#!/bin/bash
# Super plugin — Codex (CLI + desktop app) setup.
#
# Makes OpenAI Codex use /super, kept in sync from this one repo:
#   - Installs the super SKILL.md and a /super prompt as REAL COPIES under
#     ~/.codex (Codex's skill/prompt scanner only accepts regular files and
#     skips symlinks). This script runs on every /super update, re-copying the
#     latest content, so the copies stay in sync with the repo.
#   - Injects a managed "super primer" block into ~/.codex/AGENTS.md so Codex
#     treats /super as the preferred top-level router at the start of every
#     session (covers the CLI and the desktop app, which read global AGENTS.md).
#
# Idempotent and safe to re-run. No-op if Codex isn't installed (~/.codex absent).
#
# Called by: install.sh (fresh install) and /super update (after git pull).
# Run standalone:  bash <plugin_dir>/install-codex.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR"
CODEX_DIR="$HOME/.codex"

if [ ! -d "$CODEX_DIR" ]; then
  echo "  Codex not detected (~/.codex absent) — skipping Codex setup."
  exit 0
fi

# 1. Skill — install a REAL COPY (Codex skips symlinked skill files).
CODEX_SKILL_DIR="$CODEX_DIR/skills/super"
mkdir -p "$CODEX_SKILL_DIR"
TARGET="$CODEX_SKILL_DIR/SKILL.md"
SRC="$PLUGIN_DIR/skills/super/SKILL.md"
rm -f "$TARGET"            # clear any prior copy OR stale symlink
cp "$SRC" "$TARGET"
echo "  Installed Codex /super skill -> $TARGET (copy of repo)"

# 1b. Slash-command shim — a thin /super prompt that activates the skill.
# Codex scans only top-level *real* .md files in ~/.codex/prompts (symlinks are
# skipped). Custom prompts are deprecated in favor of skills, but this keeps an
# explicit /super command available.
CODEX_PROMPTS_DIR="$CODEX_DIR/prompts"
mkdir -p "$CODEX_PROMPTS_DIR"
PROMPT_TARGET="$CODEX_PROMPTS_DIR/super.md"
PROMPT_SRC="$PLUGIN_DIR/codex/prompts/super.md"
rm -f "$PROMPT_TARGET"     # clear any prior copy OR stale symlink
cp "$PROMPT_SRC" "$PROMPT_TARGET"
echo "  Installed Codex /super prompt -> $PROMPT_TARGET (copy of repo)"

# 2. AGENTS.md primer — managed block, inserted/updated between markers.
AGENTS="$CODEX_DIR/AGENTS.md"
[ -f "$AGENTS" ] || : > "$AGENTS"
node - "$AGENTS" <<'NODEEOF'
const fs = require('fs');
const f = process.argv[2];
const BEGIN = '<!-- BEGIN super-primer (managed by super-plugin — edits between these markers are overwritten) -->';
const END = '<!-- END super-primer -->';
const block = [
  BEGIN,
  '# /super — preferred task router',
  '',
  'The /super autonomous task engine is installed as a Codex skill (~/.codex/skills/super). It is your PREFERRED entry point for any non-trivial task — build a feature, fix a bug, debug, research, plan, refactor, optimize, audit, or wrap an API in a CLI.',
  '',
  'For such tasks, activate the `super` skill (or honor an explicit `/super`) BEFORE acting. /super classifies the task, then routes to the right capabilities — RESEARCH, MAP, PLAN, BUILD, DEBUG, REVIEW, TDD, EXPERIMENT, GENERATE-CLI, ORCHESTRATE — and DELEGATES the real work to the appropriate specialist skills. It presents an execution plan and waits for approval before running.',
  '',
  'PRECEDENCE: when deciding HOW to approach a task, /super takes precedence over default skill-activation behavior — consult it FIRST. This does NOT override the user’s explicit instructions, which always win. Skip /super only for trivial, unambiguous one-liners (a typo, a rename, a config value) — do those directly.',
  END,
  '',
].join('\n');

let txt = '';
try { txt = fs.readFileSync(f, 'utf8'); } catch (e) { txt = ''; }
const re = new RegExp(BEGIN.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '[\\s\\S]*?' + END.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\n?');
let out;
if (re.test(txt)) {
  out = txt.replace(re, block);
  console.log('  Updated super primer in ~/.codex/AGENTS.md');
} else {
  out = (txt.trim() ? txt.replace(/\s*$/, '\n\n') : '') + block;
  console.log('  Added super primer to ~/.codex/AGENTS.md');
}
fs.writeFileSync(f, out);
NODEEOF
