#!/bin/bash
# Super Plugin Installer for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/aifunmobi/super-plugin/main/install.sh | bash

set -e

REPO="https://github.com/aifunmobi/super-plugin.git"
CLAUDE_DIR="$HOME/.claude"
PLUGIN_DIR="$CLAUDE_DIR/plugins/marketplaces/local/plugins/super"
SKILLS_DIR="$CLAUDE_DIR/skills/super"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

echo ""
echo "  /super — The Only Slash Command You Need"
echo "  ========================================="
echo ""
echo "  Installing /super plugin for Claude Code..."
echo ""

# Clone or update the repo to the permanent plugin directory
if [ -d "$PLUGIN_DIR/.git" ]; then
  echo "  Existing installation found — updating..."
  # Fix stale branch tracking (master -> main migration)
  CURRENT_BRANCH=$(git -C "$PLUGIN_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  REMOTE_DEFAULT=$(git -C "$PLUGIN_DIR" remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
  if [ "$CURRENT_BRANCH" = "master" ] || [ "$REMOTE_DEFAULT" = "main" -a "$CURRENT_BRANCH" != "main" ]; then
    echo "  Switching from $CURRENT_BRANCH to main..."
    git -C "$PLUGIN_DIR" fetch --quiet origin main 2>/dev/null
    git -C "$PLUGIN_DIR" checkout -B main origin/main --quiet 2>/dev/null
  fi
  git -C "$PLUGIN_DIR" pull --ff-only --quiet 2>/dev/null || {
    echo "  Pull failed — re-cloning fresh..."
    rm -rf "$PLUGIN_DIR"
    git clone --quiet "$REPO" "$PLUGIN_DIR"
  }
else
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  if [ -d "$PLUGIN_DIR" ]; then
    echo "  Backing up existing $PLUGIN_DIR..."
    mv "$PLUGIN_DIR" "${PLUGIN_DIR}.bak.$(date +%s)"
  fi
  git clone --quiet "$REPO" "$PLUGIN_DIR"
fi

# Read version
VERSION=$(node -p "require('$PLUGIN_DIR/.claude-plugin/plugin.json').version" 2>/dev/null || echo "unknown")

# Create target directories
mkdir -p "$SKILLS_DIR" "$HOOKS_DIR"

# Symlink skills (single source of truth — always reads from the git repo)
ln -sf "$PLUGIN_DIR/skills/super/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  Linked /super skill -> $SKILLS_DIR/SKILL.md -> repo"

REFRESH_DIR="$CLAUDE_DIR/skills/refresh"
mkdir -p "$REFRESH_DIR"
ln -sf "$PLUGIN_DIR/skills/refresh/SKILL.md" "$REFRESH_DIR/SKILL.md"
echo "  Linked /refresh skill -> $REFRESH_DIR/SKILL.md -> repo"

# Symlink hooks
ln -sf "$PLUGIN_DIR/hooks/super-plan-guard.js" "$HOOKS_DIR/super-plan-guard.js"
ln -sf "$PLUGIN_DIR/hooks/super-research-tracker.js" "$HOOKS_DIR/super-research-tracker.js"
ln -sf "$PLUGIN_DIR/hooks/super-session-start.js" "$HOOKS_DIR/super-session-start.js"
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

echo ""
echo "  Done! v$VERSION installed."
echo ""
echo "  Files (symlinked to repo — git pull to update):"
echo "    ~/.claude/skills/super/SKILL.md       (/super)"
echo "    ~/.claude/skills/refresh/SKILL.md     (/refresh)"
echo "    ~/.claude/hooks/super-session-start.js   (/super primer at startup)"
echo "    ~/.claude/hooks/super-plan-guard.js"
echo "    ~/.claude/hooks/super-research-tracker.js"
echo "    ~/.claude/settings.json (hooks registered)"
echo ""
echo "  Commands:"
echo "    /super             — autonomous task engine"
echo "    /super update      — self-update from GitHub"
echo "    /refresh           — publish plugin changes (test, bump, commit, push)"
echo ""
echo "  Restart Claude Code, then try:"
echo "    /super dry build a todo app"
echo ""
