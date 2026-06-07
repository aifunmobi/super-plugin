#!/bin/bash
# Super plugin — hook (re-)registration.
#
# Idempotently symlinks the super hook files into ~/.claude/hooks and registers
# them in ~/.claude/settings.json. Safe to run repeatedly: it only adds hook
# entries that are missing and never touches unrelated hooks.
#
# Called by:
#   - install.sh           (fresh install / curl one-liner, after cloning)
#   - /super update        (after `git pull`, so updates pick up new hooks
#                           without a full re-install)
#
# Run standalone:  bash <plugin_dir>/install-hooks.sh

set -e

# Resolve this script's own directory = the plugin repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$HOOKS_DIR"

# Symlink hook files (single source of truth — always reads from the git repo).
ln -sf "$PLUGIN_DIR/hooks/super-plan-guard.js"      "$HOOKS_DIR/super-plan-guard.js"
ln -sf "$PLUGIN_DIR/hooks/super-research-tracker.js" "$HOOKS_DIR/super-research-tracker.js"
ln -sf "$PLUGIN_DIR/hooks/super-session-start.js"   "$HOOKS_DIR/super-session-start.js"
echo "  Linked hooks -> $HOOKS_DIR/ -> repo"

# Register hooks in settings.json (idempotent — adds only what's missing).
# super is distributed via symlinks + settings.json (not a marketplace plugin),
# so settings.json is the registration path that actually fires. The bundled
# hooks/hooks.json mirrors these for anyone who installs super as a true plugin.
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
node - "$SETTINGS" <<'NODEEOF'
const fs = require('fs');
const f = process.argv[2];
let s = {};
try { s = JSON.parse(fs.readFileSync(f, 'utf8')); } catch (e) { s = {}; }
s.hooks = s.hooks || {};

// Add a hook entry only if no entry already references this hook file.
function ensure(event, matcher, file, timeout) {
  s.hooks[event] = s.hooks[event] || [];
  const has = s.hooks[event].some(g => (g.hooks || []).some(h => (h.command || '').includes(file)));
  if (has) return false;
  const entry = { hooks: [{ type: 'command', command: 'node "$HOME/.claude/hooks/' + file + '"', timeout }] };
  if (matcher) entry.matcher = matcher;
  s.hooks[event].push(entry);
  return true;
}

const added = [];
if (ensure('SessionStart', 'startup|clear|compact', 'super-session-start.js', 5)) added.push('session-start');
if (ensure('PreToolUse',  'Write|Edit',            'super-plan-guard.js',     3)) added.push('plan-guard');
if (ensure('PostToolUse', 'Write',                 'super-research-tracker.js', 5)) added.push('research-tracker');

fs.writeFileSync(f, JSON.stringify(s, null, 2));
console.log(added.length ? '  Registered hooks in settings.json: ' + added.join(', ')
                         : '  Hooks already registered in settings.json');
NODEEOF
