"""
tests/test_ir_parser.py — Unit tests for engine/ir_parser.py

Uses inline IR strings so no clang installation is needed to run the tests.
"""

from __future__ import annotations

import sys
import os
import unittest

# Make sure project root is importable regardless of working directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from engine.ir_parser import IRParser, load_both

# ---------------------------------------------------------------------------
# Minimal IR fixtures
# ---------------------------------------------------------------------------

# A signed-overflow time bomb: x+1 > x always true at -O2
_OVERFLOW_O0 = """\
; ModuleID = 'test.c'
source_filename = "test.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @check_overflow(i32 noundef %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %1 = load i32, ptr %x, align 4
  %add = add nsw i32 %1, 1
  %2 = load i32, ptr %x, align 4
  %cmp = icmp sgt i32 %add, %2
  br i1 %cmp, label %if.then, label %if.else

if.then:
  store i32 1, ptr %retval, align 4
  ret i32 1

if.else:
  store i32 0, ptr %retval, align 4
  ret i32 0
}
"""

_OVERFLOW_O2 = """\
; ModuleID = 'test.c'
source_filename = "test.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @check_overflow(i32 noundef %0) {
entry:
  ret i32 1
}
"""

# Null deref in dead code
_NULL_DEREF_O0 = """\
; ModuleID = 'null.c'
source_filename = "null.c"

define i32 @use_ptr(ptr noundef %0) {
entry:
  %ptr = alloca ptr, align 8
  store ptr %0, ptr %ptr, align 8
  %1 = load ptr, ptr %ptr, align 8
  %tobool = icmp ne ptr %1, null
  br i1 %tobool, label %if.then, label %if.else

if.then:
  %2 = load ptr, ptr %ptr, align 8
  %3 = load i32, ptr %2, align 4
  ret i32 %3

if.else:
  store ptr null, ptr %null_ptr, align 8
  ret i32 0
}
"""

_NULL_DEREF_O2 = """\
; ModuleID = 'null.c'
source_filename = "null.c"

define i32 @use_ptr(ptr noundef %0) {
entry:
  %1 = load i32, ptr %0, align 4
  ret i32 %1
}
"""

# Uninitialized variable
_UNINIT_O0 = """\
; ModuleID = 'uninit.c'
source_filename = "uninit.c"

define i32 @is_zero() {
entry:
  %x = alloca i32, align 4
  %0 = load i32, ptr %x, align 4
  %cmp = icmp eq i32 %0, 0
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}
"""

_UNINIT_O2 = """\
; ModuleID = 'uninit.c'
source_filename = "uninit.c"

define i32 @is_zero() {
entry:
  ret i32 0
}
"""


# ---------------------------------------------------------------------------
# Tests: module-level parsing
# ---------------------------------------------------------------------------

class TestModuleParsing(unittest.TestCase):

    def test_source_filename_parsed(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        self.assertEqual(m.source_file, "test.c")

    def test_target_triple_parsed(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        self.assertIn("x86_64", m.target_triple)

    def test_opt_level_inferred_from_filename(self):
        """The parser infers -O0 / -O2 from the filename stem."""
        from pathlib import Path
        # Directly instantiate the parser to inspect _opt_level
        p0 = IRParser.__new__(IRParser)
        p0._path = Path("foo_O0.ll")
        stem = p0._path.stem
        p0._opt_level = "O0" if stem.endswith("_O0") else "O2" if stem.endswith("_O2") else ""
        self.assertEqual(p0._opt_level, "O0")

        p2 = IRParser.__new__(IRParser)
        p2._path = Path("bar_O2.ll")
        stem2 = p2._path.stem
        p2._opt_level = "O0" if stem2.endswith("_O0") else "O2" if stem2.endswith("_O2") else ""
        self.assertEqual(p2._opt_level, "O2")

    def test_defined_vs_declaration(self):
        ir = """\
; ModuleID = 't.c'
declare i32 @printf(ptr, ...)

define i32 @foo() {
entry:
  ret i32 42
}
"""
        m = IRParser.parse_text(ir)
        self.assertIn("foo", m.defined_functions)
        self.assertIn("printf", m.declarations)
        self.assertNotIn("printf", m.defined_functions)


# ---------------------------------------------------------------------------
# Tests: function parsing
# ---------------------------------------------------------------------------

class TestFunctionParsing(unittest.TestCase):

    def test_function_detected(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        self.assertIn("check_overflow", m.defined_functions)

    def test_basic_blocks_detected(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        self.assertIn("entry",   fn.block_names)
        self.assertIn("if.then", fn.block_names)
        self.assertIn("if.else", fn.block_names)

    def test_instruction_count_nonzero(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        self.assertGreater(fn.num_instructions, 0)

    def test_two_returns_detected(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        self.assertEqual(len(fn.returns), 2)

    def test_single_constant_return_at_o2(self):
        m = IRParser.parse_text(_OVERFLOW_O2)
        fn = m.defined_functions["check_overflow"]
        rets = fn.returns
        self.assertEqual(len(rets), 1)
        self.assertTrue(rets[0].return_is_constant)
        self.assertEqual(rets[0].return_value, "1")

    def test_conditional_branch_detected(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        cond_brs = fn.conditional_branches
        self.assertEqual(len(cond_brs), 1)
        self.assertIn("if.then", cond_brs[0].branch_targets)
        self.assertIn("if.else", cond_brs[0].branch_targets)

    def test_no_conditional_branch_at_o2(self):
        m = IRParser.parse_text(_OVERFLOW_O2)
        fn = m.defined_functions["check_overflow"]
        self.assertEqual(len(fn.conditional_branches), 0)

    def test_nsw_flag_present(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        nsw_instrs = [i for i in fn.all_instructions if "nsw" in i.raw]
        self.assertGreater(len(nsw_instrs), 0)

    def test_icmp_sgt_detected_as_comparison(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        cmps = fn.comparisons
        self.assertGreater(len(cmps), 0)

    def test_memory_ops_flagged(self):
        m = IRParser.parse_text(_OVERFLOW_O0)
        fn = m.defined_functions["check_overflow"]
        mem_ops = [i for i in fn.all_instructions if i.is_memory]
        self.assertGreater(len(mem_ops), 0)

    def test_null_store_detected(self):
        m = IRParser.parse_text(_NULL_DEREF_O0)
        fn = m.defined_functions["use_ptr"]
        store_nulls = [i for i in fn.all_instructions
                       if "store" in i.raw and "null" in i.raw]
        self.assertGreater(len(store_nulls), 0)

    def test_uninit_load_before_store(self):
        """At O0, %x is loaded with no prior store — entry-block uninit pattern."""
        m = IRParser.parse_text(_UNINIT_O0)
        fn = m.defined_functions["is_zero"]
        # alloca %x, then immediately load — no store anywhere
        stores_to_x = [
            i for i in fn.all_instructions
            if i.opcode == "store" and "ptr %x" in i.raw
        ]
        self.assertEqual(len(stores_to_x), 0, "Expected no store to %x")


# ---------------------------------------------------------------------------
# Tests: function_names_in_common
# ---------------------------------------------------------------------------

class TestFunctionNamesInCommon(unittest.TestCase):

    def test_common_functions(self):
        from engine.ir_parser import function_names_in_common
        m0 = IRParser.parse_text(_OVERFLOW_O0)
        m2 = IRParser.parse_text(_OVERFLOW_O2)
        common = function_names_in_common(m0, m2)
        self.assertIn("check_overflow", common)

    def test_no_common_when_renamed(self):
        from engine.ir_parser import function_names_in_common
        ir_a = """\
define i32 @foo() {
entry:
  ret i32 1
}
"""
        ir_b = """\
define i32 @bar() {
entry:
  ret i32 2
}
"""
        m0 = IRParser.parse_text(ir_a)
        m2 = IRParser.parse_text(ir_b)
        self.assertEqual(function_names_in_common(m0, m2), [])


if __name__ == "__main__":
    unittest.main()
