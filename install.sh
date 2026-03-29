#!/bin/bash
# Super Plugin Installer for Claude Code
# Usage: bash <(curl -s https://raw.githubusercontent.com/aifunmobi/super-plugin/master/install.sh)

set -e

REPO="https://github.com/aifunmobi/super-plugin.git"
TMP_DIR=$(mktemp -d)
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/super"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing /super plugin for Claude Code..."

# Clone repo
git clone --quiet "$REPO" "$TMP_DIR/super-plugin"

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

// Ensure hooks structure exists
if (!settings.hooks) settings.hooks = {};
if (!settings.hooks.PreToolUse) settings.hooks.PreToolUse = [];
if (!settings.hooks.PostToolUse) settings.hooks.PostToolUse = [];

// Add plan guard to PreToolUse
const existingPre = settings.hooks.PreToolUse.find(h => h.matcher === 'Write|Edit');
if (existingPre) {
  if (!existingPre.hooks) existingPre.hooks = [];
  existingPre.hooks.push({
    type: 'command',
    command: 'node .claude/hooks/super-plan-guard.js',
    timeout: 3
  });
} else {
  settings.hooks.PreToolUse.push({
    matcher: 'Write|Edit',
    hooks: [{
      type: 'command',
      command: 'node .claude/hooks/super-plan-guard.js',
      timeout: 3
    }]
  });
}

// Add research tracker to PostToolUse
settings.hooks.PostToolUse.push({
  matcher: 'Write',
  hooks: [{
    type: 'command',
    command: 'node .claude/hooks/super-research-tracker.js',
    timeout: 5
  }]
});

fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2));
"
    echo "  Registered hooks in settings.json"
  fi
else
  # Create minimal settings.json
  cat > "$SETTINGS" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node .claude/hooks/super-plan-guard.js",
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
            "command": "node .claude/hooks/super-research-tracker.js",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF
  echo "  Created settings.json with hooks"
fi

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "Done! Restart Claude Code and use /super to get started."
echo ""
echo "Files installed:"
echo "  ~/.claude/skills/super/SKILL.md"
echo "  ~/.claude/hooks/super-plan-guard.js"
echo "  ~/.claude/hooks/super-research-tracker.js"
echo "  ~/.claude/settings.json (hooks registered)"
