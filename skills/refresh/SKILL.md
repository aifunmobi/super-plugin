---
name: refresh
description: Universal project publish — detects project type, runs tests, bumps version, updates docs/changelog, commits, pushes, creates backups. Works in any git repo with any language or framework.
---

# /refresh — Universal Project Publish

When `/refresh` is invoked, detect the current project type and execute a full publish workflow. Works in **any git repo** — Node, Python, Rust, Go, Ruby, or plain files.

**Do not skip steps. Do not ask for confirmation on each step — run them all and report results at the end.**

## Step 1: Detect Project

Read the current working directory and detect what's present. Run these checks in parallel:

```bash
# All in one parallel batch:
git status                              # Is this a git repo?
git log --oneline -5                    # Recent commit style
git remote -v                           # Where does it push?
git diff --stat                         # What changed?
ls -la                                  # What files exist?
```

Build a project profile from what exists:

| File detected | Project type | Version location |
|---|---|---|
| `package.json` | Node.js / JavaScript / TypeScript | `version` field in package.json |
| `Cargo.toml` | Rust | `version` field in Cargo.toml |
| `pyproject.toml` | Python (modern) | `version` field in [project] or [tool.poetry] |
| `setup.py` or `setup.cfg` | Python (legacy) | `version=` in setup.py/cfg |
| `go.mod` | Go | No version file (use git tags) |
| `Gemfile` + `*.gemspec` | Ruby | `version` in gemspec |
| `.claude-plugin/plugin.json` | Claude Code plugin | `version` in plugin.json |
| `pubspec.yaml` | Dart / Flutter | `version` field |
| `pom.xml` | Java / Maven | `<version>` tag |
| None of the above | Generic project | No version to bump (skip version step) |

Also detect:

| File/dir detected | What it means |
|---|---|
| `tests/` or `test/` or `__tests__/` or `spec/` | Has test directory |
| `*.test.*` or `*_test.*` or `*_spec.*` files | Has test files |
| `Makefile` with `test` target | Run `make test` |
| `package.json` with `scripts.test` | Run `npm test` or `yarn test` |
| `pytest.ini` or `pyproject.toml` with `[tool.pytest]` | Run `pytest` |
| `Cargo.toml` | Run `cargo test` |
| `tests/run-all.sh` | Run `bash tests/run-all.sh` |
| `.github/workflows/` | Has CI — mention in report |
| `README.md` | Has README to update |
| `CHANGELOG.md` | Has dedicated changelog |
| `CLAUDE.md` | Has Claude config |
| `.claude-plugin/` | Is a Claude Code plugin |
| Symlinks in `~/.claude/skills/` or `~/.claude/hooks/` pointing to this repo | Has installed symlinks to verify |

## Step 2: Run Tests

Pick the right test runner based on what was detected:

| Detection | Command | Priority |
|---|---|---|
| `tests/run-all.sh` exists | `bash tests/run-all.sh` | 1 (custom runner first) |
| `Makefile` with `test` target | `make test` | 2 |
| `package.json` with `test` script (not `"test": "echo..."`) | `npm test` | 3 |
| `pytest.ini` or pytest in pyproject.toml | `pytest` | 3 |
| `Cargo.toml` | `cargo test` | 3 |
| `go.mod` | `go test ./...` | 3 |
| `*.gemspec` | `bundle exec rspec` or `rake test` | 3 |
| No tests detected | Skip — mention "no tests found" in report | — |

**If tests fail, STOP. Show failures. Do not continue.**

If tests pass, note the count (e.g., "39/39 passed") for the report.

## Step 3: Read Current Version

Based on the detected version location, read the current version:

```bash
# Node.js
node -p "require('./package.json').version"

# Rust
grep '^version' Cargo.toml | head -1

# Python
grep 'version' pyproject.toml | head -1

# Claude plugin
node -p "require('./.claude-plugin/plugin.json').version"

# Go — use latest git tag
git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0"
```

If no version file exists, skip version bumping entirely.

## Step 4: Bump Version

Determine the bump type:

**If the user specified a version or bump type in arguments, use that.**

Otherwise, auto-detect from `git diff`:
- Files changed include new features, new files, new capabilities → **minor** bump
- Files changed are fixes, docs, tweaks → **patch** bump
- User explicitly says `major` → **major** bump

Apply the bump to the correct file:

| Project type | How to bump |
|---|---|
| Node.js | Update `version` in `package.json` (and `package-lock.json` if it exists) |
| Rust | Update `version` in `Cargo.toml` |
| Python | Update `version` in `pyproject.toml` or `setup.py` |
| Claude plugin | Update `version` in `.claude-plugin/plugin.json` |
| Go | Create git tag after commit (e.g., `v1.2.3`) |
| No version file | Skip |

## Step 5: Update Docs

### Changelog

Look for a changelog in this order:
1. `CHANGELOG.md` — add entry at top under new version header
2. `README.md` with a `## Changelog` section — add entry at top of that section
3. Neither exists — skip changelog

**Changelog entry format:**
```markdown
### vX.Y.Z

- **Summary of change 1** — brief description
- **Summary of change 2** — brief description
```

Derive the summary from `git diff` — describe what changed in human terms, not file paths.

### README

If `README.md` exists and has version badges or version references, update them to the new version.

## Step 6: Verify Symlinks (Claude plugins only)

If `.claude-plugin/` was detected, check for symlinks from `~/.claude/skills/` and `~/.claude/hooks/` that point into this repo.

```bash
# Find symlinks pointing to this repo
find ~/.claude/skills ~/.claude/hooks -type l 2>/dev/null | while read link; do
  target=$(readlink "$link")
  if [[ "$target" == *"$(basename $(pwd))"* ]]; then
    echo "  OK: $link -> $target"
  fi
done
```

If any expected symlinks are missing or broken, recreate them and warn.

For non-plugin projects, skip this step.

## Step 7: Create Backup (if applicable)

Check if there's an existing zip backup on Desktop matching this project name:

```bash
ls ~/Desktop/$(basename $(pwd))*.zip 2>/dev/null
```

If found, create an updated zip:

```bash
git archive --format=zip --prefix=$(basename $(pwd))/ -o ~/Desktop/$(basename $(pwd))-v${NEW_VERSION}.zip HEAD
```

If no previous zip exists, skip (don't create unsolicited backups).

## Step 8: Stage and Commit

```bash
git add -A
```

**Check for sensitive files before committing:**
- Warn if `.env`, `credentials.json`, `*.pem`, `*.key`, or other secrets are staged
- If found, unstage them and warn the user

Commit with conventional message:

```bash
git commit -m "<type>(<scope>): <description>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

Commit type rules:
- New files, new features → `feat:`
- Bug fixes → `fix:`
- Documentation only → `docs:`
- Refactoring, no behavior change → `refactor:`
- Tests only → `test:`
- Build/CI changes → `chore:`

Match the existing commit style from `git log --oneline -5`.

## Step 9: Push

```bash
git push
```

If push fails:
1. Try `git pull --rebase` then `git push`
2. If still fails, show the error — do not force push

If there's no remote, say so and skip.

## Step 10: Tag (if version was bumped and project uses git tags)

For Go projects or projects that already have git tags:

```bash
git tag -a "v${NEW_VERSION}" -m "v${NEW_VERSION}"
git push --tags
```

For other projects, skip tagging.

## Step 11: Report

Output a summary:

```
/refresh complete
━━━━━━━━━━━━━━━━

Project: <project name> (<detected type>)
Version: v1.7.0 → v1.8.0
Tests: 39/39 passed
Commit: abc1234 feat: <message>
Pushed: origin/main up to date
Backup: ~/Desktop/project-v1.8.0.zip (updated)
Symlinks: 4/4 intact (Claude plugin)

Changes published:
- <bullet summary>
- <bullet summary>
```

Adapt the report to what was actually done — omit sections that were skipped (e.g., don't show "Symlinks" for a non-plugin project, don't show "Backup" if no zip existed).

## Arguments

| Argument | Effect |
|---|---|
| (none) | Auto-detect everything |
| `1.8.0` or `v1.8.0` | Force specific version |
| `patch` | Force patch bump |
| `minor` | Force minor bump |
| `major` | Force major bump |
| `dry` | Show what would happen without committing or pushing |
| `no-test` | Skip test step (use with caution) |
| `no-push` | Commit but don't push |

Multiple arguments combine: `/refresh minor no-push` = bump minor, commit, don't push.

## Error Handling

| Error | Action |
|---|---|
| Tests fail | **Stop.** Show failures. Do not commit. |
| Nothing changed | Say "nothing to publish — working tree clean" and exit. |
| Push rejected | Pull --rebase, retry once. If still fails, show error. |
| No git repo | Offer to `git init` and set up remote. |
| Sensitive files staged | Unstage them, warn user, continue with safe files. |
| No remote configured | Commit locally, skip push, mention in report. |
| Version file not found | Skip version bump, mention in report. |
| No tests found | Skip tests, mention "no tests found" in report. |
