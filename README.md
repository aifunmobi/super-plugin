# /super — The Only Slash Command You Need

**Stop micromanaging your AI.** Just say `/super` and describe what you want. The plugin figures out the rest — whether it's a one-line typo fix or a full-stack feature spanning multiple services.

`/super` is an autonomous task engine for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that combines **research, planning, codebase mapping, building, experimentation, orchestration, and CLI generation** into a single command. It reads your request, classifies the complexity, and activates exactly the right combination of capabilities — no sub-commands to memorize, no manual workflow to follow.

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
| Claude jumps straight to coding without thinking | **Plan guard** — enforces research and planning before any code is written |
| Codebase gets re-analyzed every session | **Incremental map caching** — only re-maps what actually changed (git SHA tracking) |
| You forget which approach you already tried | **Experiment continuity** — baselines, hypotheses, and results persist across sessions |
| Simple tasks get buried in ceremony | **SIMPLE fast path** — typo fixes and config changes skip the full pipeline |
| The router picks wrong capabilities | **Options** — `research`, `no-map`, `loops=5` to control exactly what runs |
| Long tasks feel like a black box | **Streaming progress** — structured status updates at every milestone |
| You don't know what it's about to do | **Execution plan** — shows exactly what will happen and waits for your OK |
| Stale artifacts pile up | **Cleanup** — `/super clean` to archive or remove old work |

## Quick start

```bash
bash <(curl -s https://raw.githubusercontent.com/aifunmobi/super-plugin/main/install.sh)
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

## 8 Capabilities

`/super` has 8 capabilities that combine automatically based on your request.

### SIMPLE — Just do it

For trivial, unambiguous changes. Skips the entire pipeline and the confirmation gate.

```
/super Rename getUserData to fetchUserData
  -> Activating: SIMPLE (trivial change, skipping full pipeline)
```

Triggers on: typo fixes, renames, config value changes, toggling flags, adding imports, one-liners with no design decisions.

### PLAN — No code without a verified plan

The backbone. Every non-trivial task goes through **discuss gray areas -> create atomic tasks -> verify coverage -> execute in waves**. Tasks are grouped into dependency waves and executed with fresh agent contexts. Each completed task produces an atomic git commit.

### RESEARCH — Expert-grade investigation

Dispatches 4 parallel researchers (Stack, Architecture, Features, Pitfalls) that investigate your problem domain like senior engineers would. Produces confidence-tagged findings (`[HIGH]`/`[MEDIUM]`/`[LOW]`), a "don't hand-roll" list of things to use off-the-shelf, and a validation architecture for verifying the implementation.

### MAP — Understand before modifying

4 parallel agents analyze your existing codebase across tech stack, architecture patterns, code quality, and concerns. Results are **cached with git SHA tracking** — subsequent runs only re-map what actually changed, saving significant time.

### BUILD — Multi-phase pipeline with quality gates

7 phases: Analyze, Design, Implement, Test, Refine, Document, Deliver. Three layers of quality monitoring (task, integration, goal). Each phase has a gate that must pass before proceeding.

### EXPERIMENT — Scientific iteration

Measures a baseline, forms hypotheses, implements changes, measures again, keeps or discards. One variable at a time. **Results persist across sessions** — come back tomorrow and it picks up at Experiment #4 instead of re-measuring the baseline.

### GENERATE-CLI — Schema-driven tool creation

Reads your API schema (OpenAPI, GraphQL, Discovery docs) or source code and generates a complete CLI with `--help`, `--json` output, and consistent exit codes.

### ORCHESTRATE — Parallel fan-out

For 2+ independent tasks. Decomposes the work, dispatches one agent per task (each with its own MAP/PLAN/BUILD internally), collects results, and synthesizes.

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

- **super-plan-guard** (PreToolUse) — Warns if source code is being edited without a plan. Suppressed in SIMPLE mode.
- **super-research-tracker** (PostToolUse) — Tracks every artifact write, updates session state, validates that research has confidence tags, plans have verification criteria, and experiments have baselines.

### Artifact persistence

All work lives in `.super/` in your project directory:

```
.super/
  state.json          # Session state, map cache, experiment tracking
  research.md         # Research findings with confidence tags
  plan.md             # Verified atomic tasks with dependency waves
  experiments.md      # Full experiment journal across sessions
  map-tech.md         # Stack analysis
  map-architecture.md # Architecture patterns
  map-quality.md      # Test coverage, CI/CD, conventions
  map-concerns.md     # Tech debt, security, performance
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

- [GSD](https://github.com/gsd-build/get-shit-done) — Context-engineered development (planning backbone, codebase mapping, research protocol)
- [AutoResearch](https://github.com/karpathy/autoresearch) — Autonomous experiment loops with scientific rigor
- [OpenSpace](https://github.com/HKUDS/OpenSpace) — Self-evolving strategy with quality monitoring
- [CLI-Anything](https://github.com/HKUDS/CLI-Anything) — Multi-phase build pipelines
- [Claude Peers MCP](https://github.com/louislva/claude-peers-mcp) — Multi-agent coordination
- [Google Workspace CLI](https://github.com/googleworkspace/cli) — Schema-driven output patterns

## Changelog

### v1.5.0

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
