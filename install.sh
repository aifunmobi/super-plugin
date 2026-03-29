#!/bin/bash
# Super Plugin Installer for Claude Code
# Usage: bash <(curl -s https://raw.githubusercontent.com/aifunmobi/super-plugin/main/install.sh)

set -e

REPO="https://github.com/aifunmobi/super-plugin.git"
TMP_DIR=$(mktemp -d)
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/super"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

echo ""
echo "  /super — The Only Slash Command You Need"
echo "  ========================================="
echo ""
echo "  Installing /super plugin for Claude Code..."
echo ""

# Clone repo
git clone --quiet "$REPO" "$TMP_DIR/super-plugin"

# Read version
VERSION=$(node -p "require('$TMP_DIR/super-plugin/.claude-plugin/plugin.json').version" 2>/dev/null || echo "unknown")

# Create directories
mkdir -p "$SKILLS_DIR" "$HOOKS_DIR"

# Copy skill
cp "$TMP_DIR/super-plugin/skills/super/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  Installed skill -> $SKILLS_DIR/SKILL.md"

# Copy hooks
cp "$TMP_DIR/super-plugin/hooks/super-plan-guard.js" "$HOOKS_DIR/"
cp "$TMP_DIR/super-plugin/hooks/super-research-tracker.js" "$HOOKS_DIR/"
echo "  Installed hooks -> $HOOKS_DIR/"

# Patch settings.json to register hooks
if [ -f "$SETTINGS" ]; then
  # Check if hooks are already registered
  if grep -q "super-plan-guard" "$SETTINGS" 2>/dev/null; then
    echo "  Hooks already registered in settings.json"
  else
    # Use node to safely patch JSON
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

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "  Done! v$VERSION installed."
echo ""
echo "  Files:"
echo "    ~/.claude/skills/super/SKILL.md"
echo "    ~/.claude/hooks/super-plan-guard.js"
echo "    ~/.claude/hooks/super-research-tracker.js"
echo "    ~/.claude/settings.json (hooks registered)"
echo ""
echo "  Restart Claude Code, then try:"
echo "    /super dry build a todo app"
echo ""
