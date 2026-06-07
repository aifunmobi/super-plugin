#!/bin/bash
# Super plugin — Codex (CLI + desktop app) setup.
#
# Makes OpenAI Codex use /super, kept in sync from this one repo:
#   - Symlinks the super SKILL.md into ~/.codex/skills/super (Codex auto-discovers
#     skills there; a symlink means `git pull` / `/super update` updates it too).
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

# 1. Skill — symlink to the repo (single source of truth, auto-updates on pull).
CODEX_SKILL_DIR="$CODEX_DIR/skills/super"
mkdir -p "$CODEX_SKILL_DIR"
TARGET="$CODEX_SKILL_DIR/SKILL.md"
SRC="$PLUGIN_DIR/skills/super/SKILL.md"
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  mv "$TARGET" "$TARGET.bak.$(date +%s)"   # preserve any old copy once
fi
ln -sf "$SRC" "$TARGET"
echo "  Linked Codex /super skill -> $TARGET -> repo"

# 1b. Slash-command shim — a thin /super prompt that activates the skill.
# Codex scans only top-level .md files in ~/.codex/prompts. (Custom prompts are
# deprecated in favor of skills, but this keeps an explicit /super command.)
CODEX_PROMPTS_DIR="$CODEX_DIR/prompts"
mkdir -p "$CODEX_PROMPTS_DIR"
PROMPT_TARGET="$CODEX_PROMPTS_DIR/super.md"
PROMPT_SRC="$PLUGIN_DIR/codex/prompts/super.md"
if [ -e "$PROMPT_TARGET" ] && [ ! -L "$PROMPT_TARGET" ]; then
  mv "$PROMPT_TARGET" "$PROMPT_TARGET.bak.$(date +%s)"
fi
ln -sf "$PROMPT_SRC" "$PROMPT_TARGET"
echo "  Linked Codex /super prompt -> $PROMPT_TARGET -> repo"

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
