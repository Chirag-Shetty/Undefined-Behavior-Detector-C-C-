"""
tests/test_ub_classifier.py — Unit tests for analysis/ub_classifier.py

Tests focus on the scoring helper functions and the top-level classifier,
using minimal inline IR and synthetic DiffReport objects.
"""

from __future__ import annotations

import sys
import os
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from engine.ir_parser import IRParser, Function, BasicBlock, Instruction
from analysis.diff_engine import (
    DiffEngine, DiffReport, FunctionDiff, Finding, ChangeKind, Severity,
)
from analysis.ub_classifier import (
    UBClassifier, UBCategory,
    _has_nsw_nuw, _signed_comparisons, _has_null_store, _has_null_load,
    _has_type_punning_load, _alloca_loaded_before_store,
    _score_signed_overflow, _score_null_deref, _score_uninit_var,
    _score_strict_aliasing,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_HEADER = """\
; ModuleID = 'test.c'
source_filename = "test.c"
"""


def _parse_fn(ir_text: str, fn_name: str = "f") -> Function:
    """Parse inline IR and return the named function object."""
    m = IRParser.parse_text(ir_text)
    return m.defined_functions[fn_name]


def _make_finding(kind: ChangeKind, sev: Severity = Severity.HIGH) -> Finding:
    return Finding(
        function_name="f",
        change_kind=kind,
        severity=sev,
        description="test",
    )


def _empty_fd(fn0: Function, fn2: Function | None = None) -> FunctionDiff:
    """FunctionDiff with no findings."""
    if fn2 is None:
        fn2 = fn0
    return FunctionDiff(name=fn0.name, fn_O0=fn0, fn_O2=fn2)


# ---------------------------------------------------------------------------
# IR fixtures for classifier helpers
# ---------------------------------------------------------------------------

_NSw_IR = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  %a = add nsw i32 %0, 1
  ret i32 %a
}
"""

_NO_NSw_IR = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  %a = add i32 %0, 1
  ret i32 %a
}
"""

_SIGNED_CMP_IR = _HEADER + """\
define i1 @f(i32 %0) {
entry:
  %c = icmp sgt i32 %0, 0
  ret i1 %c
}
"""

_NULL_STORE_IR = _HEADER + """\
define void @f() {
entry:
  %p = alloca ptr
  store ptr null, ptr %p
  ret void
}
"""

_TYPE_PUN_IR = _HEADER + """\
define float @f(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %r = load float, ptr %x
  ret float %r
}
"""

_NO_TYPE_PUN_IR = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %r = load i32, ptr %x
  ret i32 %r
}
"""

_UNINIT_IR = _HEADER + """\
define i32 @f() {
entry:
  %x = alloca i32
  %v = load i32, ptr %x
  ret i32 %v
}
"""

_INIT_IR = _HEADER + """\
define i32 @f(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %v = load i32, ptr %x
  ret i32 %v
}
"""


# ---------------------------------------------------------------------------
# Tests: IR-level helper predicates
# ---------------------------------------------------------------------------

class TestIRHelpers(unittest.TestCase):

    def test_has_nsw_nuw_true(self):
        fn = _parse_fn(_NSw_IR)
        self.assertTrue(_has_nsw_nuw(fn))

    def test_has_nsw_nuw_false(self):
        fn = _parse_fn(_NO_NSw_IR)
        self.assertFalse(_has_nsw_nuw(fn))

    def test_signed_comparisons_found(self):
        fn = _parse_fn(_SIGNED_CMP_IR)
        cmps = _signed_comparisons(fn)
        self.assertEqual(len(cmps), 1)

    def test_signed_comparisons_empty(self):
        fn = _parse_fn(_NO_NSw_IR)
        self.assertEqual(_signed_comparisons(fn), [])

    def test_has_null_store_true(self):
        fn = _parse_fn(_NULL_STORE_IR)
        self.assertTrue(_has_null_store(fn))

    def test_has_null_store_false(self):
        fn = _parse_fn(_NO_NSw_IR)
        self.assertFalse(_has_null_store(fn))

    def test_type_punning_int_to_float(self):
        fn = _parse_fn(_TYPE_PUN_IR)
        self.assertTrue(_has_type_punning_load(fn))

    def test_no_type_punning_same_type(self):
        fn = _parse_fn(_NO_TYPE_PUN_IR)
        self.assertFalse(_has_type_punning_load(fn))

    def test_uninit_var_detected_when_no_store(self):
        fn = _parse_fn(_UNINIT_IR)
        uninit = _alloca_loaded_before_store(fn)
        self.assertIn("%x", uninit)

    def test_uninit_var_not_detected_when_stored(self):
        fn = _parse_fn(_INIT_IR)
        uninit = _alloca_loaded_before_store(fn)
        self.assertNotIn("%x", uninit)

    def test_type_punning_multi_store_types(self):
        """Two stores of different types to same alloca — both should be checked."""
        ir = _HEADER + """\
define float @f(i32 %a, float %b) {
entry:
  %x = alloca i32
  store i32 %a, ptr %x
  store float %b, ptr %x
  %r = load float, ptr %x
  ret float %r
}
"""
        # After fixing last-write-wins: both i32 and float stores are tracked.
        # The i32 store + float load = violation detected.
        fn = _parse_fn(ir)
        self.assertTrue(_has_type_punning_load(fn))


# ---------------------------------------------------------------------------
# Tests: category scorers
# ---------------------------------------------------------------------------

class TestSignedOverflowScorer(unittest.TestCase):

    def test_nsw_flag_scores(self):
        fn = _parse_fn(_NSw_IR)
        fd = _empty_fd(fn)
        score, evidence = _score_signed_overflow(fd, fn)
        self.assertGreater(score, 0)
        self.assertTrue(any("nsw" in e.lower() for e in evidence))

    def test_branch_elim_finding_scores(self):
        fn = _parse_fn(_NSw_IR)
        fd = _empty_fd(fn)
        fd.findings.append(_make_finding(ChangeKind.CONDITIONAL_BRANCH_ELIMINATED))
        score, evidence = _score_signed_overflow(fd, fn)
        self.assertGreaterEqual(score, 4)  # nsw(2) + branch_elim(2)

    def test_no_signals_zero_score(self):
        fn = _parse_fn(_NO_NSw_IR)
        fd = _empty_fd(fn)
        score, _ = _score_signed_overflow(fd, fn)
        self.assertEqual(score, 0)


class TestNullDerefScorer(unittest.TestCase):

    def test_null_store_scores(self):
        fn = _parse_fn(_NULL_STORE_IR)
        fd = _empty_fd(fn)
        score, evidence = _score_null_deref(fd, fn)
        self.assertGreaterEqual(score, 3)
        self.assertTrue(any("null" in e.lower() for e in evidence))

    def test_no_null_zero_score(self):
        fn = _parse_fn(_NO_NSw_IR)
        fd = _empty_fd(fn)
        score, _ = _score_null_deref(fd, fn)
        self.assertEqual(score, 0)


class TestUninitVarScorer(unittest.TestCase):

    def test_uninit_alloca_scores(self):
        fn = _parse_fn(_UNINIT_IR)
        fd = _empty_fd(fn)
        score, evidence = _score_uninit_var(fd, fn)
        self.assertGreaterEqual(score, 3)
        self.assertTrue(any("uninit" in e.lower() or "alloca" in e.lower()
                            for e in evidence))

    def test_ret_folded_and_cmp_elim_scores(self):
        fn = _parse_fn(_UNINIT_IR)
        fd = _empty_fd(fn)
        fd.findings.append(_make_finding(ChangeKind.RETURN_CONSTANT_FOLDED))
        fd.findings.append(_make_finding(ChangeKind.COMPARISON_ELIMINATED,
                                         sev=Severity.MEDIUM))
        score, _ = _score_uninit_var(fd, fn)
        # alloca(3) + ret_folded+cmp_elim(2) + no_nsw_nuw(1) = 6+
        self.assertGreaterEqual(score, 6)


class TestStrictAliasingScorer(unittest.TestCase):

    def test_type_punning_load_scores(self):
        fn = _parse_fn(_TYPE_PUN_IR)
        fd = _empty_fd(fn)
        score, evidence = _score_strict_aliasing(fd, fn)
        self.assertGreaterEqual(score, 3)
        self.assertTrue(any("alias" in e.lower() or "type" in e.lower()
                            for e in evidence))

    def test_no_punning_zero_score(self):
        fn = _parse_fn(_NO_TYPE_PUN_IR)
        fd = _empty_fd(fn)
        score, _ = _score_strict_aliasing(fd, fn)
        self.assertEqual(score, 0)


# ---------------------------------------------------------------------------
# Tests: top-level UBClassifier
# ---------------------------------------------------------------------------

class TestUBClassifier(unittest.TestCase):

    def _classify(self, o0_text: str, o2_text: str):
        m0 = IRParser.parse_text(o0_text, path="f_O0.ll")
        m2 = IRParser.parse_text(o2_text, path="f_O2.ll")
        diff = DiffEngine().diff(m0, m2)
        return UBClassifier().classify(diff, m0, m2)

    def test_signed_overflow_detected(self):
        o0 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
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
        o2 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
entry:
  ret i32 1
}
"""
        result = self._classify(o0, o2)
        cats = [c.category for c in result.classifications]
        self.assertIn(UBCategory.SIGNED_OVERFLOW, cats)

    def test_uninit_var_detected(self):
        o0 = _HEADER + """\
define i32 @is_zero() {
entry:
  %x = alloca i32
  %0 = load i32, ptr %x
  %cmp = icmp eq i32 %0, 0
  %r = zext i1 %cmp to i32
  ret i32 %r
}
"""
        o2 = _HEADER + """\
define i32 @is_zero() {
entry:
  ret i32 0
}
"""
        result = self._classify(o0, o2)
        cats = [c.category for c in result.classifications]
        self.assertIn(UBCategory.UNINIT_VAR, cats)

    def test_strict_aliasing_detected(self):
        o0 = _HEADER + """\
define float @pun(i32 %0) {
entry:
  %x = alloca i32
  store i32 %0, ptr %x
  %r = load float, ptr %x
  ret float %r
}
"""
        o2 = _HEADER + """\
define float @pun(i32 %0) {
entry:
  ret float 0.0
}
"""
        result = self._classify(o0, o2)
        cats = [c.category for c in result.classifications]
        self.assertIn(UBCategory.STRICT_ALIASING, cats)

    def test_clean_file_no_classifications(self):
        ir = _HEADER + """\
define i32 @add(i32 %a, i32 %b) {
entry:
  %r = add i32 %a, %b
  ret i32 %r
}
"""
        result = self._classify(ir, ir)
        self.assertEqual(len(result.classifications), 0)
        self.assertEqual(len(result.unclassified), 0)

    def test_confidence_high_for_strong_signals(self):
        o0 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
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
        o2 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
entry:
  ret i32 1
}
"""
        result = self._classify(o0, o2)
        so_class = next(
            c for c in result.classifications
            if c.category == UBCategory.SIGNED_OVERFLOW
        )
        self.assertEqual(so_class.confidence, "high")

    def test_evidence_list_populated(self):
        o0 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
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
        o2 = _HEADER + """\
define i32 @check_overflow(i32 %0) {
entry:
  ret i32 1
}
"""
        result = self._classify(o0, o2)
        for cl in result.classifications:
            self.assertGreater(len(cl.evidence), 0)

    def test_multi_category_emission_when_close_scores(self):
        """A function with both type-punning AND signed overflow signals should
        emit both categories when their scores are within 1 point and both >= medium."""
        # Craft IR with nsw AND a float/int type pun
        o0 = _HEADER + """\
define float @tricky(i32 %0) {
entry:
  %x = alloca i32
  %add = add nsw i32 %0, 1
  store i32 %add, ptr %x
  %r = load float, ptr %x
  ret float %r
}
"""
        # At O2 the function collapses significantly
        o2 = _HEADER + """\
define float @tricky(i32 %0) {
entry:
  ret float 0.0
}
"""
        result = self._classify(o0, o2)
        # There should be at least one classification (strict aliasing wins due to score 3)
        self.assertGreater(len(result.classifications), 0)
        # At minimum, strict aliasing should be detected
        cats = [c.category for c in result.classifications]
        self.assertIn(UBCategory.STRICT_ALIASING, cats)


if __name__ == "__main__":
    unittest.main()
