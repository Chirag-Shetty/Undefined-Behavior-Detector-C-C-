"""
report/reporter.py — Source-Level Report Generator (Deliverable 4)

Produces:
  1. Text report: "line N: this works at -O0 but breaks at -O2 because [UB type]"
  2. HTML report: dark-themed, colour-coded, with IR diff snippets

Usage:
    from report.reporter import Reporter
    reporter = Reporter()
    reporter.write_text(cresult, diff_report, source_path, out_dir)
    reporter.write_html(cresult, diff_report, source_path, out_dir)
"""

from __future__ import annotations

import html as _html
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from analysis.diff_engine import DiffReport, Finding, ChangeKind, Severity
from analysis.ub_classifier import ClassificationReport, UBCategory, UBClassification


# ── severity colours ──────────────────────────────────────────────────────────
_SEV_COLOUR = {Severity.HIGH: "\033[91m", Severity.MEDIUM: "\033[93m", Severity.LOW: "\033[96m"}
_RESET = "\033[0m"
_BOLD  = "\033[1m"

_HTML_SEV_CLASS = {Severity.HIGH: "high", Severity.MEDIUM: "medium", Severity.LOW: "low"}
_HTML_CAT_ICON  = {
    UBCategory.SIGNED_OVERFLOW: "⚡",
    UBCategory.STRICT_ALIASING: "🔀",
    UBCategory.NULL_DEREF:      "💥",
    UBCategory.UNINIT_VAR:      "❓",
    UBCategory.UNKNOWN:         "⚠️",
}
_HTML_CAT_COLOR = {
    UBCategory.SIGNED_OVERFLOW: "#f97316",
    UBCategory.STRICT_ALIASING: "#a855f7",
    UBCategory.NULL_DEREF:      "#ef4444",
    UBCategory.UNINIT_VAR:      "#eab308",
    UBCategory.UNKNOWN:         "#6b7280",
}


# ─────────────────────────────────────────────────────────────────────────────
# Text reporter
# ─────────────────────────────────────────────────────────────────────────────

class Reporter:

    # ── public API ────────────────────────────────────────────────────────────

    def generate_text(
        self,
        cresult: ClassificationReport,
        diff: DiffReport,
        source_path: Optional[Path] = None,
        colour: bool = True,
    ) -> str:
        lines: list[str] = []
        W = 70

        def sep(ch="─"): lines.append(ch * W)
        def hdr(t): lines.append(f"{_BOLD if colour else ''}{'═'*W}{_RESET if colour else ''}")
        def h(t):   lines.append(f"{_BOLD if colour else ''}{t}{_RESET if colour else ''}")

        hdr("═")
        h(f"  UB Time Bomb Report")
        src = source_path or Path(diff.source_file)
        h(f"  Source : {src}")
        h(f"  O0 IR  : {diff.ir_O0_path.name}")
        h(f"  O2 IR  : {diff.ir_O2_path.name}")
        lines.append("═" * W)
        lines.append("")

        if not cresult.classifications:
            lines.append("  ✓ No undefined-behaviour time bombs detected.")
            lines.append("")
            return "\n".join(lines)

        # Source lines we can read
        src_lines: list[str] = []
        if source_path and source_path.exists():
            src_lines = source_path.read_text(errors="replace").splitlines()

        for cl in cresult.classifications:
            sev = _max_severity(cl.findings)
            sc  = _SEV_COLOUR.get(sev, "") if colour else ""
            rc  = _RESET if colour else ""
            sep()
            lines.append(f"{sc}[{sev.value}]{rc}  @{cl.function_name}  —  {cl.label}")
            if cl.source_line:
                lines.append(f"  line {cl.source_line}: this works at -O0 but breaks at -O2")
                lines.append(f"         because of {cl.category.value.replace('_',' ').upper()}")
                # Show the actual source line
                if src_lines and 0 < cl.source_line <= len(src_lines):
                    lines.append(f"  ┌─ source:")
                    start = max(0, cl.source_line - 1)
                    end   = min(len(src_lines), cl.source_line + 3)
                    for i, sl in enumerate(src_lines[start:end], start + 1):
                        marker = "►" if i == cl.source_line else " "
                        lines.append(f"  │ {marker} {i:4d} │ {sl}")
                    lines.append("  └─")
            lines.append("")
            lines.append(f"  Explanation:")
            for ln in _wrap(cl.explanation, 66):
                lines.append(f"    {ln}")
            lines.append("")
            lines.append(f"  Evidence:")
            for ev in cl.evidence:
                lines.append(f"    • {ev}")
            lines.append("")
            lines.append(f"  IR Changes:")
            for f in cl.findings:
                lines.append(f"    [{f.change_kind.value}]")
                lines.append(f"      {f.description}")
                if f.ir_O0_snippet:
                    lines.append(f"      O0: {f.ir_O0_snippet.strip()[:120]}")
                if f.ir_O2_snippet:
                    lines.append(f"      O2: {f.ir_O2_snippet.strip()[:120]}")
            lines.append("")

        sep("═")
        hi  = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.HIGH)
        med = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.MEDIUM)
        lo  = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.LOW)
        lines.append(f"  SUMMARY: {len(cresult.classifications)} function(s) affected")
        lines.append(f"    HIGH={hi}  MEDIUM={med}  LOW={lo}")
        cats: dict[str, int] = {}
        for c in cresult.classifications:
            cats[c.label] = cats.get(c.label, 0) + 1
        for cat, n in cats.items():
            lines.append(f"    {n}× {cat}")
        lines.append("═" * W)
        return "\n".join(lines)

    def write_text(
        self,
        cresult: ClassificationReport,
        diff: DiffReport,
        source_path: Optional[Path] = None,
        out_dir: Optional[Path] = None,
    ) -> Path:
        text = self.generate_text(cresult, diff, source_path, colour=False)
        out  = _resolve_out(out_dir, diff, ".txt")
        out.write_text(text)
        return out

    def generate_html(
        self,
        cresult: ClassificationReport,
        diff: DiffReport,
        source_path: Optional[Path] = None,
    ) -> str:
        src = source_path or Path(diff.source_file)
        src_lines: list[str] = []
        if source_path and source_path.exists():
            src_lines = source_path.read_text(errors="replace").splitlines()

        findings_html = ""
        for cl in cresult.classifications:
            sev   = _max_severity(cl.findings)
            sc    = _HTML_SEV_CLASS.get(sev, "low")
            icon  = _HTML_CAT_ICON.get(cl.category, "⚠️")
            color = _HTML_CAT_COLOR.get(cl.category, "#6b7280")

            # source context block
            src_block = ""
            if cl.source_line and src_lines and 0 < cl.source_line <= len(src_lines):
                start = max(0, cl.source_line - 2)
                end   = min(len(src_lines), cl.source_line + 4)
                rows  = ""
                for i, sl in enumerate(src_lines[start:end], start + 1):
                    hi = ' class="highlight"' if i == cl.source_line else ""
                    rows += f'<tr{hi}><td class="ln">{i}</td><td class="code">{_h(sl)}</td></tr>\n'
                src_block = f'<table class="src-table">{rows}</table>'

            # IR snippets
            ir_cards = ""
            for f in cl.findings:
                o0s = _h(f.ir_O0_snippet or "(none)")
                o2s = _h(f.ir_O2_snippet or "(none)")
                ir_cards += f"""
<div class="ir-card">
  <div class="ir-label">{_h(f.change_kind.value)}</div>
  <p class="ir-desc">{_h(f.description)}</p>
  <div class="ir-cols">
    <div class="ir-col">
      <div class="ir-badge o0">-O0</div>
      <pre>{o0s}</pre>
    </div>
    <div class="ir-col">
      <div class="ir-badge o2">-O2</div>
      <pre>{o2s}</pre>
    </div>
  </div>
</div>"""

            ev_items = "".join(f"<li>{_h(e)}</li>" for e in cl.evidence)
            loc_txt  = f"<span class='loc'>line {cl.source_line}</span>" if cl.source_line else ""

            findings_html += f"""
<article class="finding {sc}">
  <div class="finding-header">
    <span class="sev-badge {sc}">{sev.value}</span>
    <span class="fn-name">@{_h(cl.function_name)}</span>
    {loc_txt}
    <span class="cat-badge" style="background:{color}20;color:{color};border-color:{color}40">
      {icon} {_h(cl.label)}
    </span>
  </div>

  <p class="expl">{_h(cl.explanation)}</p>

  <details open>
    <summary>Source context</summary>
    {src_block if src_block else "<p><em>Source file not available</em></p>"}
  </details>

  <details open>
    <summary>Evidence ({len(cl.evidence)} signal(s))</summary>
    <ul class="ev-list">{ev_items}</ul>
  </details>

  <details>
    <summary>IR diff ({len(cl.findings)} change(s))</summary>
    {ir_cards}
  </details>
</article>"""

        # stats bar
        hi  = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.HIGH)
        med = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.MEDIUM)
        lo  = sum(1 for c in cresult.classifications if _max_severity(c.findings) == Severity.LOW)
        total = len(cresult.classifications)

        cats_html = ""
        cats: dict[str, tuple[int, str, str]] = {}
        for c in cresult.classifications:
            icon2  = _HTML_CAT_ICON.get(c.category, "⚠️")
            color2 = _HTML_CAT_COLOR.get(c.category, "#6b7280")
            cats[c.label] = (cats.get(c.label, (0,"",""))[0] + 1, icon2, color2)
        for label, (n, icon2, color2) in cats.items():
            cats_html += f'<div class="stat-pill" style="border-color:{color2};color:{color2}">{icon2} {_h(label)} ×{n}</div>'

        no_findings = '<div class="no-findings">✓ No undefined-behaviour time bombs detected.</div>' \
            if not cresult.classifications else ""

        return _HTML_TEMPLATE.format(
            source=_h(str(src)),
            o0_ir=_h(str(diff.ir_O0_path)),
            o2_ir=_h(str(diff.ir_O2_path)),
            total=total,
            high=hi,
            medium=med,
            low=lo,
            cats_html=cats_html,
            findings_html=findings_html or no_findings,
        )

    def write_html(
        self,
        cresult: ClassificationReport,
        diff: DiffReport,
        source_path: Optional[Path] = None,
        out_dir: Optional[Path] = None,
    ) -> Path:
        html = self.generate_html(cresult, diff, source_path)
        out  = _resolve_out(out_dir, diff, ".html")
        out.write_text(html)
        return out


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _h(s: str) -> str:
    return _html.escape(str(s))

def _wrap(text: str, width: int) -> list[str]:
    words = text.split()
    lines, cur = [], []
    for w in words:
        if sum(len(x)+1 for x in cur) + len(w) > width:
            lines.append(" ".join(cur)); cur = []
        cur.append(w)
    if cur: lines.append(" ".join(cur))
    return lines

def _max_severity(findings: list[Finding]) -> Severity:
    order = [Severity.HIGH, Severity.MEDIUM, Severity.LOW]
    for s in order:
        if any(f.severity == s for f in findings):
            return s
    return Severity.LOW

def _resolve_out(out_dir: Optional[Path], diff: DiffReport, ext: str) -> Path:
    if out_dir is None:
        base = Path(__file__).resolve().parent.parent / "output"
        stem = Path(diff.source_file).stem
        out_dir = base / stem
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = Path(diff.source_file).stem
    return out_dir / f"report_{stem}{ext}"


# ─────────────────────────────────────────────────────────────────────────────
# HTML template
# ─────────────────────────────────────────────────────────────────────────────

_HTML_TEMPLATE = """\
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>UB Time Bomb Report</title>
<style>
:root{{
  --bg:#0f1117;--bg2:#1a1d27;--bg3:#252836;--border:#2e3149;
  --text:#e2e8f0;--muted:#94a3b8;--accent:#6366f1;
  --high:#ef4444;--medium:#f97316;--low:#3b82f6;
  --code-bg:#0d1117;--code-text:#e2e8f0;
}}
*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:'Inter',system-ui,sans-serif;background:var(--bg);color:var(--text);
      line-height:1.6;padding:0 0 4rem}}
a{{color:var(--accent)}}

/* ── header ── */
.hero{{background:linear-gradient(135deg,#1e1b4b 0%,#0f1117 60%);
       border-bottom:1px solid var(--border);padding:2.5rem 3rem 2rem}}
.hero h1{{font-size:1.8rem;font-weight:700;letter-spacing:-.5px;
          background:linear-gradient(90deg,#818cf8,#c084fc);
          -webkit-background-clip:text;-webkit-text-fill-color:transparent}}
.hero p{{color:var(--muted);font-size:.9rem;margin-top:.3rem}}
.meta-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));
            gap:.5rem;margin-top:1rem}}
.meta-item{{background:#ffffff08;border:1px solid var(--border);border-radius:8px;
            padding:.5rem .8rem;font-size:.82rem}}
.meta-item span{{color:var(--muted);margin-right:.5rem}}

/* ── stats bar ── */
.stats{{display:flex;align-items:center;gap:1rem;flex-wrap:wrap;
        padding:1.2rem 3rem;background:var(--bg2);border-bottom:1px solid var(--border)}}
.stat-box{{display:flex;flex-direction:column;align-items:center;
           min-width:60px;padding:.4rem .8rem;border-radius:8px;
           border:1px solid var(--border)}}
.stat-box .num{{font-size:1.6rem;font-weight:800;line-height:1}}
.stat-box .lbl{{font-size:.7rem;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}}
.stat-box.high{{border-color:#ef444440;background:#ef444410}}
.stat-box.high .num{{color:var(--high)}}
.stat-box.medium{{border-color:#f9731640;background:#f9731610}}
.stat-box.medium .num{{color:var(--medium)}}
.stat-box.low{{border-color:#3b82f640;background:#3b82f610}}
.stat-box.low .num{{color:var(--low)}}
.stat-pill{{padding:.25rem .75rem;border-radius:99px;font-size:.8rem;
            border:1px solid;font-weight:500}}

/* ── content ── */
.content{{padding:2rem 3rem;max-width:1200px}}

/* ── finding card ── */
.finding{{background:var(--bg2);border:1px solid var(--border);border-radius:12px;
          margin-bottom:1.5rem;overflow:hidden;transition:box-shadow .2s}}
.finding:hover{{box-shadow:0 4px 24px #0006}}
.finding.high  {{border-left:4px solid var(--high)}}
.finding.medium{{border-left:4px solid var(--medium)}}
.finding.low   {{border-left:4px solid var(--low)}}

.finding-header{{display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;
                 padding:1rem 1.25rem;border-bottom:1px solid var(--border)}}
.sev-badge{{padding:.2rem .6rem;border-radius:6px;font-size:.75rem;
            font-weight:700;letter-spacing:.5px}}
.sev-badge.high  {{background:#ef444420;color:var(--high)}}
.sev-badge.medium{{background:#f9731620;color:var(--medium)}}
.sev-badge.low   {{background:#3b82f620;color:var(--low)}}
.fn-name{{font-family:'JetBrains Mono',monospace;font-size:1rem;font-weight:600}}
.loc{{color:var(--muted);font-size:.85rem}}
.cat-badge{{padding:.25rem .7rem;border-radius:99px;font-size:.8rem;
            font-weight:500;border:1px solid;margin-left:auto}}

.expl{{padding:1rem 1.25rem;color:var(--muted);font-size:.9rem;
       border-bottom:1px solid var(--border)}}

details{{border-bottom:1px solid var(--border)}}
details:last-child{{border-bottom:none}}
summary{{padding:.8rem 1.25rem;cursor:pointer;font-weight:600;font-size:.9rem;
         color:var(--accent);user-select:none;list-style:none}}
summary::-webkit-details-marker{{display:none}}
summary::before{{content:'▶ ';font-size:.7rem;margin-right:.4rem;
                 transition:transform .2s}}
details[open] summary::before{{content:'▼ ';}}

/* ── source table ── */
.src-table{{width:100%;border-collapse:collapse;font-family:'JetBrains Mono',monospace;
            font-size:.82rem;margin:0 1.25rem 1rem;width:calc(100% - 2.5rem)}}
.src-table td{{padding:.15rem .5rem;white-space:pre}}
.src-table .ln{{color:var(--muted);text-align:right;padding-right:1rem;
                user-select:none;min-width:3rem}}
.src-table tr.highlight{{background:#6366f115}}
.src-table tr.highlight .code{{color:#a5b4fc;font-weight:600}}

/* ── evidence list ── */
.ev-list{{padding:.5rem 1.25rem 1rem 2.5rem;font-size:.88rem;color:var(--muted)}}
.ev-list li{{margin:.3rem 0}}

/* ── IR cards ── */
.ir-card{{margin:0 1.25rem 1rem;border:1px solid var(--border);
          border-radius:8px;overflow:hidden}}
.ir-label{{padding:.4rem .8rem;background:#ffffff08;font-family:'JetBrains Mono',monospace;
           font-size:.78rem;color:var(--accent);font-weight:600;border-bottom:1px solid var(--border)}}
.ir-desc{{padding:.5rem .8rem;font-size:.85rem;color:var(--muted)}}
.ir-cols{{display:grid;grid-template-columns:1fr 1fr;border-top:1px solid var(--border)}}
.ir-col{{padding:.5rem .8rem}}
.ir-col:first-child{{border-right:1px solid var(--border)}}
.ir-badge{{display:inline-block;padding:.1rem .5rem;border-radius:4px;
           font-size:.72rem;font-weight:700;margin-bottom:.4rem}}
.ir-badge.o0{{background:#22c55e20;color:#22c55e}}
.ir-badge.o2{{background:#ef444420;color:#ef4444}}
.ir-col pre{{font-family:'JetBrains Mono',monospace;font-size:.78rem;
             color:var(--code-text);white-space:pre-wrap;word-break:break-all}}

.no-findings{{background:#16a34a15;border:1px solid #16a34a40;border-radius:12px;
              padding:2rem;text-align:center;color:#4ade80;font-size:1.1rem}}
</style>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
</head>
<body>

<div class="hero">
  <h1>⚡ UB Time Bomb Report</h1>
  <p>Undefined behaviour patterns that work at -O0 but silently break at -O2</p>
  <div class="meta-grid">
    <div class="meta-item"><span>Source</span>{source}</div>
    <div class="meta-item"><span>-O0 IR</span>{o0_ir}</div>
    <div class="meta-item"><span>-O2 IR</span>{o2_ir}</div>
  </div>
</div>

<div class="stats">
  <div class="stat-box high">  <div class="num">{high}</div>  <div class="lbl">High</div>  </div>
  <div class="stat-box medium"><div class="num">{medium}</div><div class="lbl">Medium</div></div>
  <div class="stat-box low">  <div class="num">{low}</div>  <div class="lbl">Low</div>  </div>
  <div class="stat-box">      <div class="num">{total}</div> <div class="lbl">Total</div></div>
  {cats_html}
</div>

<div class="content">
{findings_html}
</div>

</body>
</html>
"""


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def main(argv=None) -> int:
    import argparse, sys
    from engine.compiler import DifferentialCompiler
    from engine.ir_parser import load_both
    from analysis.diff_engine import DiffEngine
    from analysis.ub_classifier import UBClassifier

    ap = argparse.ArgumentParser(prog="report.reporter",
                                 description="Generate UB report from a C/C++ file.")
    ap.add_argument("source",          help="C/C++ source file")
    ap.add_argument("--html",          action="store_true", help="Also write HTML report")
    ap.add_argument("--out-dir", "-o", default=None, help="Output directory")
    ap.add_argument("--no-colour",     action="store_true", help="Disable ANSI colour")
    args = ap.parse_args(argv)

    src = Path(args.source)
    out = Path(args.out_dir) if args.out_dir else None

    # 1. Compile
    compiler = DifferentialCompiler()
    cresult_compile = compiler.compile(src, out)
    if not cresult_compile.success:
        print(cresult_compile.error, file=sys.stderr)
        return 1

    # 2. Parse IR
    m0, m2 = load_both(cresult_compile.ir_O0_path, cresult_compile.ir_O2_path)

    # 3. Diff
    diff = DiffEngine().diff(m0, m2)

    # 4. Classify
    classification = UBClassifier().classify(diff, m0, m2)

    # 5. Report (text)
    reporter = Reporter()
    text = reporter.generate_text(classification, diff, src, colour=not args.no_colour)
    print(text)

    txt_path = reporter.write_text(classification, diff, src, out)
    print(f"\n  Text report → {txt_path}")

    if args.html:
        html_path = reporter.write_html(classification, diff, src, out)
        print(f"  HTML report → {html_path}")

    return 0 if not classification.classifications else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
