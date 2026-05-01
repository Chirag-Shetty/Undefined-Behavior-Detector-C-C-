# UB Time Bomb Detector — Project Briefing

## What This Project Does
A static analysis tool that finds "undefined behavior time bombs" in C/C++ code.
These are code patterns that work fine at -O0 (no optimization) but silently break
at -O2/-O3 because the compiler exploits undefined behavior assumptions to eliminate
or restructure code.

## The Core Idea
- At -O0: compiler translates code literally, UB "accidentally works"
- At -O2/-O3: compiler ASSUMES UB never happens, uses that to optimize aggressively
- This tool finds functions where that assumption CHANGED the behavior

## Project Structure
ub-detector/
├── CLAUDE.md                  # This file
├── engine/
│   ├── compiler.py            # Deliverable 1: Compile C/C++ to IR at -O0 and -O2
│   └── ir_parser.py           # Parse and load LLVM IR files
├── analysis/
│   ├── diff_engine.py         # Deliverable 2: Compare IR, find behavioral changes
│   └── ub_classifier.py       # Deliverable 3: Map changes to UB categories
├── report/
│   └── reporter.py            # Deliverable 4: Generate source-level human-readable report
├── testcases/
│   ├── signed_overflow.c      # Test: x + 1 > x always true at -O2
│   ├── null_deref.c           # Test: null pointer in dead code
│   ├── strict_aliasing.c      # Test: type punning via pointer cast
│   ├── uninit_var.c           # Test: uninitialized variable used
│   └── cve_cases/             # Deliverable 5: 5 real-world CVE/bug tracker cases
│       ├── cve_2017_11164.c
│       ├── cve_2018_6952.c
│       ├── gcc_bug_30475.c
│       ├── gcc_bug_58640.c
│       └── clang_bug_21530.c
├── main.py                    # Entry point — runs the full pipeline
└── output/                    # Generated reports go here

## The 5 Deliverables
1. **Differential Compilation Engine** (`engine/compiler.py`)
   - Takes a .c or .cpp file as input
   - Compiles it with `clang -O0 -emit-llvm` and `clang -O2 -emit-llvm`
   - Saves both IR files for comparison

2. **Behavioral Change Detector** (`analysis/diff_engine.py`)
   - Compares the two IR files function by function
   - Detects: eliminated branches, removed code blocks, changed return values
   - Flags functions where optimizer made structural changes

3. **UB Pattern Classifier** (`analysis/ub_classifier.py`)
   - Takes the detected changes and maps them to UB categories:
     a. Signed integer overflow (e.g. x+1 > x always true)
     b. Strict aliasing violation (e.g. int* cast to float*)
     c. Null pointer dereference in dead code
     d. Use of uninitialized variables
   - Uses IR pattern matching heuristics

4. **Source-Level Report** (`report/reporter.py`)
   - Produces a human-readable report
   - Format: "line N: this works at -O0 but breaks at -O2 because of [UB type]"
   - Also generates an HTML report for easy viewing

5. **Real-World CVE Evaluation** (`testcases/cve_cases/`)
   - 5 real bugs from CVE databases or GCC/Clang bug trackers
   - Each tested through the full pipeline
   - Results documented showing tool correctly identifies the UB

## Tech Stack
- Language: Python 3
- Compiler: Clang/LLVM (clang-18, llvm-18) — already installed
- IR tools: llvm-dis, opt (part of llvm package)
- No external Python packages needed beyond stdlib

## How to Run (once built)
```bash
# Analyze a single file
python3 main.py testcases/signed_overflow.c

# Run on all CVE cases
python3 main.py --all-cve

# Generate HTML report
python3 main.py testcases/signed_overflow.c --html
```

## Key Commands Used Internally
```bash
# Compile to IR at O0
clang -O0 -S -emit-llvm input.c -o output_O0.ll

# Compile to IR at O2
clang -O2 -S -emit-llvm input.c -o output_O2.ll

# Disassemble IR to readable form
llvm-dis output.bc -o output.ll
```

## UB Categories and IR Signatures
| UB Type | What changes in IR | Example |
|---|---|---|
| Signed overflow | Branch eliminated, comparison becomes constant | x+1 > x → always true |
| Strict aliasing | Load/store reordered or removed | float f = *(float*)&i |
| Null deref in dead code | Entire block removed | if(ptr) { *null_ptr = 1; } |
| Uninitialized use | Value assumed to be specific constant | int x; return x == 0; |

## Current Status
- [x] Deliverable 1: Compilation engine
- [ ] Deliverable 2: Diff engine
- [ ] Deliverable 3: UB classifier
- [ ] Deliverable 4: Reporter
- [ ] Deliverable 5: CVE test cases
