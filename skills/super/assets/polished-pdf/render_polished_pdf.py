#!/usr/bin/env python3
"""Render a /super polished PDF.

Pipeline:
1. Render page 1 (cover) WITHOUT running header/footer (full-bleed teal)
2. Render pages 2+ WITH running header/footer and proper margins
3. Merge the two into the final PDF

Usage:
    python3 render_polished_pdf.py <input.html> <output.pdf>

Header/footer text can be overridden via env vars:
    SUPER_PDF_HEADER_LEFT   — default "RESEARCH DRAFT"
    SUPER_PDF_HEADER_RIGHT  — default derived from <title>
    SUPER_PDF_FOOTER_LEFT   — default current month (e.g. "May 2026")

Requirements:
    pip install playwright pypdf
    python3 -m playwright install chromium

Fallback (no Playwright chromium installed): writes the PDF directly with
Chrome headless (no running header/footer). Looks fine on the cover but
missing the running header on body pages.
"""
from __future__ import annotations
import os
import sys
import subprocess
import datetime
import re
import tempfile
from pathlib import Path


# --------------------------------------------------------------------------
# Templates
# --------------------------------------------------------------------------

def _header_template(left: str, right: str) -> str:
    return f"""
<div style="font-size: 8pt; width: 100%; box-sizing: border-box;
            padding: 6px 0.85in 4px 0.85in;
            color: #6b7c85; font-family: 'Helvetica Neue', Arial, sans-serif;">
  <table style="width: 100%; border-collapse: collapse;
                border-bottom: 0.5px solid #d0d8dc; padding-bottom: 6px;">
    <tr>
      <td style="font-size: 7.5pt; letter-spacing: 0.14em; text-transform: uppercase;
                 font-weight: 700; color: #6b7c85; padding-bottom: 5px;">{left}</td>
      <td style="text-align: right; font-size: 8.5pt; color: #2c3e50; padding-bottom: 5px;">
          {right}</td>
    </tr>
  </table>
</div>
"""


def _footer_template(left: str) -> str:
    return f"""
<div style="font-size: 8pt; width: 100%; box-sizing: border-box;
            padding: 4px 0.85in 6px 0.85in;
            color: #6b7c85; font-family: 'Helvetica Neue', Arial, sans-serif;">
  <table style="width: 100%; border-collapse: collapse;
                border-top: 0.5px solid #d0d8dc; padding-top: 6px;">
    <tr>
      <td style="padding-top: 5px; font-size: 8pt;">{left}</td>
      <td style="padding-top: 5px; text-align: right; font-size: 8pt;">
          Page <span class="pageNumber"></span></td>
    </tr>
  </table>
</div>
"""


# --------------------------------------------------------------------------
# Header/footer text derivation
# --------------------------------------------------------------------------

def _derive_title(html_path: Path) -> str:
    try:
        text = html_path.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r"<title>(.*?)</title>", text, re.IGNORECASE | re.DOTALL)
        return re.sub(r"\s+", " ", m.group(1)).strip() if m else "Research Report"
    except Exception:
        return "Research Report"


def _default_footer_date() -> str:
    return datetime.datetime.now().strftime("%B %Y")


# --------------------------------------------------------------------------
# Playwright renderer (preferred path)
# --------------------------------------------------------------------------

def render_with_playwright(html: Path, out: Path,
                           header_left: str, header_right: str,
                           footer_left: str) -> bool:
    try:
        from playwright.sync_api import sync_playwright
        from pypdf import PdfWriter, PdfReader
    except ImportError as e:
        print(f"[polished-pdf] Missing dependency: {e}", file=sys.stderr)
        return False

    tmp = Path(tempfile.mkdtemp(prefix="superpdf-"))
    cover_pdf = tmp / "cover.pdf"
    body_pdf = tmp / "body.pdf"

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            ctx = browser.new_context()
            page = ctx.new_page()
            page.goto(f"file://{html.resolve()}", wait_until="networkidle")

            # Cover: no header/footer, full bleed
            page.pdf(
                path=str(cover_pdf),
                format="Letter",
                print_background=True,
                display_header_footer=False,
                margin={"top": "0in", "bottom": "0in",
                        "left": "0in", "right": "0in"},
                page_ranges="1",
            )

            # Body: running header/footer in margin area
            page.pdf(
                path=str(body_pdf),
                format="Letter",
                print_background=True,
                display_header_footer=True,
                header_template=_header_template(header_left, header_right),
                footer_template=_footer_template(footer_left),
                margin={"top": "1.0in", "bottom": "0.85in",
                        "left": "0in", "right": "0in"},
                page_ranges="2-",
            )
            browser.close()
    except Exception as e:
        msg = str(e)
        if "Executable doesn't exist" in msg or "playwright install" in msg:
            print("[polished-pdf] Playwright chromium not installed. "
                  "Run: python3 -m playwright install chromium",
                  file=sys.stderr)
        else:
            print(f"[polished-pdf] Playwright error: {e}", file=sys.stderr)
        return False

    # Merge
    writer = PdfWriter()
    for src in [cover_pdf, body_pdf]:
        for pg in PdfReader(str(src)).pages:
            writer.add_page(pg)
    with open(out, "wb") as f:
        writer.write(f)
    return True


# --------------------------------------------------------------------------
# Chrome direct fallback (no running header/footer)
# --------------------------------------------------------------------------

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
]


def _find_chrome() -> str | None:
    for c in CHROME_CANDIDATES:
        if Path(c).exists():
            return c
    return None


def render_with_chrome(html: Path, out: Path) -> bool:
    chrome = _find_chrome()
    if not chrome:
        print("[polished-pdf] No Chrome/Chromium found.", file=sys.stderr)
        return False
    cmd = [
        chrome, "--headless=new", "--disable-gpu",
        "--no-pdf-header-footer", f"--print-to-pdf={out}",
        f"file://{html.resolve()}",
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"[polished-pdf] Chrome failed: {r.stderr}", file=sys.stderr)
        return False
    return True


# --------------------------------------------------------------------------
# Entry
# --------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__)
        return 2
    html = Path(argv[1])
    out = Path(argv[2])
    if not html.exists():
        print(f"[polished-pdf] Input not found: {html}", file=sys.stderr)
        return 2
    out.parent.mkdir(parents=True, exist_ok=True)

    header_left = os.environ.get("SUPER_PDF_HEADER_LEFT", "RESEARCH DRAFT")
    header_right = os.environ.get("SUPER_PDF_HEADER_RIGHT") or _derive_title(html)
    footer_left = os.environ.get("SUPER_PDF_FOOTER_LEFT", _default_footer_date())

    if render_with_playwright(html, out, header_left, header_right, footer_left):
        print(f"[polished-pdf] Wrote {out} ({out.stat().st_size:,} bytes)")
        return 0

    print("[polished-pdf] Falling back to Chrome direct (no running header/footer).",
          file=sys.stderr)
    if render_with_chrome(html, out):
        print(f"[polished-pdf] Wrote {out} ({out.stat().st_size:,} bytes) "
              "[no running header/footer]")
        return 0

    print("[polished-pdf] All renderers failed.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
