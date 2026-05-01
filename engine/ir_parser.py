"""
engine/ir_parser.py — LLVM IR Parser

Parses .ll files produced by clang-18 and extracts:
  - Module-level metadata (source file, target triple, globals)
  - Function definitions (name, return type, parameters, attributes)
  - Basic blocks (name, predecessor list)
  - Instructions (opcode, operands, result, debug location)
  - Branch instructions (conditional/unconditional, targets)
  - Return instructions (constant vs variable return values)

Usage:
    from engine.ir_parser import IRParser

    module = IRParser.parse_file("output/signed_overflow/signed_overflow_O0.ll")
    for fn in module.functions.values():
        print(fn.name, len(fn.basic_blocks), "blocks")
        for bb in fn.basic_blocks:
            print(" ", bb.name, bb.terminator)
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class DebugLoc:
    """Source location decoded from !DILocation metadata."""
    line: int
    column: int
    scope_id: int   # raw !N index — resolved lazily if needed

    def __str__(self) -> str:
        return f"line {self.line}, col {self.column}"


@dataclass
class Instruction:
    """A single LLVM IR instruction."""
    raw: str                        # full text of the line, stripped
    opcode: str                     # e.g. "br", "icmp", "ret", "store" …
    result: Optional[str] = None    # LHS name if present, e.g. "%cmp"
    operands: list[str] = field(default_factory=list)
    debug_loc: Optional[DebugLoc] = None

    # Derived flags (set by parser)
    is_terminator: bool = False     # br / ret / switch / unreachable / …
    is_branch: bool = False         # any br instruction
    is_conditional_branch: bool = False
    is_return: bool = False
    is_call: bool = False
    is_cmp: bool = False            # icmp / fcmp
    is_memory: bool = False         # load / store / alloca

    # Branch-specific fields
    branch_targets: list[str] = field(default_factory=list)   # label names
    branch_condition: Optional[str] = None                    # %cmp reg

    # Return-specific
    return_value: Optional[str] = None   # "1", "%val", "void", …
    return_is_constant: bool = False

    def __str__(self) -> str:
        return self.raw


@dataclass
class BasicBlock:
    """A single LLVM IR basic block."""
    name: str                                   # e.g. "entry", "if.then"
    predecessors: list[str] = field(default_factory=list)  # from "; preds ="
    instructions: list[Instruction] = field(default_factory=list)
    terminator: Optional[Instruction] = None    # last instruction

    @property
    def num_instructions(self) -> int:
        return len(self.instructions)

    @property
    def has_conditional_branch(self) -> bool:
        return self.terminator is not None and self.terminator.is_conditional_branch

    @property
    def successor_names(self) -> list[str]:
        if self.terminator:
            return self.terminator.branch_targets
        return []


@dataclass
class Function:
    """A single LLVM IR function definition."""
    name: str
    return_type: str
    params: list[str] = field(default_factory=list)
    attributes: str = ""            # raw attribute string
    basic_blocks: list[BasicBlock] = field(default_factory=list)
    is_declaration: bool = False    # True for 'declare' (no body)

    # Source info from debug metadata
    source_line: Optional[int] = None
    source_file: Optional[str] = None

    @property
    def num_blocks(self) -> int:
        return len(self.basic_blocks)

    @property
    def num_instructions(self) -> int:
        return sum(bb.num_instructions for bb in self.basic_blocks)

    @property
    def block_names(self) -> list[str]:
        return [bb.name for bb in self.basic_blocks]

    def get_block(self, name: str) -> Optional[BasicBlock]:
        for bb in self.basic_blocks:
            if bb.name == name:
                return bb
        return None

    @property
    def all_instructions(self):
        for bb in self.basic_blocks:
            yield from bb.instructions

    @property
    def branches(self) -> list[Instruction]:
        return [i for i in self.all_instructions if i.is_branch]

    @property
    def conditional_branches(self) -> list[Instruction]:
        return [i for i in self.all_instructions if i.is_conditional_branch]

    @property
    def returns(self) -> list[Instruction]:
        return [i for i in self.all_instructions if i.is_return]

    @property
    def comparisons(self) -> list[Instruction]:
        return [i for i in self.all_instructions if i.is_cmp]

    def summary(self) -> str:
        cond_br = len(self.conditional_branches)
        rets = self.returns
        ret_str = ", ".join(r.return_value or "?" for r in rets)
        return (
            f"@{self.name}: {self.num_blocks} blocks, "
            f"{self.num_instructions} instrs, "
            f"{cond_br} cond-branches, "
            f"returns=[{ret_str}]"
        )


@dataclass
class IRModule:
    """
    Top-level representation of one parsed .ll file.

    Attributes
    ----------
    path        : source .ll file path
    opt_level   : "O0" or "O2" (inferred from filename if not set)
    source_file : original C/C++ filename from ModuleID comment
    functions   : dict mapping function name → Function
    globals     : list of raw global variable lines
    metadata    : dict mapping !N → raw metadata string
    """
    path: Path
    opt_level: str = ""
    source_file: str = ""
    target_triple: str = ""
    functions: dict[str, Function] = field(default_factory=dict)
    declarations: dict[str, Function] = field(default_factory=dict)
    globals: list[str] = field(default_factory=list)
    metadata: dict[int, str] = field(default_factory=dict)

    @property
    def defined_functions(self) -> dict[str, Function]:
        """Only functions with a body (excludes declare stubs)."""
        return {n: f for n, f in self.functions.items() if not f.is_declaration}

    def get_function(self, name: str) -> Optional[Function]:
        return self.functions.get(name)

    def summary(self) -> str:
        fns = self.defined_functions
        return (
            f"IRModule({self.path.name}, -{self.opt_level}): "
            f"{len(fns)} functions, "
            f"source={self.source_file or '?'}"
        )


# ---------------------------------------------------------------------------
# Regex patterns (compiled once at module level)
# ---------------------------------------------------------------------------

# Module header
_RE_MODULE_ID   = re.compile(r'^;\s*ModuleID\s*=\s*[\'"](.+?)[\'"]')
_RE_TARGET_TRIP = re.compile(r'^target triple\s*=\s*"(.+?)"')
_RE_SOURCE_FILE = re.compile(r'^source_filename\s*=\s*"(.+?)"')

# Function define / declare
_RE_DEFINE  = re.compile(
    r'^define\b.+?@([\w.$]+)\s*\(([^)]*)\)[^{]*\{?$'
)
_RE_DECLARE = re.compile(r'^declare\b.+?@([\w.$]+)\s*\(')
_RE_RETTYPE = re.compile(r'^(?:define|declare)\b\s+(?:\S+\s+)*?([\w\s*<>\[\]{}]+?)\s+@')

# Basic block label:  "name:"  or  "name:  ; preds = %a, %b"
_RE_BB_LABEL = re.compile(r'^([\w.$]+):\s*(?:;.*)?$')
_RE_PREDS    = re.compile(r';\s*preds\s*=\s*(.+)$')

# Instruction result:  "%foo = ..."  or  bare opcode
_RE_RESULT   = re.compile(r'^(%[\w.$]+)\s*=\s*(.+)$')

# Opcode extraction (first identifier word of the RHS)
_RE_OPCODE   = re.compile(r'^\s*([a-z][a-z0-9_]*)')

# Branch:  "br i1 %cond, label %t, label %f"  or  "br label %dest"
_RE_BR_COND  = re.compile(
    r'^br\s+i1\s+(%[\w.$]+)\s*,\s*label\s+(%[\w.$]+)\s*,\s*label\s+(%[\w.$]+)'
)
_RE_BR_UNCOND = re.compile(r'^br\s+label\s+(%[\w.$]+)')

# Return:  "ret void"  or  "ret i32 1"  or  "ret i32 %val"
_RE_RET       = re.compile(r'^ret\s+(\S+)(?:\s+(.+))?$')

# Debug location annotation on an instruction line
_RE_DBGLOC    = re.compile(r'!dbg\s+(!(\d+))')

# Metadata definition:  "!42 = ..."
_RE_META_DEF  = re.compile(r'^(!(\d+))\s*=\s*(.+)$')
_RE_META_LINE = re.compile(r'!DILocation\(line:\s*(\d+),\s*column:\s*(\d+),\s*scope:\s*(!(\d+))')

# DISubprogram — gives us the C source line for a function
_RE_SUBPROG   = re.compile(
    r'distinct\s+!DISubprogram\(name:\s*"([\w.$]+)".*?line:\s*(\d+)',
)

# Global variable line
_RE_GLOBAL    = re.compile(r'^@[\w.$]+\s*=')


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

class IRParser:
    """
    Stateful line-by-line parser for LLVM .ll files.

    Typical use:
        module = IRParser.parse_file("path/to/file.ll")
    """

    # ------------------------------------------------------------------
    # Public entry points
    # ------------------------------------------------------------------

    @classmethod
    def parse_file(cls, path: str | Path) -> IRModule:
        """Parse a .ll file and return an IRModule."""
        path = Path(path)
        if not path.exists():
            raise FileNotFoundError(f"IR file not found: {path}")
        text = path.read_text(errors="replace")
        return cls(path).parse(text)

    @classmethod
    def parse_text(cls, text: str, path: str | Path = Path("(inline)")) -> IRModule:
        """Parse raw .ll text (useful for testing)."""
        return cls(Path(path)).parse(text)

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def __init__(self, path: Path) -> None:
        self._path = path
        # Infer opt level from filename (e.g. "foo_O2.ll")
        stem = path.stem
        if stem.endswith("_O0"):
            self._opt_level = "O0"
        elif stem.endswith("_O2"):
            self._opt_level = "O2"
        else:
            self._opt_level = ""

    def parse(self, text: str) -> IRModule:
        lines = text.splitlines()
        module = IRModule(path=self._path, opt_level=self._opt_level)

        # ---- Pass 1: collect raw metadata strings ----
        self._collect_metadata(lines, module)

        # ---- Pass 2: parse module header + functions ----
        i = 0
        current_fn: Optional[Function] = None
        current_bb: Optional[BasicBlock] = None
        inside_fn = False

        while i < len(lines):
            raw = lines[i]
            stripped = raw.strip()
            i += 1

            # Skip blank lines and comment-only lines
            if not stripped or stripped.startswith(";"):
                # But if inside a function, a blank line between blocks is OK
                continue

            # ---- Module header ----
            m = _RE_MODULE_ID.match(stripped)
            if m:
                module.source_file = m.group(1)
                continue

            m = _RE_SOURCE_FILE.match(stripped)
            if m and not module.source_file:
                module.source_file = m.group(1)
                continue

            m = _RE_TARGET_TRIP.match(stripped)
            if m:
                module.target_triple = m.group(1)
                continue

            # ---- Global variable ----
            if _RE_GLOBAL.match(stripped) and not inside_fn:
                module.globals.append(stripped)
                continue

            # ---- Function declaration (no body) ----
            if stripped.startswith("declare "):
                m = _RE_DECLARE.match(stripped)
                if m:
                    fn = Function(
                        name=m.group(1),
                        return_type=self._extract_rettype(stripped),
                        is_declaration=True,
                    )
                    module.functions[fn.name] = fn
                    module.declarations[fn.name] = fn
                continue

            # ---- Function definition — opening ----
            if stripped.startswith("define "):
                m = _RE_DEFINE.match(stripped)
                if m:
                    fn_name = m.group(1)
                    params_raw = m.group(2)
                    current_fn = Function(
                        name=fn_name,
                        return_type=self._extract_rettype(stripped),
                        params=self._parse_params(params_raw),
                    )
                    # Attach source line from DISubprogram metadata
                    current_fn.source_line = module.metadata.get(
                        f"subprog:{fn_name}", {}).get("line")
                    current_fn.source_file = module.source_file
                    module.functions[fn_name] = current_fn

                    # Entry block is implicit — starts immediately after '{'
                    current_bb = BasicBlock(name="entry")
                    current_fn.basic_blocks.append(current_bb)
                    inside_fn = True
                continue

            # ---- Function closing brace ----
            if stripped == "}" and inside_fn:
                # Finalise the last block
                if current_bb and current_bb.instructions:
                    current_bb.terminator = self._find_terminator(current_bb)
                inside_fn = False
                current_fn = None
                current_bb = None
                continue

            # ---- Inside a function body ----
            if inside_fn and current_fn is not None:

                # Basic block label?
                bb_match = _RE_BB_LABEL.match(stripped)
                # Guard: must not look like an instruction result (%foo = ...)
                if bb_match and not stripped.startswith("%") and not stripped.startswith("@"):
                    bb_name = bb_match.group(1)
                    # Skip keywords that aren't block labels
                    if bb_name in {"define", "declare", "attributes", "target",
                                   "source", "ret", "br", "call", "store",
                                   "load", "alloca", "unreachable"}:
                        continue

                    # Finalise previous block (only if it has instructions)
                    if current_bb and current_bb.instructions:
                        current_bb.terminator = self._find_terminator(current_bb)

                    # If the current (empty) block has the same name, reuse it
                    # instead of creating a duplicate.  This handles the LLVM
                    # convention of writing "entry:" explicitly even though the
                    # entry block is implicit at the top of the function.
                    if (current_bb is not None
                            and not current_bb.instructions
                            and current_bb.name == bb_name):
                        # Just update predecessors if present
                        preds_m = _RE_PREDS.search(raw)
                        if preds_m:
                            current_bb.predecessors = [
                                p.strip().lstrip("%")
                                for p in preds_m.group(1).split(",")
                            ]
                        continue

                    current_bb = BasicBlock(name=bb_name)
                    # Parse predecessors from comment
                    preds_m = _RE_PREDS.search(raw)
                    if preds_m:
                        current_bb.predecessors = [
                            p.strip().lstrip("%")
                            for p in preds_m.group(1).split(",")
                        ]
                    current_fn.basic_blocks.append(current_bb)
                    continue

                # Parse as an instruction
                if current_bb is not None:
                    instr = self._parse_instruction(stripped, module.metadata)
                    if instr is not None:
                        current_bb.instructions.append(instr)

            # ---- attributes / metadata lines — skip ----
            # (already collected in pass 1)

        # ---- Pass 3: attach source lines from DISubprogram ----
        self._attach_source_lines(module)

        return module

    # ------------------------------------------------------------------
    # Metadata collection (pass 1)
    # ------------------------------------------------------------------

    def _collect_metadata(self, lines: list[str], module: IRModule) -> None:
        """
        Scan all !N = ... lines, store raw text and parse key nodes:
        - !DILocation → stored in module.metadata[N] as DebugLoc
        - distinct !DISubprogram → stored as module.metadata["subprog:<name>"]
        """
        for line in lines:
            stripped = line.strip()
            m = _RE_META_DEF.match(stripped)
            if not m:
                continue
            idx = int(m.group(2))
            body = m.group(3)
            module.metadata[idx] = body

            # DISubprogram → function source line
            sp_m = _RE_SUBPROG.search(body)
            if sp_m:
                fn_name = sp_m.group(1)
                src_line = int(sp_m.group(2))
                module.metadata[f"subprog:{fn_name}"] = {"line": src_line}

    # ------------------------------------------------------------------
    # Instruction parsing
    # ------------------------------------------------------------------

    def _parse_instruction(
        self,
        stripped: str,
        metadata: dict,
    ) -> Optional[Instruction]:
        """Parse one stripped instruction line into an Instruction object."""

        # Skip pure comment lines
        if stripped.startswith(";"):
            return None

        instr = Instruction(raw=stripped, opcode="unknown")

        # Debug location annotation
        dbg_m = _RE_DBGLOC.search(stripped)
        if dbg_m:
            meta_idx = int(dbg_m.group(2))
            meta_body = metadata.get(meta_idx, "")
            loc_m = _RE_META_LINE.search(meta_body)
            if loc_m:
                instr.debug_loc = DebugLoc(
                    line=int(loc_m.group(1)),
                    column=int(loc_m.group(2)),
                    scope_id=int(loc_m.group(4)),
                )

        # Strip the !dbg annotation for cleaner opcode parsing
        clean = re.sub(r',?\s*!dbg\s+!\d+', '', stripped).strip()

        # LHS result register?
        res_m = _RE_RESULT.match(clean)
        if res_m:
            instr.result = res_m.group(1)
            rhs = res_m.group(2).strip()
        else:
            rhs = clean

        # Extract opcode — first word of RHS
        op_m = _RE_OPCODE.match(rhs)
        if op_m:
            instr.opcode = op_m.group(1)

        # ---- Branch ----
        if instr.opcode == "br":
            instr.is_branch = True
            instr.is_terminator = True
            cond_m = _RE_BR_COND.match(rhs)
            if cond_m:
                instr.is_conditional_branch = True
                instr.branch_condition = cond_m.group(1)
                instr.branch_targets = [
                    cond_m.group(2).lstrip("%"),
                    cond_m.group(3).lstrip("%"),
                ]
            else:
                uncond_m = _RE_BR_UNCOND.match(rhs)
                if uncond_m:
                    instr.branch_targets = [uncond_m.group(1).lstrip("%")]

        # ---- Return ----
        elif instr.opcode == "ret":
            instr.is_return = True
            instr.is_terminator = True
            ret_m = _RE_RET.match(rhs)
            if ret_m:
                ret_type = ret_m.group(1)
                ret_val = ret_m.group(2)
                if ret_type == "void":
                    instr.return_value = "void"
                    instr.return_is_constant = True
                elif ret_val is not None:
                    val = ret_val.strip().split(",")[0].strip()
                    instr.return_value = val
                    # Constant if it's a number or "null", "true", "false"
                    instr.return_is_constant = bool(
                        re.match(r'^-?\d+$', val) or
                        val in {"null", "true", "false", "undef", "poison"}
                    )

        # ---- Switch ----
        elif instr.opcode == "switch":
            instr.is_terminator = True
            instr.is_branch = True
            # Extract all label targets
            instr.branch_targets = re.findall(r'label\s+(%[\w.$]+)', rhs)
            instr.branch_targets = [t.lstrip("%") for t in instr.branch_targets]

        # ---- Unreachable ----
        elif instr.opcode == "unreachable":
            instr.is_terminator = True

        # ---- Compare ----
        elif instr.opcode in {"icmp", "fcmp"}:
            instr.is_cmp = True
            # Capture predicate and operands
            parts = rhs.split()
            if len(parts) >= 2:
                instr.operands = parts[1:]

        # ---- Memory ops ----
        elif instr.opcode in {"load", "store", "alloca"}:
            instr.is_memory = True

        # ---- Call ----
        elif instr.opcode in {"call", "invoke", "tail"}:
            instr.is_call = True

        return instr

    @staticmethod
    def _find_terminator(bb: BasicBlock) -> Optional[Instruction]:
        """Return the last terminator instruction in a block."""
        for instr in reversed(bb.instructions):
            if instr.is_terminator:
                return instr
        return None

    # ------------------------------------------------------------------
    # Helper: extract return type from a define/declare line
    # ------------------------------------------------------------------

    @staticmethod
    def _extract_rettype(line: str) -> str:
        """
        Pull the return type from a define/declare line.
        e.g. "define dso_local i32 @foo(...)" → "i32"
        """
        # Strip leading keyword and linkage/visibility tokens
        keywords = {
            "define", "declare", "dso_local", "dso_preemptable",
            "internal", "external", "private", "linkonce", "weak",
            "available_externally", "appending", "common", "extern_weak",
            "linkonce_odr", "weak_odr", "local_unnamed_addr", "unnamed_addr",
            "noundef",
        }
        parts = line.split()
        for part in parts:
            stripped_part = part.strip("*")
            if stripped_part not in keywords and not stripped_part.startswith("@"):
                return part   # first non-keyword token is the return type
        return "?"

    @staticmethod
    def _parse_params(params_raw: str) -> list[str]:
        """
        Split parameter list string into individual param strings.
        Handles nested < > and [ ] by counting depth.
        """
        params = []
        depth = 0
        current: list[str] = []
        for ch in params_raw:
            if ch in "<([{":
                depth += 1
                current.append(ch)
            elif ch in ">)]}":
                depth -= 1
                current.append(ch)
            elif ch == "," and depth == 0:
                p = "".join(current).strip()
                if p:
                    params.append(p)
                current = []
            else:
                current.append(ch)
        last = "".join(current).strip()
        if last:
            params.append(last)
        return params

    # ------------------------------------------------------------------
    # Pass 3: attach source lines from collected DISubprogram metadata
    # ------------------------------------------------------------------

    @staticmethod
    def _attach_source_lines(module: IRModule) -> None:
        for name, fn in module.functions.items():
            key = f"subprog:{name}"
            info = module.metadata.get(key)
            if isinstance(info, dict):
                fn.source_line = info.get("line")


# ---------------------------------------------------------------------------
# Convenience helpers used by diff_engine
# ---------------------------------------------------------------------------

def load_both(O0_path: str | Path, O2_path: str | Path) -> tuple[IRModule, IRModule]:
    """Parse both IR levels and return (O0_module, O2_module)."""
    return IRParser.parse_file(O0_path), IRParser.parse_file(O2_path)


def function_names_in_common(
    m0: IRModule,
    m2: IRModule,
    skip_intrinsics: bool = True,
) -> list[str]:
    """
    Return names of functions defined in both modules.
    Optionally skips LLVM intrinsics (names starting with 'llvm.').
    """
    s0 = set(m0.defined_functions)
    s2 = set(m2.defined_functions)
    common = s0 & s2
    if skip_intrinsics:
        common = {n for n in common if not n.startswith("llvm.")}
    return sorted(common)


# ---------------------------------------------------------------------------
# CLI entry point (python -m engine.ir_parser <file.ll>)
# ---------------------------------------------------------------------------

def main(argv=None) -> int:
    import argparse, sys

    ap = argparse.ArgumentParser(
        prog="engine.ir_parser",
        description="Parse a .ll file and print a structural summary.",
    )
    ap.add_argument("ll_file", help="Path to .ll IR file")
    ap.add_argument("--blocks", action="store_true",
                    help="Print basic block details per function")
    ap.add_argument("--instrs", action="store_true",
                    help="Print all instructions per block")
    args = ap.parse_args(argv)

    try:
        module = IRParser.parse_file(args.ll_file)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(module.summary())
    print(f"  Target : {module.target_triple}")
    print(f"  Globals: {len(module.globals)}")
    print()

    for fn in module.defined_functions.values():
        src = f" (source line {fn.source_line})" if fn.source_line else ""
        print(f"  {fn.summary()}{src}")
        if args.blocks:
            for bb in fn.basic_blocks:
                preds = f"  preds={bb.predecessors}" if bb.predecessors else ""
                term = str(bb.terminator) if bb.terminator else "—"
                print(f"    [{bb.name}]{preds}  ({bb.num_instructions} instrs)")
                print(f"      terminator: {term}")
                if args.instrs:
                    for instr in bb.instructions:
                        loc = f"  @{instr.debug_loc}" if instr.debug_loc else ""
                        print(f"        {instr.raw}{loc}")
        print()

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
