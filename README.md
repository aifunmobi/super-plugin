# /super — The Only Slash Command You Need

**Stop micromanaging your AI.** Just say `/super` and describe what you want. The plugin figures out the rest — whether it's a one-line typo fix or a full-stack feature spanning multiple services.

`/super` is an autonomous task engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that combines **research, planning, codebase mapping, building, debugging, code review, TDD, experimentation, orchestration, and CLI generation** into a single command. It reads your request, classifies the complexity, and activates exactly the right combination of capabilities — no sub-commands to memorize, no manual workflow to follow.

## Why /super?

**Without /super**, you're the project manager. You decide when to research, when to plan, when to map the codebase, when to parallelize. You repeat yourself across sessions. You lose experiment results when context resets.

**With /super**, Claude becomes a senior engineer who knows the playbook:

- Trivial fix? It just does it. No ceremony.
- Complex feature? It maps your codebase, researches best practices, creates a verified plan, then builds it phase by phase with quality gates.
- Performance problem? It measures a baseline, runs scientific experiments, keeps what works, discards what doesn't — and remembers all of it across sessions.
- Multiple independent tasks? It fans out parallel agents, each with their own fresh context.

Everything is persisted to `.super/` — surviving context resets, session boundaries, and your laptop going to sleep. Pick up exactly where you left off.

## What makes it different

| Problem | How /super solves it |
|---|---|
| Research is shallow and misses connections | **Two-phase research** — orchestrator gathers data, 4 parallel analysts cross-reference and catch inconsistencies |
| Claude jumps straight to coding without thinking | **Plan guard** — enforces research and planning before any code is written |
| Codebase gets re-analyzed every session | **Incremental map caching** — only re-maps what actually changed (git SHA tracking) |
| You forget which approach you already tried | **Experiment continuity** — baselines, hypotheses, and results persist across sessions |
| Simple tasks get buried in ceremony | **SIMPLE fast path** — typo fixes and config changes skip the full pipeline |
| The router picks wrong capabilities | **Options** — `research`, `no-map`, `loops=5` to control exactly what runs |
| Long tasks feel like a black box | **Streaming progress** — structured status updates at every milestone |
| You don't know what it's about to do | **Execution plan** — shows exactly what will happen and waits for your OK |
| Reports are walls of text and tables | **Illustrate** — auto-generates charts from data tables (bar charts, heatmaps, decay curves) |
| Stale artifacts pile up | **Cleanup** — `/super clean` to archive or remove old work |

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/aifunmobi/super-plugin/main/install.sh | bash
```

That's it. Restart Claude Code and start using `/super`.

<details>
<summary>Other install methods</summary>

### Manual clone

```bash
git clone https://github.com/aifunmobi/super-plugin.git \
  ~/.claude/plugins/marketplaces/local/plugins/super
```

### From Claude Code

```
/install-plugin https://github.com/aifunmobi/super-plugin
```

Then enable with `/plugins` or add to `settings.json`:

```json
{
  "enabledPlugins": {
    "super@local": true
  }
}
```

</details>

### Updating

From inside Claude Code:

```
/super update
```

Checks GitHub for a newer version, shows what changed, and updates in place. No re-install needed.

### Bonus: /refresh (universal project publish)

Works in **any git repo** — not just the super plugin. Detects your project type and does the right thing:

```
/refresh              # auto-detect everything, test, bump, commit, push
/refresh minor        # force minor version bump
/refresh 2.0.0        # force specific version
/refresh dry          # preview what would happen
/refresh no-test      # skip tests
/refresh no-push      # commit but don't push
```

What it does (adapts to your project):

| Step | What it does | Adapts to |
|---|---|---|
| 1. Detect | Reads your project structure | Node, Python, Rust, Go, Ruby, Claude plugins, or generic |
| 2. Test | Runs your test suite | npm test, pytest, cargo test, make test, or custom runner |
| 3. Version | Bumps version in the right manifest | package.json, Cargo.toml, pyproject.toml, plugin.json, git tags |
| 4. Docs | Updates changelog in CHANGELOG.md or README.md | Conventional changelog format |
| 5. Symlinks | Verifies Claude plugin symlinks | Only for Claude plugins |
| 6. Backup | Updates Desktop zip if one exists | Only if previous zip found |
| 7. Commit | Conventional commit with Co-Authored-By | Matches your existing commit style |
| 8. Push | Push to remote | Handles rebase conflicts gracefully |
| 9. Report | Summary of everything that happened | Only shows relevant sections |

## Usage

Just say `/super` followed by what you want:

```
/super Add authentication to this Express app
/super What's the best database for our use case?
/super Make the /api/search endpoint faster
/super Fix the typo in utils.ts
```

For non-trivial tasks, `/super` presents an execution plan and waits for your OK:

```
/super Execution Plan
━━━━━━━━━━━━━━━━━━━━

Task: "Add authentication to this Express app"

Capabilities: MAP -> RESEARCH -> PLAN -> BUILD
Loop budget: 2 per capability (default)

Step-by-step:
1. MAP — Analyze existing codebase (4 agents: tech, architecture, quality, concerns)
2. RESEARCH — Investigate auth approaches (JWT, session, OAuth)
3. PLAN — Create verified atomic tasks with dependency waves
4. BUILD — Implement through multi-phase pipeline

Artifacts will be written to: .super/
Commits: Atomic per task

Proceed? [Y/n]
```

You review, adjust if needed, and confirm. SIMPLE mode tasks skip this — they just execute.

## Syntax

```
/super [options] <task description>
```

Options are **plain words** before your task. No `+`, `-`, or `--` — just words.

### Complete option reference

#### Capability controls

Force a capability **on** by name, or **off** with `no-` prefix.

| Option | What it does | Example |
|---|---|---|
| `simple` | Force SIMPLE mode — skip all heavyweight capabilities, just do it | `/super simple rename foo to bar across the project` |
| `no-simple` | Force full routing even if the task looks trivial | `/super no-simple fix the typo in config.ts` |
| `research` | Force RESEARCH on — 4 parallel investigators (stack, architecture, features, pitfalls) | `/super research add caching to the API` |
| `no-research` | Skip RESEARCH even if there are unknowns | `/super no-research add OAuth login` |
| `map` | Force full MAP — re-analyze codebase regardless of cache | `/super map add a new endpoint` |
| `no-map` | Skip MAP — you already know the codebase | `/super no-map add a utility function` |
| `plan` | Force PLAN on (it's on by default for code tasks, but this ensures it) | `/super plan investigate the logging issue` |
| `no-plan` | Skip PLAN — use with caution, no verified tasks before coding | `/super no-plan add the missing import` |
| `build` | Force BUILD on — multi-phase pipeline with quality gates | `/super build research results into implementation` |
| `no-build` | Skip BUILD phase | `/super no-build research the best ORM options` |
| `experiment` | Force EXPERIMENT on — scientific iteration with baseline measurement | `/super experiment add caching and measure impact` |
| `no-experiment` | Skip EXPERIMENT even if the task mentions optimization | `/super no-experiment make the page load faster` |
| `orchestrate` | Force ORCHESTRATE — parallel fan-out across independent subtasks | `/super orchestrate lint all 3 services` |
| `no-orchestrate` | Handle everything sequentially, no parallel agents | `/super no-orchestrate audit the auth and payment services` |
| `generate-cli` | Force GENERATE-CLI — schema-driven CLI tool creation | `/super generate-cli wrap the billing API` |
| `debug` | Force DEBUG — systematic root-cause investigation with persistent state | `/super debug the checkout 500s intermittently` |
| `tdd` | Force TDD discipline in BUILD — red → green → refactor | `/super tdd add a rate limiter` |
| `no-tdd` | Disable TDD even if the router suggests it | `/super no-tdd add the helper` |
| `no-review` | Skip the post-BUILD code-review gate | `/super no-review tweak the copy` |
| `worktrees` | Force git worktree isolation for parallel/orchestrated work | `/super worktrees orchestrate refactor 4 modules` |
| `no-worktrees` | Disable worktree isolation (run parallel agents in place) | `/super no-worktrees orchestrate audit 5 services` |
| `illustrate` | Generate publication-quality charts from report tables (matplotlib, headless) | `/super illustrate research write a market analysis` |
| `no-illustrate` | Skip chart generation even if data tables are present | `/super no-illustrate research quick summary` |

#### Loop control

| Option | What it does | Example |
|---|---|---|
| `loops=0` | Single pass — no re-research, no plan re-verify, one experiment only | `/super loops=0 build the landing page` |
| `loops=1` | One iteration allowed per loop type | `/super loops=1 research auth strategies` |
| `loops=N` | Set all loops to max N iterations (research, plan verify, experiments) | `/super loops=5 experiment optimize the search query` |

**Defaults when `loops=` is not specified:**

| Loop type | Default max | What it controls |
|---|---|---|
| Research | 2 | Re-research iterations when gaps >30% |
| Plan verify | 2 | Revision loops before escalating to user |
| Experiments | 3 | Hypothesis iterations per session |

All loops auto-stop on **diminishing returns**: if an iteration produces <10% new value, it stops early.

**Safety cap:** `loops=` values over 100 pause at the 100th iteration and ask if you want to continue.

#### Meta-commands

| Option | What it does | Example |
|---|---|---|
| `dry` | Preview routing decisions without executing anything | `/super dry add a Redis caching layer` |
| `clean` | Archive or delete the `.super/` directory | `/super clean` |
| `update` | Check GitHub for newer version and self-update | `/super update` |

#### Combining options

Options compose freely. Put as many as you need before the task:

| Command | What happens |
|---|---|
| `/super research loops=5 add caching to the API` | Force research, 5 iterations for all loops |
| `/super no-map no-research refactor the billing module` | Skip map and research, straight to plan+build |
| `/super experiment no-map loops=3 optimize search` | Experiment mode, skip mapping, 3 loops |
| `/super dry research no-map add authentication` | Dry run: show what would happen with research forced on and map off |
| `/super simple fix the typo in README.md` | Force simple mode, just fix it |
| `/super loops=0 no-map quick feature add` | No loops, no mapping, single-pass execution |
| `/super research experiment loops=10 improve API perf` | Full investigation + experiment mode, generous loop budget |

## 9 Capabilities

`/super` has 9 capabilities that combine automatically based on your request.

### SIMPLE — Just do it

For trivial, unambiguous changes. Skips the entire pipeline and the confirmation gate.

```
/super Rename getUserData to fetchUserData
  -> Activating: SIMPLE (trivial change, skipping full pipeline)
```

Triggers on: typo fixes, renames, config value changes, toggling flags, adding imports, one-liners with no design decisions.

### PLAN — No code without a verified plan

The backbone. Every non-trivial task goes through **discuss gray areas -> create atomic tasks -> verify coverage -> execute in waves**. Tasks are grouped into dependency waves and executed with fresh agent contexts. Each completed task produces an atomic git commit.

### RESEARCH — Expert-grade investigation (two-phase)

Uses a proven two-phase pattern that was tested head-to-head against single-phase research and produced significantly deeper analysis:

**Phase 1 — Orchestrator gathers data:** Runs 8-12 parallel web searches across 4 domains (stack, architecture, features, pitfalls). Saves raw results to `.super/research-raw.md`.

**Phase 2 — 4 analysis agents synthesize:** Each agent receives the pre-fetched results and its domain focus. Produces confidence-tagged findings (`[HIGH]`/`[MEDIUM]`/`[LOW]`), cross-references across sources, catches inconsistencies, and generates domain-specific analytical notes.

This two-phase approach exists because sub-agents don't have web search access (platform constraint). The result is actually better than if they did — separating data gathering from analysis produces more rigorous, cross-referenced output with independent quality checks per domain.

### MAP — Understand before modifying (two-phase)

Also uses the two-phase pattern:

**Phase 1 — Orchestrator snapshots the codebase:** Reads package manifests, directory tree, entry points, config files, CI/CD setup, test config, README, and git history in a single parallel batch (~10-15 reads). Saves to `.super/map-raw.md`.

**Phase 2 — 4 analysts receive the snapshot:** Tech, Architecture, Quality, and Concerns analysts each get the full snapshot and focus purely on their domain. No duplicated file reads — every agent has the same complete picture.

Results are **cached with git SHA tracking** — subsequent runs only re-map what actually changed.

### DEBUG — Systematic root-cause investigation

For anything broken: a bug, error, crash, failing test, or regression. Hypothesis-driven (reproduce → evidence → one falsifiable hypothesis → cheapest test → fix the root cause → verify), never symptom-patching. State persists in `.super/debug.md`, so a debug session survives context resets and resumes without re-testing ruled-out theories. Trivial fixes the user already diagnosed stay in SIMPLE; non-trivial fixes hand off to PLAN → BUILD.

```
/super The checkout endpoint returns 500 intermittently
  -> Activating: DEBUG (something broken — root-cause first)
```

### BUILD — Multi-phase pipeline with quality gates

7 phases: Analyze, Design, Implement, Test, Refine, Document, Deliver. Three layers of quality monitoring (task, integration, goal). Each phase has a gate that must pass before proceeding. Plus:

- **TDD mode** (`tdd`) — inverts Implement/Test into red → green → refactor: a failing test first, then the minimum code to pass.
- **Review gate** — before Deliver, an adversarial code review runs in a fresh context; findings are tagged by severity (`must-fix` / `should-fix` / `nice-to-have`) in `.super/review.md` and all must-fixes are resolved. Skip with `no-review`.
- **Verification before completion** — "tests pass" ≠ "it works." Before claiming done, /super actually runs the artifact (CLI, endpoint, UI, or library call) and observes real behavior against the acceptance criteria.

### EXPERIMENT — Scientific iteration

Measures a baseline, forms hypotheses, implements changes, measures again, keeps or discards. One variable at a time. **Results persist across sessions** — come back tomorrow and it picks up at Experiment #4 instead of re-measuring the baseline.

### GENERATE-CLI — Schema-driven tool creation

Reads your API schema (OpenAPI, GraphQL, Discovery docs) or source code and generates a complete CLI with `--help`, `--json` output, and consistent exit codes.

### ORCHESTRATE — Parallel fan-out

For 2+ independent tasks. Decomposes the work, dispatches one agent per task (each with its own MAP/PLAN/BUILD internally), collects results, and synthesizes. When agents write files in parallel, each runs in its own **git worktree** so concurrent edits never collide, then merges back at the end (`no-worktrees` to disable; read-only fan-out skips it automatically). When the **ruflo** suite is installed, ORCHESTRATE delegates to **ruflo-swarm** by default — topology-based coordination (hierarchical / mesh / ring / star / adaptive), live Monitor streams, and anti-drift enforcement — falling back to native fan-out when ruflo is absent.

### ILLUSTRATE — Publication-quality charts

When `illustrate` is used, /super generates charts from report data tables using matplotlib (headless, no display needed). Runs as a post-processing step after report content is written, before PDF generation.

**What it produces:**

| Data pattern | Chart type generated |
|---|---|
| Ranked items with scores | Horizontal bar chart with value labels |
| Yearly/monthly returns | Vertical bar chart (green=positive, red=negative) |
| Cross-category matrix (Strong/Weak) | Color-coded heatmap |
| Values that decay over time | Multi-line curve plot |
| Side-by-side comparisons | Grouped bar chart |

Charts are saved to `.super/charts/` as PNGs at 150 DPI with a consistent institutional color scheme (dark navy, gold accents, green/amber/red confidence colors). The PDF generator embeds them inline with the report.

```
/super illustrate research write a market analysis report
```

## Progress updates

Structured single-line status updates during long-running work:

```
[RESEARCH 2/4] Architecture researcher complete — recommends event-driven pattern
[RESEARCH reloop 1/2] Gap >30% in pitfalls — re-researching with evolved strategy
[MAP skip] Reusing cached maps (0 files changed since abc123)
[BUILD 3/7] Implement phase complete — 4 files written, compiles clean
[EXPERIMENT 2/3] Hypothesis "inline queries" — 15% faster, keeping
[ORCHESTRATE 3/5] Service-C audit complete, 2 findings
```

## How it works under the hood

### Enforcement hooks

Two hooks run automatically to keep the workflow honest:

- **super-plan-guard** (PreToolUse) — Warns if source code is being edited without a plan. Suppressed in SIMPLE and DEBUG mode (investigation edits need no plan).
- **super-research-tracker** (PostToolUse) — Tracks every artifact write, updates session state, validates that research has confidence tags, plans have verification criteria, debug logs have a root cause, reviews have severity-tagged findings, and experiments have baselines.

### Artifact persistence

All work lives in `.super/` in your project directory:

```
.super/
  state.json          # Session state, map cache, experiment tracking
  research-raw.md     # Raw web search results (orchestrator-gathered)
  research.md         # Synthesized research with confidence tags
  map-raw.md          # Raw codebase snapshot (orchestrator-gathered)
  plan.md             # Verified atomic tasks with dependency waves
  debug.md            # DEBUG: reproduction, hypothesis log, root cause, fix verification
  review.md           # REVIEW: code-review findings by severity, resolution status
  experiments.md      # Full experiment journal across sessions
  map-tech.md         # Stack analysis
  map-architecture.md # Architecture patterns
  map-quality.md      # Test coverage, CI/CD, conventions
  map-concerns.md     # Tech debt, security, performance
  chart-specs.json    # ILLUSTRATE: chart data and type specifications
  charts/             # ILLUSTRATE: generated PNG charts (150 DPI)
```

This survives context resets. When `/super` is invoked, it reads `state.json` and resumes from where the previous session left off — skipping capabilities whose artifacts are still fresh.

### Incremental map caching

Maps are tagged with the git SHA at time of creation. On next run:

| What changed since last map | What happens |
|---|---|
| Nothing | MAP skipped entirely |
| <10 files, no new deps | Partial re-map (only affected agents) |
| >10 files or new deps | Full re-map |
| Maps >7 days old | Full re-map |

## Built on giants

`/super` combines proven patterns from:

- [GSD](https://github.com/gsd-build/get-shit-done) — Context-engineered development (planning backbone, codebase mapping, research protocol, debugging, code review)
- [superpowers](https://github.com/obra/superpowers) — Systematic debugging, TDD discipline, code review, git worktrees, verification-before-completion
- [ruflo](https://github.com/ruvnet/ruflo) — Optional layer: swarm topologies + Monitor (ORCHESTRATE), RAG memory (cross-session recall)
- [AutoResearch](https://github.com/karpathy/autoresearch) — Autonomous experiment loops with scientific rigor
- [OpenSpace](https://github.com/HKUDS/OpenSpace) — Self-evolving strategy with quality monitoring
- [CLI-Anything](https://github.com/HKUDS/CLI-Anything) — Multi-phase build pipelines
- [Claude Peers MCP](https://github.com/louislva/claude-peers-mcp) — Multi-agent coordination
- [Google Workspace CLI](https://github.com/googleworkspace/cli) — Schema-driven output patterns

## Changelog

### v2.3.2

- **Fix: Codex skill/prompt now installed as real copies, not symlinks.** Codex's skill and prompt scanner only accepts regular files and silently skips symlinks, so the v2.3.0–2.3.1 symlinked skill and `/super` prompt were never loaded (`/super` showed "Unrecognized command"). `install-codex.sh` now copies the files (re-copied on every `/super update`, so they stay current). Restart Codex after updating.

### v2.3.1

- **Codex `/super` slash-command shim** — `install-codex.sh` now also symlinks a thin `~/.codex/prompts/super.md` that activates the super skill on the supplied request (`$ARGUMENTS`), giving Codex an explicit `/super` command alongside skill auto-activation. (Codex marks custom prompts deprecated in favor of skills, so the skill remains the primary path; this is belt-and-suspenders.)

### v2.3.0

- **Codex support (CLI + desktop app)** — `/super` now works in OpenAI Codex too. `install-codex.sh` symlinks the super `SKILL.md` into `~/.codex/skills/super` (Codex auto-discovers it; the symlink means `/super update` keeps it current) and injects a managed precedence primer into `~/.codex/AGENTS.md` so Codex treats `/super` as the preferred top-level router at session start. Idempotent; no-op when Codex isn't installed. Wired into both `install.sh` and `/super update`. (Cloud Codex tasks read a repo's own `AGENTS.md`, so add the primer per-repo for cloud runs.)

### v2.2.1

- **Startup precedence** — The SessionStart primer now explicitly asserts precedence over the superpowers `using-superpowers` startup message for task routing: `/super` is the top-level router, consulted first, and it delegates *to* the superpowers skills (TDD, code-review, debugging, worktrees, verification) rather than competing with them. Order of authority: user instructions > /super primer > superpowers > defaults.
- **`/super update` re-registers hooks** — Update now runs the shared `install-hooks.sh` after `git pull`, so newly added hooks (and their `settings.json` entries) activate without a full re-install. A plain `/super update` now suffices going forward.
- **Shared `install-hooks.sh`** — Hook symlinking + idempotent `settings.json` registration extracted into one reusable script used by both `install.sh` and `/super update`.

### v2.2.0

- **Startup primer** — A `SessionStart` hook (`super-session-start.js`) now injects a short primer at the start of every session (startup / clear / compact) so Claude knows `/super` is the preferred entry point and router for non-trivial work — without dumping the full (large) SKILL.md into context. `/super` classifies the task and hands the real work to the right specialist skills (GSD, superpowers, ruflo-swarm). Registered via `settings.json` (the path that fires for symlink installs) and mirrored in the bundled `hooks/hooks.json` for true-plugin installs.
- **Install one-liner** — Switched to the portable `curl -fsSL … | bash` form (works under `sh`/`dash`, not just bash/zsh process substitution).
- **Idempotent hook registration** — `install.sh` now adds only the hook entries that are missing (per-hook check) instead of skipping all registration when one already exists, so updates pick up new hooks. Hook commands use absolute `$HOME` paths.

### v2.1.0

- **DEBUG capability** — Systematic, hypothesis-driven root-cause investigation with state persisted to `.super/debug.md` (survives context resets). From superpowers (systematic-debugging) + GSD (gsd-debug). New `debug` option; plan guard suppressed during pure debug.
- **Review gate** — Adversarial code review in a fresh context after BUILD's Refine phase; severity-tagged findings (`must-fix` / `should-fix` / `nice-to-have`) in `.super/review.md`; all must-fixes resolved before Deliver. From superpowers (requesting/receiving-code-review) + GSD (gsd-code-review). Skip with `no-review`.
- **TDD mode** — `tdd` option enforces red → green → refactor in BUILD. From superpowers (test-driven-development) + GSD opt-in `tdd_mode`. Disable with `no-tdd`.
- **Worktree isolation** — Parallel/orchestrated agents that write files each run in their own git worktree, merged back at the end. From superpowers (using-git-worktrees) + GSD worktree isolation. `worktrees` / `no-worktrees`.
- **Verification before completion** — BUILD's Deliver gate now requires actually running the artifact and observing it work, not just "tests pass." From superpowers (verification-before-completion) + GSD (gsd-verify-work).
- **ruflo integration (active when installed)** — When the ruflo suite is detected, ORCHESTRATE uses **ruflo-swarm** by default (topologies + live Monitor + anti-drift), and cross-session resume uses **ruflo-rag-memory** for semantic recall of past `.super/` artifacts. Both fall back silently to native behavior when ruflo is absent; ruflo-sparc is intentionally not adopted (overlaps /super's native PLAN → BUILD pipeline).
- Hooks updated to 1.2.0: plan guard also skips DEBUG mode; research tracker tracks and validates `debug.md` and `review.md`.

### v2.0.0

- **`illustrate` option** — Generates publication-quality charts from report data tables using matplotlib (headless). Horizontal bar charts, vertical bar charts, heatmaps, multi-line decay curves. Consistent institutional color scheme. Saved as PNGs to `.super/charts/`, embedded in PDFs.

### v1.9.0

- **Universal `/refresh`** — Rewritten to work in any git repo, not just the super plugin. Auto-detects project type (Node, Python, Rust, Go, Ruby, Claude plugin), runs the right test suite, bumps version in the right manifest, updates the right changelog, handles symlinks for plugins, and creates zip backups if previous ones exist.

### v1.8.0

- **`/refresh` skill** — One-command publish workflow for the super plugin.

### v1.7.0

- **Two-phase MAP** — Orchestrator snapshots the codebase (package manifest, directory tree, entry points, configs, CI/CD, tests, git history) in one parallel batch, then dispatches 4 analysis agents with the full snapshot. Eliminates duplicated file reads, gives every analyst the same complete picture.

### v1.6.0

- **Two-phase research** — Orchestrator gathers data via parallel web searches, then dispatches 4 analysis agents with pre-fetched results. Tested head-to-head: produced 2x the sources, domain-specific analyst notes, cross-reference quality checks, and insights (like data discrepancies and strategic framings) that single-phase research missed.

### v1.5.0

- **Self-update** — `/super update` checks GitHub for newer versions and updates in place
- **Simplified syntax** — All options are plain words (`research`, `no-map`, `loops=5`, `dry`, `clean`). No `+`, `-`, or `--` prefixes.
- **Execution plan & confirmation** — Shows step-by-step plan and waits for user OK before starting.
- **Loop control** — `loops=N` to set iteration limits. Defaults: research 2, plan verify 2, experiments 3.
- **Diminishing returns** — All loops auto-stop when <10% new value per iteration.
- **Safety cap** — `loops=` over 100 pauses and asks to confirm.
- **SIMPLE fast path** — Trivial tasks skip the full pipeline and confirmation gate.
- **Incremental map caching** — Git SHA staleness detection with partial re-mapping.
- **Experiment continuity** — Baselines and results persist across sessions.
- **Cleanup** — `/super clean` to archive or delete `.super/` artifacts.
- **Dry run** — `/super dry` previews routing without executing.
- **Streaming progress** — `[CAPABILITY N/M]` status lines during long-running work.

### v1.0.0

- Initial release: 7 capabilities, autonomous routing, artifact persistence, enforcement hooks

## License

MIT
