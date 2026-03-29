---
name: refresh
description: Publish /super plugin changes — runs tests, bumps version, syncs installed files, updates README and docs, commits, pushes, and verifies everything is live
---

# /refresh — Super Plugin Publish Workflow

When `/refresh` is invoked, execute the full publish workflow for the /super plugin. This automates every step needed to go from "changes on disk" to "live on GitHub and installed locally."

**Do not skip steps. Do not ask for confirmation on each step — run them all and report results at the end.**

## Plugin Locations

| Path | What |
|---|---|
| `~/.claude/plugins/marketplaces/local/plugins/super/` | Git repo (source of truth) |
| `~/.claude/skills/super/SKILL.md` | Symlink to repo SKILL.md |
| `~/.claude/hooks/super-plan-guard.js` | Symlink to repo hook |
| `~/.claude/hooks/super-research-tracker.js` | Symlink to repo hook |

## Workflow Steps

Execute these in order:

### Step 1: Verify working directory

```bash
cd ~/.claude/plugins/marketplaces/local/plugins/super
git status
```

If not a git repo, abort and tell the user.

### Step 2: Run the full test suite

```bash
bash tests/run-all.sh
```

If any tests fail, **stop here**. Show the failures and ask the user to fix them before publishing.

### Step 3: Read current version

```bash
node -p "require('./.claude-plugin/plugin.json').version"
```

### Step 4: Determine version bump

Look at what changed since the last commit:
- **New capability or major behavior change** → bump minor (e.g., 1.7.0 → 1.8.0)
- **Bug fixes, doc updates, small tweaks** → bump patch (e.g., 1.7.0 → 1.7.1)
- If the user provided a version in their `/refresh` arguments (e.g., `/refresh 2.0.0`), use that instead.

Update `.claude-plugin/plugin.json` with the new version.

### Step 5: Update README changelog

Read the current `README.md`. Add a new changelog entry at the top of the changelog section with the new version number and a summary of what changed. Derive the summary from `git diff --cached` and `git diff` — describe the changes, don't just list files.

### Step 6: Sync installed files (verify symlinks)

Check that symlinks exist and point to the repo:

```bash
ls -la ~/.claude/skills/super/SKILL.md
ls -la ~/.claude/hooks/super-plan-guard.js
ls -la ~/.claude/hooks/super-research-tracker.js
```

If any are regular files (not symlinks), replace them with symlinks:

```bash
ln -sf ~/.claude/plugins/marketplaces/local/plugins/super/skills/super/SKILL.md ~/.claude/skills/super/SKILL.md
ln -sf ~/.claude/plugins/marketplaces/local/plugins/super/hooks/super-plan-guard.js ~/.claude/hooks/super-plan-guard.js
ln -sf ~/.claude/plugins/marketplaces/local/plugins/super/hooks/super-research-tracker.js ~/.claude/hooks/super-research-tracker.js
```

### Step 7: Stage and commit

```bash
git add -A
git commit -m "<conventional commit message>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Use a conventional commit message that accurately describes the changes:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation-only changes
- `chore:` for maintenance

### Step 8: Push to GitHub

```bash
git push origin main
```

If push fails (e.g., remote has newer commits), pull with rebase first:

```bash
git pull --rebase origin main
git push origin main
```

### Step 9: Verify

Run these checks and report results:

1. `git status` — should be clean
2. `git log --oneline origin/main -1` — should match local HEAD
3. Symlinks still intact (ls -la the 3 paths)
4. Version in plugin.json matches the bump

### Step 10: Report

Output a summary:

```
/refresh complete
━━━━━━━━━━━━━━━━

Version: v1.7.0 → v1.8.0
Tests: 39/39 passed
Commit: abc1234 feat: <message>
Pushed: origin/main up to date
Symlinks: all 3 intact

Changes published:
- <bullet summary of what changed>

Other Macs: /super update
```

## Arguments

| Argument | Effect |
|---|---|
| (none) | Auto-detect version bump from changes |
| `1.8.0` or `v1.8.0` | Force specific version |
| `patch` | Force patch bump |
| `minor` | Force minor bump |
| `major` | Force major bump |
| `--dry` | Show what would happen without committing or pushing |

## Error Handling

| Error | Action |
|---|---|
| Tests fail | Stop. Show failures. Do not commit. |
| Nothing to commit | Say "nothing to publish" and exit. |
| Push rejected | Pull --rebase, then retry push once. If still fails, show error. |
| Symlink broken | Recreate it and warn the user. |
| Not a git repo | Abort with install instructions. |
