#!/usr/bin/env node
// super-hook-version: 1.0.0
// /super Plan Enforcement Guard — PreToolUse hook
//
// Ensures a plan exists before source code is modified when /super is active.
// This is the enforcement layer that makes "no code without a verified plan"
// more than a prompt instruction.
//
// How it works:
// 1. Checks if a /super session is active (.super/ directory exists)
// 2. If active, checks if a plan has been created (.super/plan.md exists)
// 3. If editing source files without a plan, injects an advisory warning
//
// Advisory only — does not block. The agent sees the warning and should
// create a plan before continuing. This catches the common failure mode
// where Claude skips planning under pressure.
//
// Files that bypass the guard (always allowed without plan):
// - .super/* (writing artifacts is always OK)
// - .planning/* (GSD artifacts)
// - package.json, package-lock.json, *.lock (dependency management)
// - *.md (documentation)
// - *.json config files in root
// - .gitignore, .env* (config)

const fs = require('fs');
const path = require('path');

// Files that are always OK to edit without a plan
const BYPASS_PATTERNS = [
  /^\.super\//,
  /^\.planning\//,
  /package(-lock)?\.json$/,
  /\.lock$/,
  /\.md$/,
  /^\.gitignore$/,
  /^\.env/,
  /^tsconfig.*\.json$/,
  /^\.eslintrc/,
  /^\.prettierrc/,
  /^jest\.config/,
  /^vitest\.config/,
  /^vite\.config/,
  /^next\.config/,
  /^webpack\.config/,
];

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const toolName = data.tool_name;

    // Only check Write and Edit operations
    if (toolName !== 'Write' && toolName !== 'Edit') {
      process.exit(0);
    }

    const filePath = data.tool_input?.file_path || '';
    const cwd = data.cwd || process.cwd();

    // Check if /super session is active
    const superDir = path.join(cwd, '.super');
    if (!fs.existsSync(superDir)) {
      // No /super session active — exit silently
      process.exit(0);
    }

    // Check if plan exists
    const planPath = path.join(superDir, 'plan.md');
    if (fs.existsSync(planPath)) {
      // Plan exists — all good
      process.exit(0);
    }

    // Get relative path for pattern matching
    const relPath = path.relative(cwd, filePath);

    // Check bypass patterns
    for (const pattern of BYPASS_PATTERNS) {
      if (pattern.test(relPath)) {
        process.exit(0);
      }
    }

    // No plan, editing source code — warn
    const output = {
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        additionalContext:
          `PLAN GUARD: You are editing ${path.basename(filePath)} but no plan exists yet ` +
          `(.super/plan.md not found). The /super skill requires a verified plan before ` +
          `writing source code. Create .super/plan.md with atomic tasks, verification ` +
          `criteria, and wave groupings first. If this is exploratory work or a trivial ` +
          `change, create a minimal plan documenting what you're doing and why.`
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch {
    process.exit(0);
  }
});
