# Implementation: LLVM IR Details

## LLVM IR Primer

LLVM IR (Intermediate Representation) is a typed, SSA-form assembly language that
sits between the C/C++ source and machine code. The tool works exclusively with the
**text format** (`.ll` files) produced by `clang -S -emit-llvm`.

### Structure of a `.ll` File

```
; ModuleID = 'signed_overflow.c'
source_filename = "signed_overflow.c"
target triple = "x86_64-unknown-linux-gnu"

; --- Function definition ---
define i32 @check_overflow(i32 noundef %0) {
entry:
  %x = alloca i32, align 4          ; allocate stack slot
  store i32 %0, ptr %x, align 4     ; spill argument to stack (O0 only)
  %1 = load i32, ptr %x, align 4    ; reload
  %add = add nsw i32 %1, 1          ; signed add (nsw = no signed wrap)
  %2 = load i32, ptr %x, align 4
  %cmp = icmp sgt i32 %add, %2      ; signed greater-than comparison
  br i1 %cmp, label %if.then, label %if.else  ; conditional branch

if.then:
  store i32 1, ptr %retval, align 4
  br label %return

if.else:
  store i32 0, ptr %retval, align 4
  br label %return

return:
  %3 = load i32, ptr %retval, align 4
  ret i32 %3
}
```

Key LLVM IR concepts used by the tool:

| Concept | IR Syntax | Tool Use |
|---|---|---|
| SSA register | `%name` | Track def-use for folding detection |
| Basic block | `label:` header | Enumerate blocks; detect removals |
| `alloca` | `%x = alloca i32` | Memory ops; detect uninit reads |
| `store` / `load` | `store T %v, ptr %p` | Type mismatch → aliasing |
| `icmp sgt/slt` | signed comparison | Overflow check pattern |
| `br i1 %c, %a, %b` | conditional branch | Count; detect eliminations |
| `nsw` / `nuw` | overflow flags | Signed/unsigned wrap UB signal |
| `getelementptr inbounds` | GEP + inbounds | Pointer-wrap UB signal |
| `unreachable` | terminator | Dead-code elimination marker |
| `!DILocation` | `!dbg !N` | Source file / line mapping |

---

## IRParser Implementation (`engine/ir_parser.py`)

### Data Model

```
IRModule
  ├── source_file: str           (from 'source_filename' or ModuleID)
  ├── target_triple: str
  ├── declarations: dict[name → Function]
  └── defined_functions: dict[name → Function]
        └── Function
              ├── name: str
              ├── source_file: str  (from debug metadata)
              ├── source_line: int
              ├── basic_blocks: list[BasicBlock]
              └── BasicBlock
                    ├── label: str
                    └── instructions: list[Instruction]
                          ├── opcode: str
                          ├── raw: str          (full line text)
                          ├── result: str       (LHS SSA name, if any)
                          └── is_memory: bool
```

### Parsing Strategy

The parser is a **line-by-line stateful finite automaton**:

```
State: OUTSIDE_FUNCTION
  → sees 'define ... @name ... {'  → enter INSIDE_FUNCTION
  → sees 'declare'                 → record declaration; stay outside

State: INSIDE_FUNCTION
  → sees 'label_name:'             → start new BasicBlock
  → sees instruction line          → append Instruction to current block
  → sees closing '}'               → exit INSIDE_FUNCTION

State: INSIDE_FUNCTION, INSIDE_BLOCK
  → classifies instruction by opcode
  → extracts: result name, nsw/nuw flags, branch targets, comparison predicates
```

All string operations use compiled `re` patterns for performance. The parser
uses `errors="replace"` when reading files to handle non-UTF-8 compiler output.

### Debug Metadata Resolution

LLVM stores debug info as numbered metadata nodes:
```
%cmp = icmp sgt i32 %add, %2, !dbg !32
!32 = !DILocation(line: 11, column: 9, scope: !33)
!33 = distinct !DISubprogram(name: "check_overflow", line: 7, ...)
```

The parser performs a two-pass resolution:
1. **First pass:** collect all `!N = ...` definitions into a dict
2. **Second pass:** for each `!DILocation(line: N)`, look up the enclosing
   `!DISubprogram` to get the function's source line

This gives each `Function` object its `source_line` attribute, used by the
reporter to print source context.

---

## DiffEngine Implementation (`analysis/diff_engine.py`)

### Per-Function Comparison

The engine first computes the intersection of function names defined in both modules
using `function_names_in_common(m0, m2)`. Functions that exist at `-O0` but were
inlined at `-O2` (and thus absent from the `-O2` module) are outside the analysis
scope — an inherent limitation of the textual diff approach.

For each common function `fn`, the engine runs 7 independent passes. Each pass
calls `fn.basic_blocks`, `fn.all_instructions`, `fn.conditional_branches`, etc.

### Pass 1: Conditional Branch Elimination

```python
cond_O0 = fn0.conditional_branches   # list of 'br i1 %c, %a, %b' instrs
cond_O2 = fn2.conditional_branches
eliminated = len(cond_O0) - len(cond_O2)
if eliminated > 0:
    emit(CONDITIONAL_BRANCH_ELIMINATED, HIGH)
```

The classic UB signal: the optimizer proved a condition always true/false.

### Pass 2: Basic Block Removal

```python
blocks_O0 = {b.label for b in fn0.basic_blocks} - BORING_BLOCKS
blocks_O2 = {b.label for b in fn2.basic_blocks}
removed = blocks_O0 - blocks_O2
if removed:
    emit(BASIC_BLOCK_REMOVED, HIGH)
```

`BORING_BLOCKS = {"entry", "return", "return.ptr", "cleanup"}` — these blocks
are routinely eliminated by the optimizer for non-UB reasons.

### Pass 3: Return Constant Folding

```python
rets_O0 = fn0.returns
rets_O2 = fn2.returns
has_variable_O0 = any(not r.return_is_constant for r in rets_O0)
all_constant_O2 = all(r.return_is_constant for r in rets_O2) and rets_O2
if has_variable_O0 and all_constant_O2:
    emit(RETURN_CONSTANT_FOLDED, HIGH)
```

The optimizer deduced the return value at compile time — only possible if it
proved some condition from UB axioms.

### Pass 7: Overflow Flag Detection

```python
for instr in fn0.all_instructions:
    if instr.opcode in {"add", "sub", "mul", "shl"}:
        flags = set(re.findall(r'\b(nsw|nuw)\b', instr.raw))
        if flags: flagged_O0.append((instr.raw, flags))
    elif instr.opcode == "getelementptr" and "inbounds" in instr.raw:
        flagged_O0.append((instr.raw, {"inbounds"}))

# Count how many flagged instructions survive at O2
flagged_O2 = arith_with_flags(fn2)
eliminated = len(flagged_O0) - len(flagged_O2)
if eliminated > 0:
    emit(OVERFLOW_FLAG_DROPPED, HIGH)
```

`nsw` (no signed wrap) and `nuw` (no unsigned wrap) are emitted by clang when
it can prove the operation doesn't overflow — but this is a UB *assumption*, not
a proof. The optimizer at `-O2` exploits this by treating the instruction's result
as carrying that guarantee, allowing elimination of the overflow-check branch.

`getelementptr inbounds` carries the same semantics for pointer arithmetic:
the resulting pointer must be within the same allocated object.

---

## Compiler Flags Rationale (`engine/compiler.py`)

```python
BASE_FLAGS = [
    "-S",                          # emit text IR, not bitcode
    "-emit-llvm",                  # LLVM IR format
    "-g",                          # include debug metadata (line numbers)
    "-fno-discard-value-names",    # keep %x instead of %1 (readable IR)
]

O0_FLAGS = BASE_FLAGS + ["-O0"]
O2_FLAGS = BASE_FLAGS + ["-O2"]
```

### Why no `-fno-strict-aliasing`?

Strictly aliasing code **must not** pass `-fno-strict-aliasing` — that would make the
strict-aliasing UB benign and hide the very thing we're looking for. We intentionally
let the optimizer see and exploit aliasing violations.

### Why no `-Wno-everything`?

We don't suppress warnings. The `-g` flag can trigger some warnings on certain
inputs; these are passed through to the user as informational noise (the IR is still
generated regardless).

### Clang Version Fallback

```python
CLANG_BIN = "clang-18"
CLANG_FALLBACKS = ["clang"]

def _resolve_clang():
    for candidate in [CLANG_BIN] + CLANG_FALLBACKS:
        if shutil.which(candidate):
            return candidate
    raise RuntimeError("No clang found")
```

The tool uses `clang-18` by default but falls back to any `clang` in `PATH`. The
analysis is valid for clang 15+ (when opaque pointers became the default, changing
`ptr` vs `i32*` syntax).

---

## UB Category: Signed Integer Overflow

### C Standard Reference
C11 §6.5 ¶5: "If an exceptional condition occurs during the evaluation of an
expression (that is, if the result is not mathematically defined or not in the range
of representable values for its type), the behaviour is **undefined**."

For `int x = INT_MAX; x + 1;` — the mathematical result is `2^31`, which is not
representable as a 32-bit signed integer → UB.

### IR Signature at -O0

```llvm
%add = add nsw i32 %x, 1       ; clang emits nsw because C semantics say no-overflow
%cmp = icmp sgt i32 %add, %x   ; overflow check: add > x?
br i1 %cmp, label %no_ov, label %overflow
```

### IR Signature at -O2

```llvm
ret i32 1                        ; branch eliminated; always returns "no overflow"
```

The optimizer sees `add nsw` → "this addition cannot overflow" → `%add > %x` is
trivially true → the `%overflow` branch is unreachable → dead-code eliminated →
the function body collapses to a single `ret i32 1`.

---

## UB Category: Strict Aliasing Violation

### C Standard Reference
C11 §6.5 ¶7: An object shall only be accessed by an lvalue of a compatible type.
Accessing a `float` through an `int*` (or vice-versa) is undefined behaviour.

### IR Signature at -O0

```llvm
%x = alloca i32, align 4
store i32 %bits, ptr %x, align 4     ; store integer bits
%r = load float, ptr %x, align 4     ; load as float (TYPE MISMATCH → UB)
```

The type mismatch (`i32` store, `float` load from the same alloca) is the textual
signature in the IR. The tool detects this via `_has_type_punning_load()` which
tracks `defaultdict(set)` of stored types per alloca name.

### IR Signature at -O2

The load may be eliminated, hoisted above the store, or replaced with a cached
value — the exact transformation is ABI and target dependent. The tool detects the
*effect* (significant instruction count collapse without structural changes) rather
than the specific transformation.

---

## UB Category: Null Pointer Dereference

### C Standard Reference
C11 §6.5.3.2 ¶4: If the value of the pointer is null, the behaviour is undefined.

### Detection Pattern

```c
int use_ptr(int *ptr) {
    if (ptr) { return *ptr; }
    else {
        int *null_ptr = 0;
        return *null_ptr;   // UB: always null, but the optimizer
    }                       // proves this path is dead → eliminates it
}
```

```llvm
; O0: null pointer assigned
store ptr null, ptr %null_ptr, align 8
; O0: if.else block exists with the null deref

; O2: if.else block removed entirely
; O2: %tobool check eliminated
```

Detection: `_has_null_store(fn0)` + `BASIC_BLOCK_REMOVED` finding.

---

## UB Category: Uninitialized Variable Use

### C Standard Reference
C11 §6.7.9: An object without an initializer has an **indeterminate** value.
Reading an indeterminate value is undefined behaviour.

### Detection Pattern

```llvm
; O0:
%x = alloca i32, align 4
; NO store to %x before:
%0 = load i32, ptr %x, align 4   ; reads uninitialized memory
%cmp = icmp eq i32 %0, 0         ; comparison on garbage value
%conv = zext i1 %cmp to i32
ret i32 %conv

; O2:
ret i32 0                         ; optimizer assumed value, constant-folded
```

The `_alloca_loaded_before_store()` function performs a two-pass global scan:
- **Pass 1:** collect all alloca names whose pointer is ever used in a `store`
- **Pass 2:** collect all alloca names whose pointer is used in a `load`
- **Result:** `loaded - stored` = allocas definitely read without any write

This conservative criterion (never stored anywhere) avoids false positives from
conditionally-initialized variables.

---

## Report Generation (`report/reporter.py`)

### Source Context Extraction

The reporter reads the original `.c` file and extracts a window of lines around the
flagged line number:

```python
with open(source_path) as f:
    lines = f.readlines()
start = max(0, line_no - 1)
end   = min(len(lines), line_no + 3)
context = lines[start:end]
```

The flagged line is prefixed with `►` in both text and HTML output.

### HTML Report

The HTML report uses:
- **Inline CSS** (no external resources) for offline compatibility
- **Dark theme** (`#1a1a2e` background, green/red severity colours)
- **`<details>`/`<summary>`** for collapsible IR diff sections
- **`_h(text)`** for HTML escaping all user/IR content (prevents XSS)

Google Fonts CDN is used for `Inter` font; falls back to `system-ui` if offline.

---

## File Format: `.ll` Stability

The LLVM `.ll` text format has been stable since LLVM 14. Key changes between
versions that affect this tool:

| LLVM Version | Change | Impact |
|---|---|---|
| 14 → 15 | Opaque pointers: `i32*` → `ptr` | `_has_type_punning_load` regex updated |
| 15 → 18 | `noundef` attribute added to params | Parser ignores attributes on `define` line |
| All | `!dbg !N` suffix on instructions | Optional; parser handles missing metadata gracefully |
