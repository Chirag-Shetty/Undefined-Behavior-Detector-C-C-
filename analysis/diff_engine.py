"""
analysis/diff_engine.py — Behavioral Change Detector (Deliverable 2)

Compares O0 and O2 LLVM IR function-by-function and flags locations where
the optimizer made structural changes that are only valid under the UB
assumption.

Seven detection passes (run in order of severity):
  1. conditional_branch_eliminated  — br i1 → unconditional or gone
  2. basic_block_removed            — entire block present in O0, absent in O2
  3. return_constant_folded         — variable return → constant return
  4. comparison_eliminated          — icmp/fcmp present in O0, absent in O2
  5. unreachable_inserted           — O2 adds 'unreachable' that O0 lacked
  6. instruction_count_collapse     — dramatic instruction-count reduction
  7. overflow_flag_dropped          — 'nsw'/'nuw' flags gone (optimizer exploited them)

Usage:
    from engine.compiler import DifferentialCompiler
    from engine.ir_parser import load_both
    from analysis.diff_engine import DiffEngine

    result = DifferentialCompiler().compile("testcases/signed_overflow.c")
    m0, m2 = load_both(result.ir_O0_path, result.ir_O2_path)
    report  = DiffEngine().diff(m0, m2)

    for finding in report.findings:
        print(finding.short())
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Optional

from engine.ir_parser import (
    Function,
    IRModule,
    Instruction,
    BasicBlock,
    load_both,
    function_names_in_common,
)


# ---------------------------------------------------------------------------
# Change taxonomy
# ---------------------------------------------------------------------------

class ChangeKind(str, Enum):
    """Canonical labels for each detected behavioural change."""
    CONDITIONAL_BRANCH_ELIMINATED = "conditional_branch_eliminated"
    BASIC_BLOCK_REMOVED           = "basic_block_removed"
    RETURN_CONSTANT_FOLDED        = "return_constant_folded"
    COMPARISON_ELIMINATED         = "comparison_eliminated"
    UNREACHABLE_INSERTED          = "unreachable_inserted"
    INSTRUCTION_COUNT_COLLAPSE    = "instruction_count_collapse"
    OVERFLOW_FLAG_DROPPED         = "overflow_flag_dropped"


class Severity(str, Enum):
    HIGH   = "HIGH"
    MEDIUM = "MEDIUM"
    LOW    = "LOW"


# Map each change kind to a default severity
_DEFAULT_SEVERITY: dict[ChangeKind, Severity] = {
    ChangeKind.CONDITIONAL_BRANCH_ELIMINATED: Severity.HIGH,
    ChangeKind.BASIC_BLOCK_REMOVED:           Severity.HIGH,
    ChangeKind.RETURN_CONSTANT_FOLDED:        Severity.HIGH,
    ChangeKind.COMPARISON_ELIMINATED:         Severity.MEDIUM,
    ChangeKind.UNREACHABLE_INSERTED:          Severity.MEDIUM,
    ChangeKind.INSTRUCTION_COUNT_COLLAPSE:    Severity.LOW,
    ChangeKind.OVERFLOW_FLAG_DROPPED:         Severity.MEDIUM,
}


# ---------------------------------------------------------------------------
# Finding dataclass
# ---------------------------------------------------------------------------

@dataclass
class Finding:
    """
    A single detected behavioral change in one function.

    All fields are intentionally kept flat so the classifier and reporter
    can access them without further parsing.
    """
    # Identity
    function_name: str
    change_kind: ChangeKind
    severity: Severity

    # Human-readable descriptions
    description: str        # one-line summary
    detail_O0: str = ""     # what O0 IR shows
    detail_O2: str = ""     # what O2 IR shows

    # Source location (from debug metadata, best-effort)
    source_file: Optional[str] = None
    source_line: Optional[int] = None   # function's opening source line

    # Instruction-level source lines (populated when available)
    instr_lines: list[int] = field(default_factory=list)

    # Raw IR snippets for the report
    ir_O0_snippet: str = ""
    ir_O2_snippet: str = ""

    def short(self) -> str:
        loc = f" (line {self.source_line})" if self.source_line else ""
        return (
            f"[{self.severity.value}] @{self.function_name}{loc}: "
            f"{self.change_kind.value} — {self.description}"
        )

    def __str__(self) -> str:
        lines = [self.short()]
        if self.detail_O0:
            lines.append(f"  O0: {self.detail_O0}")
        if self.detail_O2:
            lines.append(f"  O2: {self.detail_O2}")
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# Per-function diff result
# ---------------------------------------------------------------------------

@dataclass
class FunctionDiff:
    """All findings for a single function pair."""
    name: str
    fn_O0: Function
    fn_O2: Function
    findings: list[Finding] = field(default_factory=list)

    # Raw metrics (useful for reporting)
    blocks_O0: int = 0
    blocks_O2: int = 0
    instrs_O0: int = 0
    instrs_O2: int = 0
    cond_branches_O0: int = 0
    cond_branches_O2: int = 0

    @property
    def changed(self) -> bool:
        return len(self.findings) > 0

    @property
    def max_severity(self) -> Optional[Severity]:
        if not self.findings:
            return None
        order = [Severity.HIGH, Severity.MEDIUM, Severity.LOW]
        for sev in order:
            if any(f.severity == sev for f in self.findings):
                return sev
        return None


# ---------------------------------------------------------------------------
# Module-level diff report
# ---------------------------------------------------------------------------

@dataclass
class DiffReport:
    """
    Complete diff report for a compilation unit.

    Contains per-function diffs and flat lists of findings sorted by severity.
    """
    source_file: str
    ir_O0_path: Path
    ir_O2_path: Path

    function_diffs: list[FunctionDiff] = field(default_factory=list)

    @property
    def findings(self) -> list[Finding]:
        """All findings across all functions, sorted HIGH → MEDIUM → LOW."""
        all_f = [f for fd in self.function_diffs for f in fd.findings]
        order = {Severity.HIGH: 0, Severity.MEDIUM: 1, Severity.LOW: 2}
        return sorted(all_f, key=lambda f: (order[f.severity], f.function_name))

    @property
    def changed_functions(self) -> list[FunctionDiff]:
        return [fd for fd in self.function_diffs if fd.changed]

    @property
    def total_findings(self) -> int:
        return sum(len(fd.findings) for fd in self.function_diffs)

    def summary(self) -> str:
        hi  = sum(1 for f in self.findings if f.severity == Severity.HIGH)
        med = sum(1 for f in self.findings if f.severity == Severity.MEDIUM)
        lo  = sum(1 for f in self.findings if f.severity == Severity.LOW)
        return (
            f"DiffReport: {self.source_file} | "
            f"{len(self.changed_functions)} changed functions | "
            f"{self.total_findings} findings "
            f"(HIGH={hi}, MEDIUM={med}, LOW={lo})"
        )


# ---------------------------------------------------------------------------
# Diff Engine
# ---------------------------------------------------------------------------

# Threshold: fraction of instruction reduction that triggers LOW finding
_INSTR_COLLAPSE_RATIO = 0.40   # >60% reduction

# Overflow / UB arithmetic flags emitted by clang -O0 that the optimizer
# exploits (removes the runtime check, then drops the flag)
_OVERFLOW_FLAGS = re.compile(r'\b(nsw|nuw|nnan|ninf|nsz|arcp|fast)\b')


class DiffEngine:
    """
    Compares two IRModules (O0 vs O2) and produces a DiffReport.

    Each detection pass is a private method that appends Finding objects
    to a FunctionDiff.  Passes are independent and non-overlapping in what
    they flag, so a single function can accumulate several findings.
    """

    def diff(self, m0: IRModule, m2: IRModule) -> DiffReport:
        """
        Compare *m0* (-O0) with *m2* (-O2) and return a DiffReport.
        Only functions present in both modules are compared.
        """
        report = DiffReport(
            source_file=m0.source_file or str(m0.path),
            ir_O0_path=m0.path,
            ir_O2_path=m2.path,
        )

        common = function_names_in_common(m0, m2)
        for fn_name in common:
            fn0 = m0.defined_functions[fn_name]
            fn2 = m2.defined_functions[fn_name]
            fd = self._diff_function(fn0, fn2)
            report.function_diffs.append(fd)

        return report

    # ------------------------------------------------------------------
    # Public convenience: diff from file paths
    # ------------------------------------------------------------------

    @classmethod
    def diff_files(cls, O0_path: str | Path, O2_path: str | Path) -> DiffReport:
        """Load both IR files and diff them."""
        m0, m2 = load_both(O0_path, O2_path)
        return cls().diff(m0, m2)

    # ------------------------------------------------------------------
    # Per-function orchestrator
    # ------------------------------------------------------------------

    def _diff_function(self, fn0: Function, fn2: Function) -> FunctionDiff:
        fd = FunctionDiff(
            name=fn0.name,
            fn_O0=fn0,
            fn_O2=fn2,
            blocks_O0=fn0.num_blocks,
            blocks_O2=fn2.num_blocks,
            instrs_O0=fn0.num_instructions,
            instrs_O2=fn2.num_instructions,
            cond_branches_O0=len(fn0.conditional_branches),
            cond_branches_O2=len(fn2.conditional_branches),
        )

        # Run all detection passes
        self._pass_conditional_branch_eliminated(fn0, fn2, fd)
        self._pass_basic_block_removed(fn0, fn2, fd)
        self._pass_return_constant_folded(fn0, fn2, fd)
        self._pass_comparison_eliminated(fn0, fn2, fd)
        self._pass_unreachable_inserted(fn0, fn2, fd)
        self._pass_instruction_count_collapse(fn0, fn2, fd)
        self._pass_overflow_flag_dropped(fn0, fn2, fd)

        return fd

    # ------------------------------------------------------------------
    # Pass 1 — Conditional branch eliminated
    #
    # A conditional branch (br i1 %cond, label %t, label %f) in O0
    # becomes an unconditional branch or disappears entirely in O2.
    # This is the classic UB sign: the optimizer proved one path is
    # unreachable by assuming UB never happens.
    # ------------------------------------------------------------------

    def _pass_conditional_branch_eliminated(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        cond_O0 = fn0.conditional_branches
        cond_O2 = fn2.conditional_branches

        if not cond_O0:
            return  # nothing to compare

        eliminated = len(cond_O0) - len(cond_O2)
        if eliminated <= 0:
            return

        # Collect source lines of eliminated branches (best-effort)
        instr_lines: list[int] = []
        ir_snippets: list[str] = []
        for br in cond_O0:
            if br.debug_loc:
                instr_lines.append(br.debug_loc.line)
            ir_snippets.append(f"  {br.raw}")

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.CONDITIONAL_BRANCH_ELIMINATED,
            severity=_DEFAULT_SEVERITY[ChangeKind.CONDITIONAL_BRANCH_ELIMINATED],
            description=(
                f"{eliminated} of {len(cond_O0)} conditional branch(es) eliminated "
                f"by optimizer (UB assumption collapsed the condition)"
            ),
            detail_O0=(
                f"{len(cond_O0)} conditional branch(es): "
                + "; ".join(
                    f"br on {b.branch_condition} → [{', '.join(b.branch_targets)}]"
                    for b in cond_O0
                )
            ),
            detail_O2=(
                f"{len(cond_O2)} conditional branch(es) remain"
                if cond_O2 else "no conditional branches remain"
            ),
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            instr_lines=instr_lines,
            ir_O0_snippet="\n".join(ir_snippets),
            ir_O2_snippet="\n".join(
                f"  {b.raw}" for b in cond_O2
            ) if cond_O2 else "  (none)",
        ))

    # ------------------------------------------------------------------
    # Pass 2 — Basic block removed
    #
    # A named block (if.then, if.else, loop.body, …) present in the O0
    # function is completely absent from the O2 function.  This means the
    # optimizer proved that path is unreachable — dead-code elimination
    # driven by UB assumptions.
    # ------------------------------------------------------------------

    def _pass_basic_block_removed(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        names_O0 = set(fn0.block_names)
        names_O2 = set(fn2.block_names)
        removed = names_O0 - names_O2

        # Only flag semantically interesting blocks (not "entry" / "return")
        # because entry is always present and return is often merged.
        interesting = {
            b for b in removed
            if b not in {"entry", "return", "return.ptr"}
            and not b.startswith("cleanup")
        }

        if not interesting:
            return

        removed_blocks = [fn0.get_block(n) for n in interesting if fn0.get_block(n)]

        # Gather source lines from instructions in removed blocks
        instr_lines: list[int] = []
        ir_snippets: list[str] = []
        for bb in removed_blocks:
            ir_snippets.append(f"  {bb.name}:")
            for instr in bb.instructions:
                if instr.debug_loc:
                    instr_lines.append(instr.debug_loc.line)
                ir_snippets.append(f"    {instr.raw}")

        instr_lines = sorted(set(instr_lines))

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.BASIC_BLOCK_REMOVED,
            severity=_DEFAULT_SEVERITY[ChangeKind.BASIC_BLOCK_REMOVED],
            description=(
                f"{len(interesting)} basic block(s) dead-code-eliminated at -O2: "
                + ", ".join(sorted(interesting))
            ),
            detail_O0=(
                f"Blocks present at -O0: {sorted(interesting)}"
            ),
            detail_O2=(
                f"Blocks absent at -O2 (eliminated as dead code)"
            ),
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            instr_lines=instr_lines,
            ir_O0_snippet="\n".join(ir_snippets),
            ir_O2_snippet="  (blocks removed entirely)",
        ))

    # ------------------------------------------------------------------
    # Pass 3 — Return value constant-folded
    #
    # At -O0 the function returns a runtime value (%reg).
    # At -O2 the function returns a compile-time constant (e.g. 1).
    # Combined with a branch elimination finding, this is the strongest
    # evidence of UB-driven optimisation.
    # ------------------------------------------------------------------

    def _pass_return_constant_folded(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        rets_O0 = fn0.returns
        rets_O2 = fn2.returns

        if not rets_O0 or not rets_O2:
            return

        # O0: at least one non-constant return
        has_variable_O0 = any(not r.return_is_constant for r in rets_O0)
        # O2: all returns are constants
        all_constant_O2 = all(r.return_is_constant for r in rets_O2)

        if not (has_variable_O0 and all_constant_O2):
            return

        values_O0 = [r.return_value for r in rets_O0]
        values_O2 = [r.return_value for r in rets_O2]

        instr_lines: list[int] = []
        for r in rets_O2:
            if r.debug_loc:
                instr_lines.append(r.debug_loc.line)

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.RETURN_CONSTANT_FOLDED,
            severity=_DEFAULT_SEVERITY[ChangeKind.RETURN_CONSTANT_FOLDED],
            description=(
                f"Function always returns constant {set(values_O2)} at -O2 "
                f"(was runtime value at -O0); optimizer proved result under UB assumption"
            ),
            detail_O0=f"Returns: {values_O0} (runtime value(s))",
            detail_O2=f"Returns: {values_O2} (compile-time constant(s))",
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            instr_lines=instr_lines,
            ir_O0_snippet="\n".join(f"  {r.raw}" for r in rets_O0),
            ir_O2_snippet="\n".join(f"  {r.raw}" for r in rets_O2),
        ))

    # ------------------------------------------------------------------
    # Pass 4 — Comparison (icmp/fcmp) eliminated
    #
    # A signed/unsigned comparison or floating-point comparison present
    # at -O0 is absent at -O2 because the optimizer has constant-folded
    # it (typically to i1 true or i1 false) or removed it outright.
    # ------------------------------------------------------------------

    def _pass_comparison_eliminated(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        cmps_O0 = fn0.comparisons
        cmps_O2 = fn2.comparisons

        eliminated = len(cmps_O0) - len(cmps_O2)
        if eliminated <= 0 or not cmps_O0:
            return

        instr_lines: list[int] = []
        ir_snippets: list[str] = []
        for cmp in cmps_O0:
            if cmp.debug_loc:
                instr_lines.append(cmp.debug_loc.line)
            ir_snippets.append(f"  {cmp.raw}")

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.COMPARISON_ELIMINATED,
            severity=_DEFAULT_SEVERITY[ChangeKind.COMPARISON_ELIMINATED],
            description=(
                f"{eliminated} comparison instruction(s) constant-folded away at -O2"
            ),
            detail_O0=f"{len(cmps_O0)} icmp/fcmp instruction(s)",
            detail_O2=f"{len(cmps_O2)} icmp/fcmp instruction(s) remain",
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            instr_lines=instr_lines,
            ir_O0_snippet="\n".join(ir_snippets),
            ir_O2_snippet="\n".join(
                f"  {c.raw}" for c in cmps_O2
            ) if cmps_O2 else "  (none)",
        ))

    # ------------------------------------------------------------------
    # Pass 5 — unreachable inserted
    #
    # The optimizer inserts 'unreachable' when it can prove a code path
    # is never taken — this is a very direct signal that UB has been
    # used to eliminate code that was reachable at runtime at -O0.
    # ------------------------------------------------------------------

    def _pass_unreachable_inserted(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        def count_unreachable(fn: Function) -> list[Instruction]:
            return [
                i for i in fn.all_instructions
                if i.opcode == "unreachable"
            ]

        ur_O0 = count_unreachable(fn0)
        ur_O2 = count_unreachable(fn2)
        new_unreachable = len(ur_O2) - len(ur_O0)

        if new_unreachable <= 0:
            return

        instr_lines: list[int] = []
        for u in ur_O2:
            if u.debug_loc:
                instr_lines.append(u.debug_loc.line)

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.UNREACHABLE_INSERTED,
            severity=_DEFAULT_SEVERITY[ChangeKind.UNREACHABLE_INSERTED],
            description=(
                f"Optimizer inserted {new_unreachable} 'unreachable' terminator(s) "
                f"at -O2 (UB-driven proof that path is never taken)"
            ),
            detail_O0=f"{len(ur_O0)} 'unreachable' terminator(s) at -O0",
            detail_O2=f"{len(ur_O2)} 'unreachable' terminator(s) at -O2",
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            instr_lines=instr_lines,
            ir_O0_snippet="  (none)" if not ur_O0 else "\n".join(f"  {u.raw}" for u in ur_O0),
            ir_O2_snippet="\n".join(f"  {u.raw}" for u in ur_O2),
        ))

    # ------------------------------------------------------------------
    # Pass 6 — Instruction count collapse
    #
    # A dramatic reduction in instruction count (>60%) without any of the
    # above structural signals can still indicate that the optimizer made
    # significant assumptions.  Flagged at LOW severity to avoid noise.
    # ------------------------------------------------------------------

    def _pass_instruction_count_collapse(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        n0 = fn0.num_instructions
        n2 = fn2.num_instructions

        if n0 == 0:
            return

        ratio = n2 / n0

        # Only flag if ratio is below threshold AND we haven't already
        # flagged higher-severity structural changes (to reduce noise).
        already_flagged = any(
            f.change_kind in {
                ChangeKind.CONDITIONAL_BRANCH_ELIMINATED,
                ChangeKind.BASIC_BLOCK_REMOVED,
                ChangeKind.RETURN_CONSTANT_FOLDED,
            }
            for f in fd.findings
        )
        if ratio >= _INSTR_COLLAPSE_RATIO or already_flagged:
            return

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.INSTRUCTION_COUNT_COLLAPSE,
            severity=_DEFAULT_SEVERITY[ChangeKind.INSTRUCTION_COUNT_COLLAPSE],
            description=(
                f"Instruction count dropped {n0}→{n2} "
                f"({100*(1-ratio):.0f}% reduction) at -O2"
            ),
            detail_O0=f"{n0} instructions at -O0",
            detail_O2=f"{n2} instructions at -O2",
            source_file=fn0.source_file,
            source_line=fn0.source_line,
        ))

    # ------------------------------------------------------------------
    # Pass 7 — Overflow flag dropped
    #
    # Clang emits 'add nsw' / 'add nuw' (no signed/unsigned wrap) flags
    # at -O0 to record the programmer's intent.  At -O2 the optimizer
    # may *use* these flags to eliminate checks and then drop them, or
    # the add itself may be gone.  The flag's presence at -O0 with
    # absence at -O2 (while the add still exists) signals the optimizer
    # exploited the UB guarantee.
    # ------------------------------------------------------------------

    def _pass_overflow_flag_dropped(
        self, fn0: Function, fn2: Function, fd: FunctionDiff
    ) -> None:
        def arith_with_flags(fn: Function) -> list[tuple[str, set[str]]]:
            """Return (raw_instr, {flags}) for arithmetic instrs with UB flags.

            Covers both integer arithmetic (nsw/nuw on add/sub/mul/shl) and
            pointer arithmetic (inbounds on getelementptr).  Both are UB
            assumptions that the optimizer exploits to remove overflow checks.
            """
            results = []
            for instr in fn.all_instructions:
                if instr.opcode in {"add", "sub", "mul", "shl"}:
                    flags = set(_OVERFLOW_FLAGS.findall(instr.raw))
                    if flags:
                        results.append((instr.raw, flags))
                elif instr.opcode == "getelementptr" and "inbounds" in instr.raw:
                    # `getelementptr inbounds` carries the same UB guarantee as nsw:
                    # the result must not wrap the address space.  Compilers exploit
                    # this to eliminate pointer-wrap security checks.
                    results.append((instr.raw, {"inbounds"}))
            return results

        flagged_O0 = arith_with_flags(fn0)
        flagged_O2 = arith_with_flags(fn2)

        if not flagged_O0:
            return

        # Reduction in flagged arithmetic instructions signals exploitation
        dropped = len(flagged_O0) - len(flagged_O2)
        if dropped <= 0:
            return

        # Collect flags that appeared in O0 but are gone in O2
        flags_O0 = {f for _, fs in flagged_O0 for f in fs}
        flags_O2 = {f for _, fs in flagged_O2 for f in fs}
        exploited_flags = flags_O0 - flags_O2

        if not exploited_flags:
            return

        fd.findings.append(Finding(
            function_name=fn0.name,
            change_kind=ChangeKind.OVERFLOW_FLAG_DROPPED,
            severity=_DEFAULT_SEVERITY[ChangeKind.OVERFLOW_FLAG_DROPPED],
            description=(
                f"Arithmetic overflow flags {exploited_flags} present at -O0 "
                f"are dropped/exploited at -O2 "
                f"({dropped} of {len(flagged_O0)} flagged instruction(s) eliminated)"
            ),
            detail_O0=(
                f"{len(flagged_O0)} arithmetic instruction(s) with UB flags "
                f"({', '.join(sorted(flags_O0))})"
            ),
            detail_O2=(
                f"{len(flagged_O2)} remain; flags dropped: "
                f"{', '.join(sorted(exploited_flags))}"
            ),
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            ir_O0_snippet="\n".join(f"  {raw}" for raw, _ in flagged_O0),
            ir_O2_snippet="\n".join(
                f"  {raw}" for raw, _ in flagged_O2
            ) if flagged_O2 else "  (none — all eliminated)",
        ))


# ---------------------------------------------------------------------------
# CLI entry point  (python -m analysis.diff_engine <O0.ll> <O2.ll>)
# ---------------------------------------------------------------------------

def main(argv=None) -> int:
    import argparse, sys

    ap = argparse.ArgumentParser(
        prog="analysis.diff_engine",
        description="Compare O0 and O2 IR files and report behavioral changes.",
    )
    ap.add_argument("O0_ll", help="Path to -O0 .ll file")
    ap.add_argument("O2_ll", help="Path to -O2 .ll file")
    ap.add_argument("--verbose", "-v", action="store_true",
                    help="Print IR snippets for each finding")
    ap.add_argument("--all", action="store_true",
                    help="Show unchanged functions too")
    args = ap.parse_args(argv)

    try:
        report = DiffEngine.diff_files(args.O0_ll, args.O2_ll)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(report.summary())
    print()

    for fd in report.function_diffs:
        if not fd.changed and not args.all:
            continue

        status = f"[{fd.max_severity.value}]" if fd.changed else "[OK]"
        print(
            f"{status} @{fd.name}  "
            f"blocks: {fd.blocks_O0}→{fd.blocks_O2}  "
            f"instrs: {fd.instrs_O0}→{fd.instrs_O2}  "
            f"cond-br: {fd.cond_branches_O0}→{fd.cond_branches_O2}"
        )
        for finding in fd.findings:
            print(f"  • [{finding.change_kind.value}] {finding.description}")
            if args.verbose:
                if finding.detail_O0:
                    print(f"    O0: {finding.detail_O0}")
                if finding.detail_O2:
                    print(f"    O2: {finding.detail_O2}")
                if finding.ir_O0_snippet:
                    print(f"    IR@O0:\n{finding.ir_O0_snippet}")
                if finding.ir_O2_snippet:
                    print(f"    IR@O2:\n{finding.ir_O2_snippet}")
        print()

    if not report.findings:
        print("No behavioral changes detected.")

    return 0 if not report.findings else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
