# Polished PDF Style — Institutional Research Report

This is the **default** PDF style for `/super` deliverables. It mirrors a
dark-teal institutional research format with a full-bleed cover, running
header/footer, teal-headed tables, key-finding callouts, and HIGH / MEDIUM / LOW
confidence chips.

## When this style is used

Activated automatically whenever `/super` is asked to produce a PDF deliverable.
This applies to:

- Research reports rendered to PDF
- `illustrate` runs that end with PDF output
- Any task whose final deliverable is a `.pdf`

Suppress with the `plain-pdf` option (e.g. `/super plain-pdf research X`),
or use a different deliverable format entirely.

## Pipeline

1. Write the report content as Markdown in `.super/<topic>/report.md`
2. Generate charts to `.super/<topic>/charts/` at 150 DPI using the matplotlib
   palette in `chart_palette.py`
3. Write the report as HTML using `report_template.html` as the structural
   reference (copy and adapt — do NOT rewrite the CSS)
4. Run `render_polished_pdf.py` to merge a no-header cover with header/footer body
5. Final PDF is written to the user-facing output path

## Required tools

- `python3` with `matplotlib`, `playwright`, and `pypdf` installed
- Playwright chromium: `python3 -m playwright install chromium` (one-time)

If Playwright chromium isn't installed and the user is offline, fall back to
Chrome direct headless (no running header/footer) — see `render_polished_pdf.py`
for the fallback path.

## Style tokens

| Token                  | Value      | Use                                    |
|------------------------|------------|----------------------------------------|
| `--teal-deep`          | `#134e4a`  | Cover background, deepest accent       |
| `--teal`               | `#1a5e5b`  | Section headers, table heads, rules    |
| `--teal-mid`           | `#2a7a76`  | Cover pill, KPI cards, top/bottom rules|
| `--teal-bg`            | `#e9f1f0`  | Key-finding callout background         |
| `--ink`                | `#2c3e50`  | Body text                              |
| `--grey`               | `#6b7c85`  | Header/footer, captions                |
| `--rule`               | `#d0d8dc`  | Table cell borders, header/footer rule |
| `--paper-cool`         | `#fafbfb`  | Alternating row tint                   |
| Confidence HIGH (chip) | bg `#d4edda` / fg `#155724` | "HIGH" tag    |
| Confidence MED  (chip) | bg `#fff3cd` / fg `#856404` | "MEDIUM" tag  |
| Confidence LOW  (chip) | bg `#f8d7da` / fg `#721c24` | "LOW" tag     |

## Cover page anatomy

```
┌──────────────────────────────────────┐ ← top rule (teal-mid)
│  Dark teal background                │
│                                      │
│  [ INSTITUTIONAL RESEARCH REPORT ]   │ ← pill (teal-mid bg)
│                                      │
│  Large white title (52pt, 800)       │
│                                      │
│  Subtitle (21pt, 400, 86% white)     │
│                                      │
│  3-4 line blurb (10.5pt, 88% white)  │
│  ─────────────── divider ─────────── │
│  Date | Universe | Source            │ ← meta row
│                                      │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐             │ ← KPI cards (teal-mid)
│  │KPI│ │KPI│ │KPI│ │KPI│             │
│  └───┘ └───┘ └───┘ └───┘             │
│                                      │
│  Confidential footer (centered)      │
└──────────────────────────────────────┘ ← bottom rule (teal-mid)
```

## Inner page anatomy

```
RESEARCH DRAFT                Weather Derivatives & ...  ← running header
─────────────────────────────────────────────────────
                                                       (header rule)

1. Section Title (26pt, teal)                          ← numbered section
═════════════════════════════════════                  (section rule)

1.1 Subsection (14pt, teal)

Body text justified, 10.5pt, dark ink, 1.55 line
height. **Bold** stays ink-colored, *italic* softer.
Confidence chips inline: HIGH MEDIUM LOW.

┌─ KEY FINDING — Title ─────────────────────────┐    ← key-finding callout
│ Teal-bg, left-bordered, padded                │      (teal-bg, left border)
└───────────────────────────────────────────────┘

| Header (teal bg, white text)   |              |    ← table with teal head
| Alternating row tints          |              |      and #fafbfb tint

─────────────────────────────────────────────────────
May 2026                                       Page N ← running footer
```

## Default chart matplotlib palette (drop-in)

```python
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

NAVY = "#1a3a4a"; GOLD = "#c8963e"; TEAL = "#2a9d8f"
GREEN = "#3aa674"; AMBER = "#e0a93b"; RED = "#c0392b"; GREY = "#7f8c8d"

plt.rcParams.update({
    "figure.dpi": 150, "savefig.dpi": 150,
    "savefig.bbox": "tight", "savefig.pad_inches": 0.25,
    "font.family": "DejaVu Sans", "font.size": 10,
    "axes.titlesize": 13, "axes.titleweight": "bold", "axes.titlecolor": NAVY,
    "axes.labelsize": 10.5, "axes.labelcolor": "#2c3e50",
    "axes.edgecolor": "#999999", "axes.linewidth": 0.6,
    "axes.spines.top": False, "axes.spines.right": False,
    "xtick.labelsize": 9.5, "ytick.labelsize": 9.5,
    "legend.frameon": False, "legend.fontsize": 9.5,
    "grid.color": "#e0e0e0", "grid.linewidth": 0.5,
})
```
