# Design: UB Time Bomb Detector

## Problem Statement

C and C++ programs routinely contain **undefined behaviour (UB)** that appears harmless
at `-O0` because the compiler translates the code literally. When optimisation is
enabled (`-O2` / `-O3`), the compiler is permitted — and in practice, does — exploit
the UB assumptions to delete branches, constant-fold returns, and eliminate entire
code paths. The result is a program that produces different observable output at
higher optimisation levels without any compiler warning.

These are **time bombs**: code that ships, passes CI, and works in debug builds, then
silently regresses when a build flag changes.

### Motivating Example

```c
int check_overflow(int x) {
    if (x + 1 > x) return 1;   // always true at -O2 (UB: signed overflow)
    else            return 0;   // dead code at -O2 — ELIMINATED
}
```

At `-O0`, `check_overflow(INT_MAX)` returns `0` (the addition wraps at runtime).
At `-O2`, clang eliminates the else branch entirely and always returns `1`.
The function is semantically different at the two optimisation levels, and no
warning is emitted.

---

## Design Goals

| Goal | Rationale |
|---|---|
| **Static, not dynamic** | Find UB without executing the program; covers all code paths |
| **Optimisation-level differential** | Ground truth: the optimizer's own IR tells us what it exploited |
| **No external Python deps** | Runs in any environment with Python 3.10+ and clang |
| **Source-level output** | Findings anchored to line numbers via LLVM debug metadata |
| **Classifiable UB categories** | Not just "something changed" — which UB rule was the trigger |

---

## Approach: Differential IR Analysis

The core insight is that LLVM IR produced at `-O0` is a near-literal translation of
the C source, while IR at `-O2` has been transformed under the UB axioms. The
**behavioural delta** between the two IRs is a certificate that UB was exploited.

```
C source → clang -O0 -emit-llvm → IR₀   ─┐
                                          ├─► diff ──► UB findings
C source → clang -O2 -emit-llvm → IR₂   ─┘
```

This approach is categorically different from existing tools:

| Tool | Method | Limitation |
|---|---|---|
| **UBSan** | Runtime instrumentation | Only covers executed paths; needs test inputs |
| **Clang -fsanitize=undefined** | Runtime | Same as UBSan |
| **Clang Static Analyzer** | AST-level symbolic execution | Does not model optimizer behaviour |
| **cppcheck** | Pattern matching on AST | Cannot reason about optimizer UB exploitation |
| **This tool** | Differential LLVM IR analysis | No execution needed; optimizer is the oracle |

### Why Not AST-Based?

AST-based tools operate on the source structure before any optimisation. They can
identify patterns that *could* be UB, but they cannot tell you whether the optimizer
*actually* exploited that UB to change the program's behaviour. A false positive rate
of 10-30% is typical for AST-based UB checkers.

Our differential approach has a different error profile: it only fires when the IR
actually differs — no exploitation means no finding.

### Why LLVM IR Instead of Assembly?

LLVM IR sits between the source and machine code. It is:
- **Portable** — target-independent; the same analysis works on x86, ARM, RISC-V
- **Structured** — SSA form with explicit basic blocks and typed instructions
- **Debug-annotated** — `!DILocation` metadata maps every instruction back to a
  source line
- **Readable** — human-readable text with `.ll` extension; no disassembler needed

---

## Architecture

The tool is a **five-stage pipeline**, each stage isolated as a Python module:

```
Stage 1: DifferentialCompiler  (engine/compiler.py)
  Invokes clang twice with -O0 and -O2, retaining -g for debug info.
  Key flag choices:
    -S -emit-llvm          → .ll text (not bitcode)
    -g                     → debug metadata for source mapping
    -fno-discard-value-names → readable IR register names (%x vs %1)
    NO -fno-strict-aliasing  → let the optimizer exploit aliasing UB

Stage 2: IRParser             (engine/ir_parser.py)
  Regex-based stateful parser for .ll files.
  Produces: IRModule → {Function → {BasicBlock → [Instruction]}}
  Also extracts: conditional branches, returns, comparisons, memory ops,
                 NSw/NUW flags, debug location metadata.

Stage 3: DiffEngine           (analysis/diff_engine.py)
  Runs 7 detection passes over (fn₀, fn₂) pairs.
  Each pass is independent and emits typed Finding objects.

Stage 4: UBClassifier         (analysis/ub_classifier.py)
  Scores each changed function against 4 UB categories.
  Returns a list of UBClassification (supports multi-category for complex fns).

Stage 5: Reporter             (report/reporter.py)
  Generates both a text report (to stdout and .txt) and an HTML report.
  Source context is extracted from the original .c file using debug line info.
```

---

## Detection Passes (Stage 3)

Seven orthogonal passes, each targeting a specific optimizer behaviour:

| Pass | Change Kind | Trigger | Severity |
|---|---|---|---|
| 1 | `conditional_branch_eliminated` | `br i1` count drops from O0→O2 | HIGH |
| 2 | `basic_block_removed` | Named block present at O0, absent at O2 | HIGH |
| 3 | `return_constant_folded` | O0 returns register; O2 returns literal constant | HIGH |
| 4 | `comparison_eliminated` | `icmp` count drops from O0→O2 | MEDIUM |
| 5 | `unreachable_inserted` | O2 has `unreachable` where O0 had `ret`/`br` | MEDIUM |
| 6 | `instruction_count_collapse` | >60% reduction without structural changes | LOW |
| 7 | `overflow_flag_dropped` | `nsw`/`nuw`/`inbounds` in O0 gone in O2 | HIGH |

Pass 6 is **suppressed** when passes 1/2/3 already fired (to avoid duplicate noise).

---

## Classification (Stage 4)

Each UB category maintains an independent **evidence score**. Evidence points are
accumulated from IR signals present in the O0 function and from the findings
produced by Stage 3:

### Signed Integer Overflow
- +2: `add nsw` / `sub nsw` / `mul nsw` present in O0
- +1: `icmp sgt` / `icmp slt` signed comparison found in O0
- +2: `CONDITIONAL_BRANCH_ELIMINATED` finding
- +2: `OVERFLOW_FLAG_DROPPED` finding
- +1: `RETURN_CONSTANT_FOLDED` finding
- +1: `COMPARISON_ELIMINATED` finding

### Null Pointer Dereference
- +3: `store ptr null` in O0
- +1: null comparison (`icmp ne ptr ..., null`) in O0
- +1: `BASIC_BLOCK_REMOVED` finding
- +1: `UNREACHABLE_INSERTED` finding
- -2: if signed overflow signals are also strong (disambiguation)

### Uninitialized Variable Use
- +3: alloca name appears in loads but has **no store anywhere** in function
- +2: `RETURN_CONSTANT_FOLDED` + `COMPARISON_ELIMINATED` both present
- +1: `COMPARISON_ELIMINATED` alone
- +1: no `nsw`/`nuw` flags and no signed comparisons (rules out overflow)

### Strict Aliasing Violation
- +3: `store i32` / `load float` (or vice-versa) to same alloca
- +2: module-level type-punning detected and this function shows collapse
- +1: `INSTRUCTION_COUNT_COLLAPSE` without structural changes

**Winner selection:** The highest scorer wins. Secondary categories are also emitted
when their score is ≥ medium threshold AND within 1 point of the winner — correctly
handling functions with multiple UB types (e.g. `fast_inv_sqrt` has both type-punning
and integer bit-manipulation).

---

## Alternatives Considered

### Alternative 1: Compile-time AST Matching
Use clang's `ASTMatchers` to find patterns like `x + 1 > x`.
- ✅ Source-accurate, no IR knowledge needed
- ❌ High false positives (pattern may not be exploited by any optimizer)
- ❌ Does not generalize to novel UB patterns not in the match rules

### Alternative 2: UBSan + Differential Execution
Run the binary built with `-O0 -fsanitize=undefined` and again with `-O2`, compare
stdout/stderr/exit codes.
- ✅ Ground truth (actual runtime behaviour)
- ❌ Requires test harness and inputs; misses untested paths
- ❌ Does not work on code that can't be linked (libraries, OS kernels)

### Alternative 3: Compiler-Explorer API
Submit code to Godbolt, compare assembly output.
- ✅ Easy for humans to inspect
- ❌ Assembly diff is noisy; hard to attribute differences to UB vs normal optimisation
- ❌ Network dependency; not embeddable in CI

### Alternative 4: `opt -O2` on the O0 IR
Run the LLVM optimisation pipeline on the O0 IR directly, without recompilation.
- ✅ Deterministic (no parsing differences)
- ❌ Misses front-end UB analysis that clang performs before emitting IR
- ❌ Some UB signals (like `nsw` flags) are set by the front-end, not `opt`

---

## Design Decisions and Trade-offs

### Textual IR Parsing vs. LLVM Python Bindings

We parse `.ll` files with regex rather than using `llvm-python` or `llvmlite`.

**Pros of regex:**
- Zero external dependencies — works in any Python installation
- `.ll` format is stable; our patterns are robust to minor version changes

**Cons of regex:**
- No semantic understanding (SSA def-use chains, dominator tree)
- Cannot follow GEP chains — struct member accesses via different GEP results
  for the same logical field are opaque to the scanner (documented limitation)

### Conservative Uninit Detection

`_alloca_loaded_before_store` only flags allocas with **zero stores anywhere** in
the function. A stricter approach (entry-block analysis or dominance) would catch
conditionally-initialized variables but risks false positives. We accept the
false-negative trade-off and rely on the diff-engine signals (branch elimination,
constant folding) to detect the harder cases.

### Exit Code Convention

Exit code `1` on findings is intentional and makes the tool CI-friendly:

```yaml
# GitHub Actions example
- run: ./run.sh src/ --no-colour
  # fails the CI job if any UB time bomb is found
```

---

## Security of the Tool Itself

The tool never executes the analyzed code. It only:
1. Invokes `clang` as a subprocess with explicit whitelisted flags
2. Reads the resulting `.ll` text files
3. Reads the original `.c` source for context lines

No `eval`, no dynamic imports, no network access.
