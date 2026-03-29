# Super - Autonomous Task Engine for Claude Code

A Claude Code plugin that autonomously routes tasks to the right combination of research, planning, building, experimentation, orchestration, and codebase mapping. Handles everything from one-line typo fixes to multi-service architecture overhauls.

## Install

### Option A: One-liner (recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/aifunmobi/super-plugin/master/install.sh)
```

This clones the repo into your Claude Code plugins directory and enables it automatically.

### Option B: Manual clone

```bash
git clone https://github.com/aifunmobi/super-plugin.git \
  ~/.claude/plugins/marketplaces/local/plugins/super
```

### Option C: From Claude Code

```bash
# In Claude Code, run:
/install-plugin https://github.com/aifunmobi/super-plugin
```

Then enable with `/plugins` or add to settings.json:

```json
{
  "enabledPlugins": {
    "super@local": true
  }
}
```

## Usage

Just say `/super` followed by what you want:

```
/super Add authentication to this Express app
/super What's the best database for our use case?
/super Make the /api/search endpoint faster
/super Fix the typo in utils.ts
```

The skill reads your request, checks complexity, and activates the right capabilities automatically.

### Capabilities

| Capability | Activated When |
|------------|----------------|
| **SIMPLE** | Trivial tasks: typos, renames, config changes, one-liners |
| **PLAN** | Always, for any non-trivial code task (GSD backbone) |
| **RESEARCH** | Unknowns, comparisons, "which/what/how" |
| **MAP** | Existing codebase being modified (with incremental caching) |
| **BUILD** | Creating or modifying code |
| **EXPERIMENT** | Optimizing, "make faster", comparing |
| **GENERATE-CLI** | Wrapping APIs or tools |
| **ORCHESTRATE** | 2+ independent tasks |

### SIMPLE mode

For trivial changes, `/super` skips the full pipeline and just does the work:

```
/super Fix the typo in README.md
  -> Activating: SIMPLE (trivial change, skipping full pipeline)
```

SIMPLE activates automatically when the task affects 1-2 files, is mechanical (not architectural), has no unknowns, and has no dependencies between changes. Examples: typo fixes, renames, config value changes, toggling flags, adding imports.

### Capability overrides

Force capabilities on or off with `+`/`-` flags:

```
/super +research "add caching to the API"     # Force research even if router wouldn't
/super -map "add a utility function"           # Skip mapping, you know the codebase
/super +experiment -research "try inlining"    # Force experiment, skip research
/super +simple "just add the import"           # Force simple mode for borderline tasks
```

**Rules:**
- Overrides are parsed before routing and always win over the router's judgment
- Valid names: `simple`, `plan`, `research`, `map`, `build`, `experiment`, `generate-cli`, `orchestrate`
- Multiple overrides can be combined in one invocation

### Incremental map caching

MAP results are cached in `.super/` with the git SHA at the time of mapping. On subsequent runs, `/super` checks what changed since the last map:

| What changed | What happens |
|---|---|
| Nothing (0 files) | MAP skipped entirely, cached maps reused |
| <10 files, no new deps | Partial MAP — only affected agents re-run |
| >10 files or new deps/config | Full MAP (all 4 agents) |
| Maps older than 7 days | Full MAP regardless of diff |

This saves significant time on repeated `/super` invocations in the same project.

### Cleanup

Remove stale `.super/` artifacts when you're done with a task:

```
/super clean
```

Shows a summary of what's in `.super/` (artifact count, size, age), then asks whether to **archive** (backup to `.super.bak.<timestamp>/`) or **delete**. If your `.super/` directory is >30 days old, `/super` will proactively suggest cleanup on next invocation.

### Dry run

Preview which capabilities would activate without executing anything:

```
/super --dry-run "add caching to the API"
```

Shows each capability with yes/no, the activation order, map cache status, and suggests useful overrides. No artifacts are written.

### Progress updates

During long-running capabilities, `/super` emits structured single-line status updates:

```
[RESEARCH 2/4] Architecture researcher complete — recommends event-driven pattern
[MAP skip] Reusing cached maps (0 files changed since abc123)
[BUILD 3/7] Implement phase complete — 4 files written, compiles clean
[EXPERIMENT 2/5] Hypothesis "inline queries" — 15% faster, keeping
```

### Experiment continuity

Experiments persist across sessions. If you run `/super` to optimize something, leave, and come back later, it picks up where you left off — reusing the baseline (if the code hasn't changed), continuing the experiment numbering, and avoiding hypotheses that were already discarded.

## Enforcement Hooks

The plugin registers two hooks automatically:

- **super-plan-guard** (PreToolUse): Warns if editing source code without a plan. Automatically suppressed in SIMPLE mode.
- **super-research-tracker** (PostToolUse): Tracks artifacts to `.super/`, validates quality, records git SHA for map staleness detection.

## Artifacts

All work persists to `.super/` in your project directory:

```
.super/
  state.json          # Session state, map cache metadata, capabilities log
  research.md         # Research findings with confidence tags
  plan.md             # Verified atomic tasks with waves
  experiments.md      # Hypothesis log with results
  map-*.md            # Codebase analysis (tech, architecture, quality, concerns)
```

### state.json schema

```json
{
  "session_start": "2026-03-28T...",
  "last_updated": "2026-03-28T...",
  "capabilities_activated": ["MAP", "PLAN", "BUILD"],
  "simple_mode": false,
  "artifacts": {
    "map-tech.md": { "written": "...", "size_bytes": 1234 },
    "plan.md": { "written": "...", "size_bytes": 5678 }
  },
  "map_metadata": {
    "git_sha": "abc123...",
    "timestamp": "2026-03-28T...",
    "partial": false,
    "agents_run": ["tech", "architecture", "quality", "concerns"]
  },
  "experiment_metadata": {
    "experiment_count": 3,
    "last_updated": "2026-03-28T...",
    "git_sha": "def456..."
  }
}
```

## Origin

Built by combining patterns from:
- [AutoResearch](https://github.com/karpathy/autoresearch) - autonomous experiment loops
- [OpenSpace](https://github.com/HKUDS/OpenSpace) - self-evolving strategy
- [CLI-Anything](https://github.com/HKUDS/CLI-Anything) - multi-phase pipelines
- [Claude Peers MCP](https://github.com/louislva/claude-peers-mcp) - multi-agent coordination
- [Google Workspace CLI](https://github.com/googleworkspace/cli) - schema-driven output
- [GSD](https://github.com/gsd-build/get-shit-done) - context-engineered development

## Changelog

### v1.2.0

- **Cleanup command** — `/super clean` to archive or delete `.super/` artifacts, with proactive staleness suggestions
- **Dry-run mode** — `/super --dry-run` previews routing decisions without executing
- **Streaming progress** — Structured `[CAPABILITY N/M]` status lines during long-running work
- **Experiment continuity** — Baselines, hypotheses, and results persist across sessions; experiments resume instead of restarting

### v1.1.0

- **SIMPLE fast path** — Trivial tasks skip the full pipeline (no MAP/RESEARCH/PLAN overhead)
- **Capability overrides** — `+capability`/`-capability` flags let you force or suppress routing decisions
- **Incremental map caching** — MAP results cached with git SHA; only re-maps when the codebase actually changed

### v1.0.0

- Initial release with 7 capabilities, autonomous routing, artifact persistence, and enforcement hooks

## License

MIT
