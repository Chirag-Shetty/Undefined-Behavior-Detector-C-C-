# ⚡ UB Time Bomb Detector

A static analysis tool that finds **undefined behaviour time bombs** in C/C++ code — patterns that work correctly at `-O0` but silently break at `-O2` because the compiler exploits UB assumptions to eliminate or restructure code.

## The Core Idea

| Optimization | What happens |
|---|---|
| `-O0` | Compiler translates code literally; UB "accidentally works" |
| `-O2` | Compiler **assumes UB never happens** and optimizes aggressively |

This tool compiles your code at both levels, diffs the LLVM IR, and reports every function where the optimizer's UB assumption **changed the observable behaviour**.

---

## Requirements

- Python 3.10+
- `clang-18` and `llvm-dis-18`

```bash
# Verify
clang-18 --version
llvm-dis-18 --version
```

No external Python packages required — standard library only.

---

## Installation

```bash
git clone https://github.com/Chirag-Shetty/Undefined-Behavior-Detector-C-C-.git
cd Undefined-Behavior-Detector-C-C-
```

---

## Usage

### Analyse a single file

```bash
python3 main.py testcases/signed_overflow.c
```

### Generate an HTML report as well

```bash
python3 main.py testcases/signed_overflow.c --html
```

### Run all 5 CVE / bug-tracker test cases

```bash
python3 main.py --all-cve
```

### Run all CVE cases and generate HTML reports

```bash
python3 main.py --all-cve --html
```

### Analyse every `.c` file in a directory

```bash
python3 main.py testcases/
python3 main.py testcases/cve_cases/
```

### Show detailed evidence per function

```bash
python3 main.py testcases/signed_overflow.c --verbose
```

### Custom output directory

```bash
python3 main.py --all-cve --html --out-dir /tmp/ub_reports
```

### Disable colour (for CI / log capture)

```bash
python3 main.py --all-cve --no-colour
```

---

## All flags

| Flag | Description |
|---|---|
| `FILE_OR_DIR` | C/C++ source file or directory to analyse |
| `--all-cve` | Run all 5 cases in `testcases/cve_cases/` |
| `--html` | Also write an HTML report |
| `--out-dir DIR` | Override output directory (default: `output/<stem>/`) |
| `--verbose / -v` | Print per-function evidence bullets |
| `--no-colour` | Disable ANSI colour output |

---

## Output

For each analysed file, two reports are written to `output/<stem>/`:

| File | Description |
|---|---|
| `<stem>_O0.ll` | LLVM IR at `-O0` |
| `<stem>_O2.ll` | LLVM IR at `-O2` |
| `report_<stem>.txt` | Source-level text report |
| `report_<stem>.html` | Dark-themed interactive HTML report |

### Example text output

```
[HIGH]  @check_overflow  —  Signed Integer Overflow
  line 7: this works at -O0 but breaks at -O2
         because of SIGNED INTEGER OVERFLOW
  ┌─ source:
  │ ►    7 │ int check_overflow(int x) {
  └─
  Evidence:
    • O0 IR contains 'add nsw' — signed overflow UB flag
    • Conditional branch eliminated at -O2
    • Return value constant-folded: %2 → 1
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | No UB found |
| `1` | UB time bombs detected |
| `2` | Compilation error |

---

## Detected UB Categories

| Category | IR Signature | Example |
|---|---|---|
| **Signed Integer Overflow** | `add nsw`, `icmp sgt/slt`, branch eliminated | `x + 1 > x` always true |
| **Strict Aliasing Violation** | `store i32` / `load float` same alloca | `*(float*)&my_int` |
| **Null Pointer Dereference** | `store ptr null`, removed dead block | null deref in dead branch |
| **Uninitialized Variable Use** | alloca loaded before any store | `int x; return x == 0;` |

---

## Project Structure

```
ub-detector/
├── main.py                        # Entry point — run this
├── engine/
│   ├── compiler.py                # Stage 1: compile to IR at -O0 and -O2
│   └── ir_parser.py               # Stage 2: parse .ll files into data model
├── analysis/
│   ├── diff_engine.py             # Stage 3: diff IR, detect behavioural changes
│   └── ub_classifier.py           # Stage 4: map changes to UB categories
├── report/
│   └── reporter.py                # Stage 5: generate text + HTML reports
├── testcases/
│   ├── signed_overflow.c          # x+1 > x always true at -O2
│   ├── null_deref.c               # null deref in dead code path
│   ├── uninit_var.c               # uninitialized variable read
│   ├── strict_aliasing.c          # type punning via pointer cast
│   └── cve_cases/
│       ├── cve_2017_11164.c       # PCRE 8.41 — offset arithmetic overflow
│       ├── cve_2018_6952.c        # GNU patch — hunk size overflow
│       ├── gcc_bug_30475.c        # GCC: overflow check silently removed
│       ├── gcc_bug_58640.c        # GCC: uninit var in complex control flow
│       └── clang_bug_21530.c      # Clang: strict aliasing / fast inv sqrt
└── output/                        # Generated IR and reports
```

---

## How It Works

```
C source file
     │
     ▼
[Stage 1] DifferentialCompiler
  clang-18 -O0  ──►  signed_overflow_O0.ll
  clang-18 -O2  ──►  signed_overflow_O2.ll
     │
     ▼
[Stage 2] IRParser
  Parses functions, basic blocks, instructions, debug metadata
     │
     ▼
[Stage 3] DiffEngine  (7 detection passes)
  • conditional_branch_eliminated
  • basic_block_removed
  • return_constant_folded
  • comparison_eliminated
  • unreachable_inserted
  • instruction_count_collapse
  • overflow_flag_dropped
     │
     ▼
[Stage 4] UBClassifier  (scoring heuristics)
  Signed Overflow / Strict Aliasing / Null Deref / Uninit Var
     │
     ▼
[Stage 5] Reporter
  Text report (stdout + .txt)
  HTML report (dark-themed, interactive)
```

---

## CVE Test Case Results

| Test case | Models | Finding |
|---|---|---|
| `cve_2017_11164.c` | PCRE 8.41 offset arithmetic | Signed Integer Overflow [HIGH] |
| `cve_2018_6952.c` | GNU patch hunk accounting | Signed Integer Overflow [HIGH] |
| `gcc_bug_30475.c` | GCC overflow-check elimination | Signed Overflow + Null Deref [HIGH] |
| `gcc_bug_58640.c` | GCC uninit in control flow | Uninit Variable Use [HIGH] ×2 |
| `clang_bug_21530.c` | Clang strict aliasing / fast inv sqrt | Strict Aliasing + Signed Overflow [HIGH] |

---

## Design Decisions

- **Zero external dependencies** — only Python standard library
- **Differential analysis** — relies on behavioural delta between `-O0` and `-O2` rather than pattern matching; more robust across compiler versions
- **Scoring-based classifier** — each UB category independently scores evidence; the highest scorer wins, with tiebreakers for ambiguous cases
- **UB-friendly compiler flags** — strict aliasing kept active so the compiler actually exploits the UB patterns we are looking for
