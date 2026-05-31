"""
tests/test_diff_engine.py — Unit tests for analysis/diff_engine.py

Each test constructs minimal O0/O2 IR strings, parses them, and asserts that
the expected detection pass fires (or doesn't fire).
"""

from __future__ import annotations

import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from engine.ir_parser import IRParser
from analysis.diff_engine import DiffEngine, ChangeKind, Severity

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _diff(o0_text: str, o2_text: str):
    """Parse two inline IR strings and return the DiffReport."""
    m0 = IRParser.parse_text(o0_text, path="test_O0.ll")
    m2 = IRParser.parse_text(o2_text, path="test_O2.ll")
    return DiffEngine().diff(m0, m2)


def _finding_kinds(report) -> set[str]:
    return {f.change_kind.value for f in report.findings}


# ---------------------------------------------------------------------------
# Shared IR fixtures
# ---------------------------------------------------------------------------

_HEADER = """\
; ModuleID = 'test.c'
source_filename = "test.c"
target triple = "x86_64-unknown-linux-gnu"
"""

# O0: function with a conditional branch
_COND_BR_O0 = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %1 = load i32, ptr %x
  %add = add nsw i32 %1, 1
  %2 = load i32, ptr %x
  %cmp = icmp sgt i32 %add, %2
  br i1 %cmp, label %if.then, label %if.else

if.then:
  ret i32 1

if.else:
  ret i32 0
}
"""

# O2: conditional branch eliminated, always returns 1
_COND_BR_O2 = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  ret i32 1
}
"""

# O0: function with two named basic blocks beyond entry
_BLOCKS_O0 = _HEADER + """\
define i32 @g(i32 %0) {
entry:
  %cmp = icmp sgt i32 %0, 0
  br i1 %cmp, label %pos, label %neg

pos:
  ret i32 1

neg:
  ret i32 -1
}
"""

# O2: both named blocks removed, function simplified
_BLOCKS_O2 = _HEADER + """\
define i32 @g(i32 %0) {
entry:
  %cmp = icmp sgt i32 %0, 0
  %sel = select i1 %cmp, i32 1, i32 -1
  ret i32 %sel
}
"""

# O0: variable return
_RET_VAR_O0 = _HEADER + """\
define i32 @h(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %1 = load i32, ptr %x
  ret i32 %1
}
"""

# O2: constant-folded return
_RET_CONST_O2 = _HEADER + """\
define i32 @h(i32 %0) {
entry:
  ret i32 1
}
"""

# O0: function with two icmp instructions
_CMP_O0 = _HEADER + """\
define i32 @cmpfn(i32 %a, i32 %b) {
entry:
  %c1 = icmp sgt i32 %a, 0
  %c2 = icmp slt i32 %b, 100
  %r = add i32 %a, %b
  ret i32 %r
}
"""

# O2: comparisons folded away
_CMP_O2 = _HEADER + """\
define i32 @cmpfn(i32 %a, i32 %b) {
entry:
  %r = add i32 %a, %b
  ret i32 %r
}
"""

# O0: no unreachable
_UNREACH_O0 = _HEADER + """\
define void @ufn(i32 %0) {
entry:
  %cmp = icmp sgt i32 %0, 0
  br i1 %cmp, label %ok, label %bad

ok:
  ret void

bad:
  ret void
}
"""

# O2: bad path becomes unreachable
_UNREACH_O2 = _HEADER + """\
define void @ufn(i32 %0) {
entry:
  %cmp = icmp sgt i32 %0, 0
  br i1 %cmp, label %ok, label %bad

ok:
  ret void

bad:
  unreachable
}
"""

# O0: large function
_COLLAPSE_O0 = _HEADER + """\
define i32 @big(i32 %0) {
entry:
  %a = add i32 %0, 1
  %b = add i32 %a, 2
  %c = add i32 %b, 3
  %d = add i32 %c, 4
  %e = add i32 %d, 5
  %f = add i32 %e, 6
  %g = add i32 %f, 7
  %h = add i32 %g, 8
  %i = add i32 %h, 9
  ret i32 %i
}
"""

# O2: dramatically fewer instructions (> 60% reduction)
_COLLAPSE_O2 = _HEADER + """\
define i32 @big(i32 %0) {
entry:
  %r = add i32 %0, 45
  ret i32 %r
}
"""

# O0: arithmetic with nsw flags
_OVERFLOW_FLAG_O0 = _HEADER + """\
define i32 @arith(i32 %0) {
entry:
  %a = add nsw i32 %0, 1
  %b = sub nsw i32 %a, 2
  ret i32 %b
}
"""

# O2: nsw flags dropped / instructions eliminated
_OVERFLOW_FLAG_O2 = _HEADER + """\
define i32 @arith(i32 %0) {
entry:
  %a = add i32 %0, -1
  ret i32 %a
}
"""


# ---------------------------------------------------------------------------
# Pass 1 — conditional_branch_eliminated
# ---------------------------------------------------------------------------

class TestPassConditionalBranchEliminated(unittest.TestCase):

    def test_fires_when_branch_eliminated(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        self.assertIn(ChangeKind.CONDITIONAL_BRANCH_ELIMINATED.value, _finding_kinds(report))

    def test_severity_is_high(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        hi = [f for f in report.findings
              if f.change_kind == ChangeKind.CONDITIONAL_BRANCH_ELIMINATED]
        self.assertTrue(all(f.severity == Severity.HIGH for f in hi))

    def test_does_not_fire_when_branches_preserved(self):
        report = _diff(_BLOCKS_O0, _BLOCKS_O0)  # same IR → no change
        self.assertNotIn(ChangeKind.CONDITIONAL_BRANCH_ELIMINATED.value, _finding_kinds(report))


# ---------------------------------------------------------------------------
# Pass 2 — basic_block_removed
# ---------------------------------------------------------------------------

class TestPassBasicBlockRemoved(unittest.TestCase):

    def test_fires_when_named_block_disappears(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        self.assertIn(ChangeKind.BASIC_BLOCK_REMOVED.value, _finding_kinds(report))

    def test_removed_block_names_in_description(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.BASIC_BLOCK_REMOVED]
        self.assertTrue(len(findings) > 0)
        combined = " ".join(f.description for f in findings)
        # at least one of the removed block names should appear
        self.assertTrue("if.then" in combined or "if.else" in combined)

    def test_does_not_fire_for_entry_removal(self):
        """entry block is always excluded from the interesting set."""
        report = _diff(_RET_VAR_O0, _RET_CONST_O2)
        block_findings = [f for f in report.findings
                          if f.change_kind == ChangeKind.BASIC_BLOCK_REMOVED]
        for f in block_findings:
            self.assertNotIn("entry", f.description)


# ---------------------------------------------------------------------------
# Pass 3 — return_constant_folded
# Use a separate fixture where O0 has a genuine runtime variable return
# ---------------------------------------------------------------------------

# O0: function returns a runtime register value (non-constant)
_RET_FOLD_O0 = _HEADER + """\
define i32 @retfold(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %1 = load i32, ptr %x
  %add = add nsw i32 %1, 1
  %2 = load i32, ptr %x
  %cmp = icmp sgt i32 %add, %2
  %retval = alloca i32
  br i1 %cmp, label %t, label %f
t:
  store i32 1, ptr %retval
  br label %done
f:
  store i32 0, ptr %retval
  br label %done
done:
  %r = load i32, ptr %retval
  ret i32 %r
}
"""

# O2: always returns the constant 1 (the comparison was folded away)
_RET_FOLD_O2 = _HEADER + """\
define i32 @retfold(i32 %0) {
entry:
  ret i32 1
}
"""


class TestPassReturnConstantFolded(unittest.TestCase):

    def test_fires_when_variable_return_becomes_constant(self):
        report = _diff(_RET_FOLD_O0, _RET_FOLD_O2)
        self.assertIn(ChangeKind.RETURN_CONSTANT_FOLDED.value, _finding_kinds(report))

    def test_detail_mentions_constant_value(self):
        report = _diff(_RET_FOLD_O0, _RET_FOLD_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.RETURN_CONSTANT_FOLDED]
        self.assertTrue(len(findings) > 0)
        # The constant '1' should appear in the O2 detail
        self.assertIn("1", findings[0].detail_O2)

    def test_does_not_fire_when_already_constant_at_o0(self):
        # Both O0 and O2 return constants → no "folding" occurred
        ir_const = _HEADER + """\
define i32 @c() {
entry:
  ret i32 42
}
"""
        report = _diff(ir_const, ir_const)
        self.assertNotIn(ChangeKind.RETURN_CONSTANT_FOLDED.value, _finding_kinds(report))


# ---------------------------------------------------------------------------
# Pass 4 — comparison_eliminated
# ---------------------------------------------------------------------------

class TestPassComparisonEliminated(unittest.TestCase):

    def test_fires_when_icmp_removed(self):
        report = _diff(_CMP_O0, _CMP_O2)
        self.assertIn(ChangeKind.COMPARISON_ELIMINATED.value, _finding_kinds(report))

    def test_count_matches_eliminated_instructions(self):
        report = _diff(_CMP_O0, _CMP_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.COMPARISON_ELIMINATED]
        self.assertTrue(len(findings) > 0)
        # 2 comparisons at O0, 0 at O2 → 2 eliminated
        self.assertIn("2", findings[0].description)


# ---------------------------------------------------------------------------
# Pass 5 — unreachable_inserted
# ---------------------------------------------------------------------------

class TestPassUnreachableInserted(unittest.TestCase):

    def test_fires_when_unreachable_added(self):
        report = _diff(_UNREACH_O0, _UNREACH_O2)
        self.assertIn(ChangeKind.UNREACHABLE_INSERTED.value, _finding_kinds(report))

    def test_severity_is_medium(self):
        report = _diff(_UNREACH_O0, _UNREACH_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.UNREACHABLE_INSERTED]
        self.assertTrue(all(f.severity == Severity.MEDIUM for f in findings))


# ---------------------------------------------------------------------------
# Pass 6 — instruction_count_collapse
# ---------------------------------------------------------------------------

class TestPassInstructionCountCollapse(unittest.TestCase):

    def test_fires_for_large_reduction(self):
        report = _diff(_COLLAPSE_O0, _COLLAPSE_O2)
        kinds = _finding_kinds(report)
        # Should fire because there are no structural signals suppressing it
        self.assertIn(ChangeKind.INSTRUCTION_COUNT_COLLAPSE.value, kinds)

    def test_severity_is_low(self):
        report = _diff(_COLLAPSE_O0, _COLLAPSE_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.INSTRUCTION_COUNT_COLLAPSE]
        self.assertTrue(all(f.severity == Severity.LOW for f in findings))

    def test_suppressed_when_higher_signals_present(self):
        """Pass 6 must not fire if passes 1/2/3 already flagged the function."""
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        # Conditional branch eliminated → pass 6 should be suppressed
        self.assertNotIn(ChangeKind.INSTRUCTION_COUNT_COLLAPSE.value, _finding_kinds(report))


# ---------------------------------------------------------------------------
# Pass 7 — overflow_flag_dropped
# ---------------------------------------------------------------------------

class TestPassOverflowFlagDropped(unittest.TestCase):

    def test_fires_when_nsw_eliminated(self):
        report = _diff(_OVERFLOW_FLAG_O0, _OVERFLOW_FLAG_O2)
        self.assertIn(ChangeKind.OVERFLOW_FLAG_DROPPED.value, _finding_kinds(report))

    def test_flags_mentioned_in_description(self):
        report = _diff(_OVERFLOW_FLAG_O0, _OVERFLOW_FLAG_O2)
        findings = [f for f in report.findings
                    if f.change_kind == ChangeKind.OVERFLOW_FLAG_DROPPED]
        self.assertTrue(len(findings) > 0)
        self.assertIn("nsw", findings[0].description)

    def test_getelementptr_inbounds_detected(self):
        """Pass 7 now catches GEP inbounds as an overflow UB flag."""
        gep_o0 = _HEADER + """\
define ptr @advance(ptr %base, i64 %n) {
entry:
  %p = getelementptr inbounds i8, ptr %base, i64 %n
  ret ptr %p
}
"""
        gep_o2 = _HEADER + """\
define ptr @advance(ptr %base, i64 %n) {
entry:
  ret ptr %base
}
"""
        report = _diff(gep_o0, gep_o2)
        self.assertIn(ChangeKind.OVERFLOW_FLAG_DROPPED.value, _finding_kinds(report))

    def test_does_not_fire_when_no_flags(self):
        no_flag_ir = _HEADER + """\
define i32 @plain(i32 %0) {
entry:
  %a = add i32 %0, 1
  ret i32 %a
}
"""
        report = _diff(no_flag_ir, no_flag_ir)
        self.assertNotIn(ChangeKind.OVERFLOW_FLAG_DROPPED.value, _finding_kinds(report))


# ---------------------------------------------------------------------------
# DiffReport helpers
# ---------------------------------------------------------------------------

class TestDiffReportHelpers(unittest.TestCase):

    def test_findings_sorted_high_first(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        findings = report.findings
        # All HIGH findings should come before MEDIUM/LOW
        severities = [f.severity for f in findings]
        order = {Severity.HIGH: 0, Severity.MEDIUM: 1, Severity.LOW: 2}
        for i in range(len(severities) - 1):
            self.assertLessEqual(order[severities[i]], order[severities[i + 1]])

    def test_changed_functions_filtered(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        for fd in report.changed_functions:
            self.assertTrue(fd.changed)

    def test_total_findings_count(self):
        report = _diff(_COND_BR_O0, _COND_BR_O2)
        self.assertEqual(report.total_findings, len(report.findings))


if __name__ == "__main__":
    unittest.main()
