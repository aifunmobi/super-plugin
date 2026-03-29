#!/bin/bash
# Super Plugin Installer for Claude Code
# Usage: bash <(curl -s https://raw.githubusercontent.com/aifunmobi/super-plugin/main/install.sh)

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

# Symlink skill (single source of truth — always reads from the git repo)
ln -sf "$PLUGIN_DIR/skills/super/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  Linked skill -> $SKILLS_DIR/SKILL.md -> repo"

# Symlink hooks
ln -sf "$PLUGIN_DIR/hooks/super-plan-guard.js" "$HOOKS_DIR/super-plan-guard.js"
ln -sf "$PLUGIN_DIR/hooks/super-research-tracker.js" "$HOOKS_DIR/super-research-tracker.js"
echo "  Linked hooks -> $HOOKS_DIR/ -> repo"

# Patch settings.json to register hooks
if [ -f "$SETTINGS" ]; then
  if grep -q "super-plan-guard" "$SETTINGS" 2>/dev/null; then
    echo "  Hooks already registered in settings.json"
  else
    node -e "
const fs = require('fs');
const settings = JSON.parse(fs.readFileSync('$SETTINGS', 'utf8'));

if (!settings.hooks) settings.hooks = {};
if (!settings.hooks.PreToolUse) settings.hooks.PreToolUse = [];
if (!settings.hooks.PostToolUse) settings.hooks.PostToolUse = [];

const existingPre = settings.hooks.PreToolUse.find(h => h.matcher === 'Write|Edit');
if (existingPre) {
  if (!existingPre.hooks) existingPre.hooks = [];
  if (!existingPre.hooks.some(h => h.command && h.command.includes('super-plan-guard'))) {
    existingPre.hooks.push({
      type: 'command',
      command: 'node \"\$HOME/.claude/hooks/super-plan-guard.js\"',
      timeout: 3
    });
  }
} else {
  settings.hooks.PreToolUse.push({
    matcher: 'Write|Edit',
    hooks: [{
      type: 'command',
      command: 'node \"\$HOME/.claude/hooks/super-plan-guard.js\"',
      timeout: 3
    }]
  });
}

if (!settings.hooks.PostToolUse.some(h => h.hooks && h.hooks.some(hh => hh.command && hh.command.includes('super-research-tracker')))) {
  settings.hooks.PostToolUse.push({
    matcher: 'Write',
    hooks: [{
      type: 'command',
      command: 'node \"\$HOME/.claude/hooks/super-research-tracker.js\"',
      timeout: 5
    }]
  });
}

fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2));
"
    echo "  Registered hooks in settings.json"
  fi
else
  cat > "$SETTINGS" << 'SETTINGSEOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOME/.claude/hooks/super-plan-guard.js\"",
            "timeout": 3
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOME/.claude/hooks/super-research-tracker.js\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
  echo "  Created settings.json with hooks"
fi

echo ""
echo "  Done! v$VERSION installed."
echo ""
echo "  Files (symlinked to repo — git pull to update):"
echo "    ~/.claude/skills/super/SKILL.md"
echo "    ~/.claude/hooks/super-plan-guard.js"
echo "    ~/.claude/hooks/super-research-tracker.js"
echo "    ~/.claude/settings.json (hooks registered)"
echo ""
echo "  To update later:  cd $PLUGIN_DIR && git pull"
echo ""
echo "  Restart Claude Code, then try:"
echo "    /super dry build a todo app"
echo ""
