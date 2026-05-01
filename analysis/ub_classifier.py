"""
analysis/ub_classifier.py — UB Pattern Classifier (Deliverable 3)

Maps DiffReport findings + raw IR functions to one of four UB categories:
  a. SIGNED_OVERFLOW   — signed integer arithmetic overflow (nsw flag, sgt/slt icmp)
  b. STRICT_ALIASING   — type-punning via pointer cast (store i32 / load float)
  c. NULL_DEREF        — null pointer dereference in dead code (store ptr null)
  d. UNINIT_VAR        — uninitialized variable read (alloca with no prior store)

Each category has a dedicated heuristic that scores evidence points from:
  - The ChangeKind findings produced by DiffEngine
  - The raw O0 IR function body (instructions, opcodes, operands)

Usage:
    from analysis.ub_classifier import UBClassifier
    from analysis.diff_engine import DiffEngine
    from engine.ir_parser import load_both

    m0, m2 = load_both(ir_O0, ir_O2)
    report  = DiffEngine().diff(m0, m2)
    cresult = UBClassifier().classify(report, m0, m2)

    for c in cresult.classifications:
        print(c.short())
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

from engine.ir_parser import Function, IRModule, Instruction, BasicBlock
from analysis.diff_engine import (
    DiffReport, FunctionDiff, Finding, ChangeKind, Severity,
)


# ---------------------------------------------------------------------------
# UB taxonomy
# ---------------------------------------------------------------------------

class UBCategory(str, Enum):
    SIGNED_OVERFLOW = "signed_integer_overflow"
    STRICT_ALIASING = "strict_aliasing_violation"
    NULL_DEREF      = "null_pointer_dereference"
    UNINIT_VAR      = "uninitialized_variable_use"
    UNKNOWN         = "unknown_ub_pattern"


# Human-readable names and CLAUDE.md descriptions
_CATEGORY_LABEL: dict[UBCategory, str] = {
    UBCategory.SIGNED_OVERFLOW: "Signed Integer Overflow",
    UBCategory.STRICT_ALIASING: "Strict Aliasing Violation",
    UBCategory.NULL_DEREF:      "Null Pointer Dereference (Dead Code)",
    UBCategory.UNINIT_VAR:      "Use of Uninitialized Variable",
    UBCategory.UNKNOWN:         "Unknown UB Pattern",
}

_CATEGORY_EXPLANATION: dict[UBCategory, str] = {
    UBCategory.SIGNED_OVERFLOW: (
        "Signed integer arithmetic overflow is undefined in C/C++. "
        "The compiler assumes it never happens and uses that to eliminate "
        "branches (e.g. x+1 > x is always true at -O2)."
    ),
    UBCategory.STRICT_ALIASING: (
        "Accessing memory through a pointer of a different type (e.g. reading "
        "an int via float*) violates the strict aliasing rule. The compiler may "
        "reorder or eliminate loads/stores based on the assumption they cannot alias."
    ),
    UBCategory.NULL_DEREF: (
        "Dereferencing a null pointer is undefined behaviour. The compiler may "
        "remove an entire code path that it proves must pass through a null deref, "
        "treating that path as dead code."
    ),
    UBCategory.UNINIT_VAR: (
        "Reading an uninitialized variable is undefined behaviour. The compiler "
        "may assume the variable holds any convenient value and constant-fold "
        "comparisons against it."
    ),
    UBCategory.UNKNOWN: (
        "A structural change was detected between -O0 and -O2 IR, but the "
        "specific UB pattern could not be determined from IR heuristics alone."
    ),
}


# ---------------------------------------------------------------------------
# Result dataclass
# ---------------------------------------------------------------------------

@dataclass
class UBClassification:
    """A classified UB finding for one function."""
    function_name: str
    category: UBCategory
    confidence: str          # "high" | "medium" | "low"
    evidence: list[str]      # bullet points of evidence
    source_file: Optional[str] = None
    source_line: Optional[int] = None
    findings: list[Finding] = field(default_factory=list)

    @property
    def label(self) -> str:
        return _CATEGORY_LABEL[self.category]

    @property
    def explanation(self) -> str:
        return _CATEGORY_EXPLANATION[self.category]

    def short(self) -> str:
        loc = f" (line {self.source_line})" if self.source_line else ""
        return (
            f"[{self.confidence.upper()}] @{self.function_name}{loc}: "
            f"{self.label}"
        )

    def __str__(self) -> str:
        lines = [self.short(), f"  → {self.explanation}"]
        for ev in self.evidence:
            lines.append(f"  • {ev}")
        return "\n".join(lines)


@dataclass
class ClassificationReport:
    """Full classification result for one source file."""
    source_file: str
    classifications: list[UBClassification] = field(default_factory=list)
    unclassified: list[Finding] = field(default_factory=list)

    def summary(self) -> str:
        cats = {}
        for c in self.classifications:
            cats[c.label] = cats.get(c.label, 0) + 1
        parts = ", ".join(f"{v}× {k}" for k, v in cats.items())
        return (
            f"ClassificationReport: {self.source_file} | "
            f"{len(self.classifications)} classified "
            f"({parts or 'none'}), "
            f"{len(self.unclassified)} unclassified"
        )


# ---------------------------------------------------------------------------
# IR pattern helpers
# ---------------------------------------------------------------------------

def _instrs(fn: Function) -> list[Instruction]:
    return list(fn.all_instructions)


def _raw(fn: Function) -> str:
    """Full concatenated raw text of all instructions."""
    return "\n".join(i.raw for i in _instrs(fn))


def _opcodes(fn: Function) -> list[str]:
    return [i.opcode for i in _instrs(fn)]


def _has_nsw_nuw(fn: Function) -> bool:
    """True if any arithmetic instruction carries nsw or nuw flag."""
    return any(
        re.search(r'\b(nsw|nuw)\b', i.raw)
        for i in _instrs(fn)
        if i.opcode in {"add", "sub", "mul", "shl"}
    )


def _signed_comparisons(fn: Function) -> list[Instruction]:
    """Return icmp instructions using signed predicates (sgt, slt, sge, sle)."""
    return [
        i for i in _instrs(fn)
        if i.opcode == "icmp"
        and re.search(r'\bicmp\s+s(gt|lt|ge|le)\b', i.raw)
    ]


def _has_null_store(fn: Function) -> bool:
    """True if any block stores 'ptr null' (explicit null assignment)."""
    return any(
        re.search(r'store\s+ptr\s+null', i.raw)
        for i in _instrs(fn)
    )


def _has_null_load(fn: Function) -> bool:
    """True if any instruction loads from a null/zero pointer."""
    return any(
        re.search(r'load\s+\w+,\s+ptr\s+null', i.raw)
        for i in _instrs(fn)
    )


def _has_type_punning_load(fn: Function) -> bool:
    """
    True when a float/double load follows an integer store to the same alloca
    (or vice-versa) — the opaque-pointer strict aliasing signature in clang-18.
    """
    # Collect alloca names and the types stored to each
    stored_types: dict[str, str] = {}   # alloca_name → stored type
    loaded_types: dict[str, str] = {}   # alloca_name → loaded type

    for instr in _instrs(fn):
        # store <type> <val>, ptr %name
        sm = re.match(r'store\s+(\S+)\s+.+,\s+ptr\s+(%[\w.$]+)', instr.raw)
        if sm:
            stored_types[sm.group(2)] = sm.group(1)

        # %r = load <type>, ptr %name
        lm = re.match(r'%[\w.$]+\s*=\s*load\s+(\S+),\s+ptr\s+(%[\w.$]+)', instr.raw)
        if lm:
            loaded_types[lm.group(2)] = lm.group(1)

    for ptr, load_type in loaded_types.items():
        store_type = stored_types.get(ptr)
        if store_type and store_type != load_type:
            # Integer store / float load (or vice-versa) — aliasing violation
            int_types  = {"i8", "i16", "i32", "i64", "i128"}
            fp_types   = {"float", "double", "half", "fp128", "x86_fp80"}
            if (
                (store_type in int_types and load_type in fp_types) or
                (store_type in fp_types  and load_type in int_types)
            ):
                return True
    return False


def _alloca_loaded_before_store(fn: Function) -> list[str]:
    """
    Return alloca names that are loaded before any store to them.
    This is the IR signature of an uninitialized variable read.
    """
    uninit: list[str] = []
    stored: set[str] = set()
    # Track stores from function params (they're always initialized)
    for instr in _instrs(fn):
        if instr.opcode == "store":
            # store <type> <val>, ptr %name
            m = re.search(r'store\s+\S+\s+\S+,\s+ptr\s+(%[\w.$]+)', instr.raw)
            if m:
                stored.add(m.group(1))
        elif instr.opcode == "load":
            m = re.match(r'%[\w.$]+\s*=\s*load\s+\S+,\s+ptr\s+(%[\w.$]+)', instr.raw)
            if m:
                ptr = m.group(1)
                if ptr not in stored:
                    uninit.append(ptr)
    return uninit


# ---------------------------------------------------------------------------
# Scoring engine
# ---------------------------------------------------------------------------

# Minimum score to emit a classification at a given confidence
_THRESHOLDS = {"high": 3, "medium": 2, "low": 1}


def _confidence(score: int) -> str:
    if score >= _THRESHOLDS["high"]:
        return "high"
    if score >= _THRESHOLDS["medium"]:
        return "medium"
    return "low"


# ---------------------------------------------------------------------------
# Per-category heuristics
# ---------------------------------------------------------------------------

def _score_signed_overflow(
    fd: FunctionDiff, fn0: Function
) -> tuple[int, list[str]]:
    score = 0
    evidence: list[str] = []

    if _has_nsw_nuw(fn0):
        score += 2
        evidence.append("O0 IR contains 'add nsw'/'sub nsw' — signed overflow is UB and the flag is a compiler hint")

    signed_cmps = _signed_comparisons(fn0)
    if signed_cmps:
        score += 1
        evidence.append(f"O0 IR has {len(signed_cmps)} signed comparison(s) (icmp sgt/slt) — typical overflow-check pattern")

    cond_elim = any(f.change_kind == ChangeKind.CONDITIONAL_BRANCH_ELIMINATED for f in fd.findings)
    if cond_elim:
        score += 2
        evidence.append("Conditional branch eliminated at -O2 (optimizer proved condition always true/false via no-overflow assumption)")

    flag_drop = any(f.change_kind == ChangeKind.OVERFLOW_FLAG_DROPPED for f in fd.findings)
    if flag_drop:
        score += 2
        evidence.append("Overflow flag (nsw/nuw) dropped/exploited at -O2")

    ret_folded = any(f.change_kind == ChangeKind.RETURN_CONSTANT_FOLDED for f in fd.findings)
    if ret_folded and (signed_cmps or _has_nsw_nuw(fn0)):
        score += 1
        evidence.append("Return value constant-folded — optimizer proved result from overflow assumption")

    return score, evidence


def _score_strict_aliasing(
    fd: FunctionDiff,
    fn0: Function,
    module_has_type_punning: bool = False,
    punning_functions: list[str] | None = None,
) -> tuple[int, list[str]]:
    score = 0
    evidence: list[str] = []
    punning_functions = punning_functions or []

    if _has_type_punning_load(fn0):
        score += 3
        evidence.append("O0 IR: store and load to same alloca use different types (e.g. store i32, load float) — strict aliasing violation")

    # bitcast between incompatible pointer types (older LLVM style)
    if re.search(r'bitcast\s+\w+\*\s+%[\w.$]+\s+to\s+\w+\*', _raw(fn0)):
        score += 2
        evidence.append("O0 IR: bitcast between incompatible pointer types")

    # inttoptr / ptrtoint (extreme aliasing violation)
    if "inttoptr" in _raw(fn0) or "ptrtoint" in _raw(fn0):
        score += 1
        evidence.append("O0 IR: inttoptr/ptrtoint conversion — possible aliasing violation")

    # Instruction-count collapse without structural changes (aliasing may
    # cause invisible load/store reordering rather than block removal)
    collapse = any(f.change_kind == ChangeKind.INSTRUCTION_COUNT_COLLAPSE for f in fd.findings)
    no_branch_elim = not any(
        f.change_kind in {ChangeKind.CONDITIONAL_BRANCH_ELIMINATED, ChangeKind.BASIC_BLOCK_REMOVED}
        for f in fd.findings
    )
    if collapse and no_branch_elim:
        score += 1
        evidence.append("Significant instruction-count reduction without branch elimination — consistent with load/store reordering")

    # Cross-function: a callee in this module has a type-punning load,
    # and this function (caller) shows observable optimization effects.
    if module_has_type_punning and punning_functions and (collapse or fd.changed):
        if not _has_type_punning_load(fn0):   # don't double-count
            score += 2
            evidence.append(
                f"Module contains strict aliasing violation in: "
                f"{', '.join(punning_functions)} — optimizer effects propagated to caller"
            )

    return score, evidence


def _score_null_deref(
    fd: FunctionDiff, fn0: Function
) -> tuple[int, list[str]]:
    score = 0
    evidence: list[str] = []

    if _has_null_store(fn0):
        score += 3
        evidence.append("O0 IR: explicit 'store ptr null' — null pointer assigned in code")

    if _has_null_load(fn0):
        score += 3
        evidence.append("O0 IR: load through null pointer — dereferencing null")

    block_removed = any(f.change_kind == ChangeKind.BASIC_BLOCK_REMOVED for f in fd.findings)
    if block_removed:
        # Check if any removed block sits in the else-branch of a null check
        cond_branch_in_entry = any(
            i.is_conditional_branch and
            re.search(r'icmp\s+(ne|eq)\s+ptr\s+%[\w.$]+,\s+null', i.raw)
            for bb in fn0.basic_blocks
            for i in bb.instructions
        )
        if cond_branch_in_entry:
            score += 2
            evidence.append("Removed block is the dead branch of a null-check (icmp ptr ... null)")
        else:
            score += 1
            evidence.append("Basic block dead-code-eliminated at -O2")

    # Null check pattern: icmp ne/eq ptr %x, null
    null_checks = [
        i for i in _instrs(fn0)
        if i.opcode == "icmp" and re.search(r'icmp\s+(ne|eq)\s+ptr', i.raw)
    ]
    if null_checks:
        score += 1
        evidence.append(f"O0 IR: {len(null_checks)} null-pointer comparison(s) (icmp ne/eq ptr ... null)")

    return score, evidence


def _score_uninit_var(
    fd: FunctionDiff, fn0: Function
) -> tuple[int, list[str]]:
    score = 0
    evidence: list[str] = []

    uninit_ptrs = _alloca_loaded_before_store(fn0)
    if uninit_ptrs:
        score += 3
        evidence.append(
            f"O0 IR: {len(uninit_ptrs)} alloca(s) read before any store "
            f"— uninitialized variable use ({', '.join(uninit_ptrs[:3])})"
        )

    ret_folded = any(f.change_kind == ChangeKind.RETURN_CONSTANT_FOLDED for f in fd.findings)
    cmp_elim   = any(f.change_kind == ChangeKind.COMPARISON_ELIMINATED for f in fd.findings)

    if ret_folded and cmp_elim:
        score += 2
        evidence.append("Return value and comparison both constant-folded — optimizer assumed a specific uninitialized value")
    elif ret_folded:
        score += 1
        evidence.append("Return value constant-folded at -O2")
    elif cmp_elim:
        score += 1
        evidence.append("Comparison eliminated at -O2 (consistent with uninitialized value folding)")

    # No overflow flags (distinguishes from signed-overflow category)
    if not _has_nsw_nuw(fn0) and uninit_ptrs:
        score += 1
        evidence.append("No nsw/nuw arithmetic flags — rules out signed overflow as primary cause")

    return score, evidence


# ---------------------------------------------------------------------------
# Classifier
# ---------------------------------------------------------------------------

class UBClassifier:
    """
    Classifies each changed function in a DiffReport into a UB category.

    Strategy
    --------
    For each function with at least one HIGH/MEDIUM finding, run all four
    category scorers.  The category with the highest score wins.
    If the winning score is below the LOW threshold, the function is marked
    UNKNOWN.  Multiple categories can be emitted for the same function if
    scores are tied or within 1 point (rare, but possible in complex code).
    """

    def classify(
        self,
        diff_report: DiffReport,
        m0: IRModule,
        m2: IRModule,
    ) -> ClassificationReport:
        result = ClassificationReport(source_file=diff_report.source_file)

        # Pre-scan: find any function in the module with type-punning loads.
        # Strict aliasing effects often surface as instruction collapse in a
        # *caller* (e.g. main) while the actual violation is in the callee.
        module_has_type_punning = any(
            _has_type_punning_load(fn)
            for fn in m0.defined_functions.values()
        )
        punning_functions = [
            fn.name for fn in m0.defined_functions.values()
            if _has_type_punning_load(fn)
        ]

        for fd in diff_report.changed_functions:
            fn0 = m0.defined_functions.get(fd.name)
            if fn0 is None:
                for f in fd.findings:
                    result.unclassified.append(f)
                continue

            classification = self._classify_function(
                fd, fn0,
                module_has_type_punning=module_has_type_punning,
                punning_functions=punning_functions,
            )
            if classification.category == UBCategory.UNKNOWN:
                result.unclassified.extend(fd.findings)
            result.classifications.append(classification)

        return result

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _classify_function(
        self,
        fd: FunctionDiff,
        fn0: Function,
        module_has_type_punning: bool = False,
        punning_functions: list[str] | None = None,
    ) -> UBClassification:
        punning_functions = punning_functions or []
        scorers = [
            (UBCategory.SIGNED_OVERFLOW, lambda fd, fn: _score_signed_overflow(fd, fn)),
            (UBCategory.NULL_DEREF,      lambda fd, fn: _score_null_deref(fd, fn)),
            (UBCategory.UNINIT_VAR,      lambda fd, fn: _score_uninit_var(fd, fn)),
            (UBCategory.STRICT_ALIASING, lambda fd, fn: _score_strict_aliasing(
                fd, fn,
                module_has_type_punning=module_has_type_punning,
                punning_functions=punning_functions,
            )),
        ]

        results: list[tuple[UBCategory, int, list[str]]] = []
        for cat, scorer in scorers:
            score, evidence = scorer(fd, fn0)
            results.append((cat, score, evidence))

        # Sort by score descending
        results.sort(key=lambda t: t[1], reverse=True)
        best_cat, best_score, best_evidence = results[0]

        if best_score < _THRESHOLDS["low"]:
            return UBClassification(
                function_name=fd.name,
                category=UBCategory.UNKNOWN,
                confidence="low",
                evidence=["No strong IR signatures found for any known UB category"],
                source_file=fn0.source_file,
                source_line=fn0.source_line,
                findings=fd.findings,
            )

        return UBClassification(
            function_name=fd.name,
            category=best_cat,
            confidence=_confidence(best_score),
            evidence=best_evidence,
            source_file=fn0.source_file,
            source_line=fn0.source_line,
            findings=fd.findings,
        )


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main(argv=None) -> int:
    import argparse, sys
    from engine.ir_parser import load_both
    from analysis.diff_engine import DiffEngine

    ap = argparse.ArgumentParser(
        prog="analysis.ub_classifier",
        description="Classify UB patterns from O0/O2 IR diff.",
    )
    ap.add_argument("O0_ll", help="Path to -O0 .ll file")
    ap.add_argument("O2_ll", help="Path to -O2 .ll file")
    ap.add_argument("--verbose", "-v", action="store_true",
                    help="Print evidence bullets")
    args = ap.parse_args(argv)

    try:
        m0, m2 = load_both(args.O0_ll, args.O2_ll)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    report = DiffEngine().diff(m0, m2)
    cresult = UBClassifier().classify(report, m0, m2)

    print(cresult.summary())
    print()

    for c in cresult.classifications:
        print(c.short())
        print(f"  Explanation: {c.explanation}")
        if args.verbose:
            for ev in c.evidence:
                print(f"  • {ev}")
        print()

    if cresult.unclassified:
        print(f"Unclassified findings: {len(cresult.unclassified)}")
        for f in cresult.unclassified:
            print(f"  {f.short()}")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
