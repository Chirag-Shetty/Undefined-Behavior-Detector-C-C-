"""
engine/compiler.py — Differential Compilation Engine (Deliverable 1)

Compiles a C/C++ source file to LLVM IR at both -O0 and -O2 using clang-18.
Produces human-readable .ll files for downstream IR comparison and analysis.

Usage:
    from engine.compiler import DifferentialCompiler

    compiler = DifferentialCompiler()
    result = compiler.compile("testcases/signed_overflow.c")
    if result.success:
        print(result.ir_O0_path)   # path to -O0 .ll file
        print(result.ir_O2_path)   # path to -O2 .ll file
    else:
        print(result.error)
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CLANG_BIN = "clang-18"          # primary binary name
CLANG_FALLBACKS = ["clang-18", "clang"]  # tried in order if primary fails

# Flags shared by both optimisation levels
# -S            → emit human-readable .ll instead of bitcode
# -emit-llvm    → produce LLVM IR rather than object code
# -g            → embed debug metadata so we can map IR back to source lines
# -fno-discard-value-names → keep variable names from source in IR (makes diff readable)
# -Wno-everything → suppress warnings so stderr stays clean for our use
COMMON_FLAGS = [
    "-S",
    "-emit-llvm",
    "-g",
    "-fno-discard-value-names",
    "-Wno-everything",
]

# Extra flags for strict-aliasing analysis
# At -O2 the compiler assumes strict aliasing by default; we want to see that
# effect, so we do NOT add -fno-strict-aliasing here (the tool's whole point
# is to *expose* these optimisations).
OPT_LEVEL_FLAGS = {
    "O0": ["-O0"],
    "O2": ["-O2"],
}


# ---------------------------------------------------------------------------
# Result dataclass
# ---------------------------------------------------------------------------

@dataclass
class CompilationResult:
    """Holds every artefact produced by one compile() call."""

    source_path: Path                   # resolved input file
    output_dir: Path                    # directory where IR files live

    # Output paths (set on success)
    ir_O0_path: Optional[Path] = None  # -O0 .ll file
    ir_O2_path: Optional[Path] = None  # -O2 .ll file

    # Status
    success: bool = False
    error: Optional[str] = None        # human-readable error message

    # Raw subprocess output for debugging
    stdout_O0: str = ""
    stderr_O0: str = ""
    stdout_O2: str = ""
    stderr_O2: str = ""

    # Command lines used (useful for reproducing failures)
    cmd_O0: list[str] = field(default_factory=list)
    cmd_O2: list[str] = field(default_factory=list)

    def summary(self) -> str:
        """Return a short human-readable summary of the result."""
        if self.success:
            return (
                f"[OK] {self.source_path.name}\n"
                f"     -O0 IR → {self.ir_O0_path}\n"
                f"     -O2 IR → {self.ir_O2_path}"
            )
        return f"[FAIL] {self.source_path.name}: {self.error}"


# ---------------------------------------------------------------------------
# Compiler class
# ---------------------------------------------------------------------------

class DifferentialCompiler:
    """
    Compiles C/C++ source to LLVM IR at -O0 and -O2 using clang-18.

    Parameters
    ----------
    clang_bin : str
        Name or absolute path of the clang binary to use.
        Falls back through CLANG_FALLBACKS if the specified binary is not found.
    extra_flags : list[str]
        Additional flags appended to every compilation command.
    timeout : int
        Subprocess timeout in seconds per compilation step.
    """

    def __init__(
        self,
        clang_bin: str = CLANG_BIN,
        extra_flags: Optional[list[str]] = None,
        timeout: int = 60,
    ) -> None:
        self.clang_bin = self._resolve_clang(clang_bin)
        self.extra_flags: list[str] = extra_flags or []
        self.timeout = timeout

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def compile(
        self,
        source_path: str | Path,
        output_dir: str | Path | None = None,
    ) -> CompilationResult:
        """
        Compile *source_path* to LLVM IR at both -O0 and -O2.

        Parameters
        ----------
        source_path : str | Path
            Path to the .c or .cpp file to analyse.
        output_dir : str | Path | None
            Directory in which to store the generated .ll files.
            Defaults to ``output/<stem>/`` relative to the project root
            (i.e. the parent of this file's parent directory).

        Returns
        -------
        CompilationResult
            Always returns a result object; check ``.success`` before using
            the IR paths.
        """
        source_path = Path(source_path).resolve()

        if not source_path.exists():
            return CompilationResult(
                source_path=source_path,
                output_dir=Path("."),
                success=False,
                error=f"Source file not found: {source_path}",
            )

        if source_path.suffix not in {".c", ".cpp", ".cc", ".cxx"}:
            return CompilationResult(
                source_path=source_path,
                output_dir=Path("."),
                success=False,
                error=f"Unsupported file extension '{source_path.suffix}'. "
                      "Expected .c, .cpp, .cc, or .cxx",
            )

        # Resolve output directory
        if output_dir is None:
            project_root = Path(__file__).resolve().parent.parent
            output_dir = project_root / "output" / source_path.stem
        output_dir = Path(output_dir).resolve()
        output_dir.mkdir(parents=True, exist_ok=True)

        result = CompilationResult(source_path=source_path, output_dir=output_dir)

        # Compile at each optimisation level
        for level, opt_flags in OPT_LEVEL_FLAGS.items():
            ir_path = output_dir / f"{source_path.stem}_{level}.ll"
            cmd = self._build_command(source_path, ir_path, opt_flags)

            if level == "O0":
                result.cmd_O0 = cmd
            else:
                result.cmd_O2 = cmd

            ok, stdout, stderr = self._run(cmd)

            if level == "O0":
                result.stdout_O0, result.stderr_O0 = stdout, stderr
            else:
                result.stdout_O2, result.stderr_O2 = stdout, stderr

            if not ok:
                result.success = False
                result.error = (
                    f"Compilation failed at -{level}.\n"
                    f"Command: {' '.join(cmd)}\n"
                    f"stderr:\n{stderr}"
                )
                return result   # bail early — no point continuing

            # Verify the file was actually written
            if not ir_path.exists() or ir_path.stat().st_size == 0:
                result.success = False
                result.error = (
                    f"clang exited cleanly at -{level} but produced no output at "
                    f"{ir_path}"
                )
                return result

            if level == "O0":
                result.ir_O0_path = ir_path
            else:
                result.ir_O2_path = ir_path

        result.success = True
        return result

    def compile_many(
        self,
        sources: list[str | Path],
        output_dir: str | Path | None = None,
    ) -> list[CompilationResult]:
        """Convenience wrapper: compile a list of source files."""
        return [self.compile(src, output_dir) for src in sources]

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_command(
        self,
        source: Path,
        output: Path,
        opt_flags: list[str],
    ) -> list[str]:
        """Assemble the complete clang command for one optimisation level."""
        # Language flag: force C or C++ regardless of extension
        lang_flag = ["-x", "c++"] if source.suffix in {".cpp", ".cc", ".cxx"} else ["-x", "c"]

        return [
            self.clang_bin,
            *lang_flag,
            *COMMON_FLAGS,
            *opt_flags,
            *self.extra_flags,
            str(source),
            "-o", str(output),
        ]

    def _run(self, cmd: list[str]) -> tuple[bool, str, str]:
        """
        Execute a subprocess command.

        Returns
        -------
        (success, stdout, stderr)
        """
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
            return proc.returncode == 0, proc.stdout, proc.stderr
        except FileNotFoundError:
            return (
                False,
                "",
                f"Binary not found: '{cmd[0]}'. "
                f"Is clang-18 installed? (sudo apt install clang-18)",
            )
        except subprocess.TimeoutExpired:
            return False, "", f"Compilation timed out after {self.timeout}s: {' '.join(cmd)}"
        except OSError as exc:
            return False, "", f"OS error running compiler: {exc}"

    @staticmethod
    def _resolve_clang(preferred: str) -> str:
        """
        Return the first clang binary that exists on PATH.
        Prefers *preferred*; falls back through CLANG_FALLBACKS.
        """
        candidates = [preferred] + [f for f in CLANG_FALLBACKS if f != preferred]
        for candidate in candidates:
            if shutil.which(candidate):
                return candidate
        # Last resort: return preferred and let the subprocess fail with a
        # useful error message rather than crashing here.
        return preferred


# ---------------------------------------------------------------------------
# IR metadata helpers
# ---------------------------------------------------------------------------

def extract_source_map(ir_path: Path) -> dict[str, int]:
    """
    Parse a .ll file and return a mapping of ``{ir_function_name: first_source_line}``.

    LLVM debug metadata encodes source locations as ``!DILocation`` nodes;
    the first ``line:`` value we see inside each function's debug scope gives
    us the approximate source line for that function body.

    This is a lightweight textual scan — sufficient for report generation
    without pulling in the full LLVM Python bindings.
    """
    mapping: dict[str, int] = {}
    if not ir_path.exists():
        return mapping

    current_fn: Optional[str] = None
    fn_pattern = re.compile(r'^define\s+.*?@([\w.]+)\s*\(')
    loc_pattern = re.compile(r'!DILocation\(line:\s*(\d+)')

    with ir_path.open("r", errors="replace") as fh:
        for line in fh:
            fn_match = fn_pattern.match(line)
            if fn_match:
                current_fn = fn_match.group(1)

            if current_fn and current_fn not in mapping:
                loc_match = loc_pattern.search(line)
                if loc_match:
                    mapping[current_fn] = int(loc_match.group(1))

    return mapping


def get_ir_stats(ir_path: Path) -> dict:
    """
    Return basic statistics about an IR file:
    - num_functions   : number of defined functions
    - num_basic_blocks: total basic block count
    - num_instructions: total instruction count
    - file_size_bytes : raw .ll file size
    """
    stats = {
        "num_functions": 0,
        "num_basic_blocks": 0,
        "num_instructions": 0,
        "file_size_bytes": 0,
    }
    if not ir_path.exists():
        return stats

    stats["file_size_bytes"] = ir_path.stat().st_size

    inside_fn = False
    with ir_path.open("r", errors="replace") as fh:
        for line in fh:
            stripped = line.strip()
            if stripped.startswith("define "):
                stats["num_functions"] += 1
                inside_fn = True
            elif stripped == "}" and inside_fn:
                inside_fn = False
            elif inside_fn:
                # A basic block label is an identifier ending with ':'
                if stripped.endswith(":") and not stripped.startswith(";"):
                    stats["num_basic_blocks"] += 1
                # Count non-empty, non-comment, non-label lines as instructions
                elif stripped and not stripped.startswith(";") and not stripped.endswith(":"):
                    stats["num_instructions"] += 1

    return stats


# ---------------------------------------------------------------------------
# CLI entry point (python -m engine.compiler <file>)
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    """Minimal CLI so this module can be tested standalone."""
    import argparse

    parser = argparse.ArgumentParser(
        prog="engine.compiler",
        description="Compile a C/C++ file to LLVM IR at -O0 and -O2.",
    )
    parser.add_argument("source", help="Path to .c / .cpp source file")
    parser.add_argument(
        "--output-dir", "-o",
        default=None,
        help="Directory for generated .ll files (default: output/<stem>/)",
    )
    parser.add_argument(
        "--clang",
        default=CLANG_BIN,
        help=f"Clang binary to use (default: {CLANG_BIN})",
    )
    parser.add_argument(
        "--stats",
        action="store_true",
        help="Print IR statistics after successful compilation",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show the exact clang commands used",
    )
    args = parser.parse_args(argv)

    compiler = DifferentialCompiler(clang_bin=args.clang)
    result = compiler.compile(args.source, args.output_dir)

    print(result.summary())

    if args.verbose and result.success:
        print("\nCommands used:")
        print("  O0:", " ".join(result.cmd_O0))
        print("  O2:", " ".join(result.cmd_O2))

    if args.stats and result.success:
        for level, ir_path in [("O0", result.ir_O0_path), ("O2", result.ir_O2_path)]:
            s = get_ir_stats(ir_path)
            print(
                f"\n  -{level} stats: "
                f"{s['num_functions']} fns, "
                f"{s['num_basic_blocks']} blocks, "
                f"{s['num_instructions']} instrs, "
                f"{s['file_size_bytes']} bytes"
            )

    if not result.success:
        if result.stderr_O0:
            print("\n--- O0 stderr ---", file=sys.stderr)
            print(result.stderr_O0, file=sys.stderr)
        if result.stderr_O2:
            print("\n--- O2 stderr ---", file=sys.stderr)
            print(result.stderr_O2, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
