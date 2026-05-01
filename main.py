#!/usr/bin/env python3
"""
main.py — UB Time Bomb Detector
Entry point that runs the full analysis pipeline on C/C++ source files.

Usage:
    python3 main.py testcases/signed_overflow.c          # analyse one file
    python3 main.py testcases/signed_overflow.c --html   # + HTML report
    python3 main.py --all-cve                            # run all CVE cases
    python3 main.py --all-cve --html                     # CVE cases + HTML
    python3 main.py testcases/ --html                    # all files in dir
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

# ── project imports ───────────────────────────────────────────────────────────
from engine.compiler      import DifferentialCompiler
from engine.ir_parser     import load_both
from analysis.diff_engine import DiffEngine
from analysis.ub_classifier import UBClassifier, UBCategory
from report.reporter      import Reporter


# ── ANSI helpers ──────────────────────────────────────────────────────────────
RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
GREEN  = "\033[92m"
BLUE   = "\033[94m"
PURPLE = "\033[95m"

_SEV_COLOR = {"HIGH": RED, "MEDIUM": YELLOW, "LOW": CYAN}
_CAT_COLOR = {
    UBCategory.SIGNED_OVERFLOW: YELLOW,
    UBCategory.STRICT_ALIASING: PURPLE,
    UBCategory.NULL_DEREF:      RED,
    UBCategory.UNINIT_VAR:      CYAN,
    UBCategory.UNKNOWN:         DIM,
}

def _c(text: str, *codes: str) -> str:
    return "".join(codes) + text + RESET

def _banner() -> None:
    print(_c("", BOLD) + """
  ╔══════════════════════════════════════════════════════════╗
  ║        ⚡  UB Time Bomb Detector  ⚡                     ║
  ║   Finds undefined-behaviour that works at -O0 but        ║
  ║   silently breaks at -O2 due to compiler optimisation    ║
  ╚══════════════════════════════════════════════════════════╝
""" + RESET)


# ── pipeline ──────────────────────────────────────────────────────────────────

def analyse_file(
    source: Path,
    *,
    html: bool = False,
    out_dir: Path | None = None,
    colour: bool = True,
    verbose: bool = False,
) -> int:
    """
    Run the full 4-stage pipeline on *source* and return an exit code.
    Returns 0 if no findings, 1 if findings were produced, 2 on error.
    """
    src = source.resolve()
    tag = _c(f"[{src.name}]", BOLD, BLUE)

    # ── Stage 1: Compile ──────────────────────────────────────────────────────
    print(f"  {tag}  {_c('compiling...', DIM)}", end="", flush=True)
    t0 = time.perf_counter()

    compiler = DifferentialCompiler()
    comp = compiler.compile(src, out_dir)
    elapsed = time.perf_counter() - t0

    if not comp.success:
        print(f"  {_c('FAIL', RED, BOLD)}")
        print(f"  {_c(comp.error or 'Unknown compile error', RED)}")
        return 2

    print(f"  {_c('OK', GREEN)}  ({elapsed:.2f}s)")

    # ── Stage 2: Parse IR ─────────────────────────────────────────────────────
    m0, m2 = load_both(comp.ir_O0_path, comp.ir_O2_path)

    # ── Stage 3: Diff ─────────────────────────────────────────────────────────
    diff = DiffEngine().diff(m0, m2)

    # ── Stage 4: Classify ─────────────────────────────────────────────────────
    classification = UBClassifier().classify(diff, m0, m2)

    # ── Report: text (always) ─────────────────────────────────────────────────
    reporter = Reporter()
    text = reporter.generate_text(classification, diff, src, colour=colour)
    print(text)

    txt_path = reporter.write_text(classification, diff, src, out_dir)
    print(_c(f"  Text report → {txt_path}", DIM))

    # ── Report: HTML (optional) ───────────────────────────────────────────────
    if html:
        html_path = reporter.write_html(classification, diff, src, out_dir)
        print(_c(f"  HTML report → {html_path}", DIM))

    if verbose and classification.classifications:
        _print_verbose(classification)

    return 1 if classification.classifications else 0


def _print_verbose(classification) -> None:
    """Print a compact per-function breakdown."""
    print(_c("\n  ── Detailed findings ──", BOLD))
    for cl in classification.classifications:
        cat_col = _CAT_COLOR.get(cl.category, DIM)
        sev = "HIGH" if cl.confidence == "high" else "MEDIUM" if cl.confidence == "medium" else "LOW"
        sev_col = _SEV_COLOR.get(sev, DIM)
        print(
            f"    {_c(f'[{sev}]', sev_col, BOLD)}  "
            f"{_c('@' + cl.function_name, BOLD)}  "
            f"{_c(cl.label, cat_col)}"
        )
        for ev in cl.evidence:
            print(f"      {_c('•', DIM)} {ev}")


# ── multi-file helpers ────────────────────────────────────────────────────────

def _collect_sources(paths: list[str]) -> list[Path]:
    """Expand directories and globs; return sorted list of .c/.cpp files."""
    sources: list[Path] = []
    for p in paths:
        path = Path(p)
        if path.is_dir():
            for ext in ("*.c", "*.cpp", "*.cc", "*.cxx"):
                sources.extend(sorted(path.glob(ext)))
        elif path.exists():
            sources.append(path)
        else:
            print(_c(f"Warning: {p} not found, skipping.", YELLOW), file=sys.stderr)
    return sources


def _cve_sources(project_root: Path) -> list[Path]:
    """Return all files under testcases/cve_cases/."""
    cve_dir = project_root / "testcases" / "cve_cases"
    if not cve_dir.exists():
        print(_c(f"CVE test case directory not found: {cve_dir}", RED), file=sys.stderr)
        return []
    return sorted(cve_dir.glob("*.c"))


# ── summary printer ───────────────────────────────────────────────────────────

def _print_summary(results: dict[str, int]) -> None:
    total   = len(results)
    errors  = sum(1 for v in results.values() if v == 2)
    clean   = sum(1 for v in results.values() if v == 0)
    flagged = sum(1 for v in results.values() if v == 1)

    print(_c("\n" + "═" * 62, BOLD))
    print(_c("  RUN SUMMARY", BOLD))
    print("═" * 62)
    print(f"  Files analysed : {total}")
    print(f"  {_c('With findings  :', BOLD)} {_c(str(flagged), RED if flagged else GREEN, BOLD)}")
    print(f"  {_c('Clean          :', BOLD)} {_c(str(clean), GREEN, BOLD)}")
    if errors:
        print(f"  {_c('Errors         :', BOLD)} {_c(str(errors), YELLOW, BOLD)}")
    print("═" * 62)

    if flagged:
        print(_c("\n  Files with UB time bombs:", RED, BOLD))
        for name, code in results.items():
            if code == 1:
                print(f"    {_c('⚡', RED)} {name}")

    if clean:
        print(_c("\n  Clean files:", GREEN))
        for name, code in results.items():
            if code == 0:
                print(f"    {_c('✓', GREEN)} {name}")
    print()


# ── argument parsing ──────────────────────────────────────────────────────────

def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="python3 main.py",
        description="UB Time Bomb Detector — finds undefined behaviour that "
                    "works at -O0 but silently breaks at -O2.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 main.py testcases/signed_overflow.c
  python3 main.py testcases/signed_overflow.c --html
  python3 main.py --all-cve --html
  python3 main.py testcases/ --html --out-dir /tmp/ub_reports
""",
    )
    p.add_argument(
        "sources",
        nargs="*",
        metavar="FILE_OR_DIR",
        help="C/C++ source file(s) or directory to analyse",
    )
    p.add_argument(
        "--all-cve",
        action="store_true",
        help="Run all 5 CVE/bug-tracker test cases in testcases/cve_cases/",
    )
    p.add_argument(
        "--html",
        action="store_true",
        help="Also generate an HTML report alongside the text report",
    )
    p.add_argument(
        "--out-dir", "-o",
        metavar="DIR",
        default=None,
        help="Directory for output files (default: output/<stem>/)",
    )
    p.add_argument(
        "--no-colour",
        action="store_true",
        help="Disable ANSI colour output",
    )
    p.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print detailed per-function evidence after each report",
    )
    return p


# ── entry point ───────────────────────────────────────────────────────────────

def main(argv: list[str] | None = None) -> int:
    parser  = _build_parser()
    args    = parser.parse_args(argv)
    colour  = not args.no_colour
    out_dir = Path(args.out_dir) if args.out_dir else None

    project_root = Path(__file__).resolve().parent

    # Collect source files
    sources: list[Path] = []
    if args.all_cve:
        sources.extend(_cve_sources(project_root))
    if args.sources:
        sources.extend(_collect_sources(args.sources))

    if not sources:
        parser.print_help()
        return 0

    # Deduplicate while preserving order
    seen: set[Path] = set()
    unique: list[Path] = []
    for s in sources:
        r = s.resolve()
        if r not in seen:
            seen.add(r)
            unique.append(r)
    sources = unique

    _banner()
    print(_c(f"  Analysing {len(sources)} file(s)…\n", DIM))

    results: dict[str, int] = {}
    for src in sources:
        code = analyse_file(
            src,
            html=args.html,
            out_dir=out_dir,
            colour=colour,
            verbose=args.verbose,
        )
        results[src.name] = code
        print()

    if len(sources) > 1:
        _print_summary(results)

    # Exit 1 if any file had findings, 2 if any had errors, else 0
    if any(v == 2 for v in results.values()):
        return 2
    if any(v == 1 for v in results.values()):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
