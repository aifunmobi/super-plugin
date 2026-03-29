# Super - Autonomous Task Engine for Claude Code

A Claude Code plugin that autonomously routes tasks to the right combination of research, planning, building, experimentation, orchestration, and codebase mapping.

## Install

### Option A: From GitHub (recommended)

```bash
# In Claude Code, run:
/install-plugin https://github.com/YOUR_USERNAME/super-plugin
```

### Option B: Local install

```bash
# Copy to your plugins directory
cp -r super-plugin ~/.claude/plugins/marketplaces/local/plugins/super

# Or symlink for development
ln -s "$(pwd)/super-plugin" ~/.claude/plugins/marketplaces/local/plugins/super
```

Then enable in Claude Code with `/plugins` or add to settings.json:

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
/super Audit security across all 5 services
```

The skill reads your request and activates the right capabilities automatically:

| Capability | Activated When |
|------------|----------------|
| **PLAN** | Always, for any code task (GSD backbone) |
| **RESEARCH** | Unknowns, comparisons, "which/what/how" |
| **MAP** | Existing codebase being modified |
| **BUILD** | Creating or modifying code |
| **EXPERIMENT** | Optimizing, "make faster", comparing |
| **GENERATE-CLI** | Wrapping APIs or tools |
| **ORCHESTRATE** | 2+ independent tasks |

## Enforcement Hooks

The plugin registers two hooks automatically:

- **super-plan-guard** (PreToolUse): Warns if editing source code without a plan
- **super-research-tracker** (PostToolUse): Tracks artifacts to `.super/`, validates quality

## Artifacts

All work persists to `.super/` in your project directory:

```
.super/
  state.json          # What's been done (auto-maintained by hook)
  research.md         # Research findings with confidence tags
  plan.md             # Verified atomic tasks with waves
  experiments.md      # Hypothesis log with results
  map-*.md            # Codebase analysis (tech, architecture, quality, concerns)
```

## Origin

Built by combining patterns from:
- [AutoResearch](https://github.com/karpathy/autoresearch) - autonomous experiment loops
- [OpenSpace](https://github.com/HKUDS/OpenSpace) - self-evolving strategy
- [CLI-Anything](https://github.com/HKUDS/CLI-Anything) - multi-phase pipelines
- [Claude Peers MCP](https://github.com/louislva/claude-peers-mcp) - multi-agent coordination
- [Google Workspace CLI](https://github.com/googleworkspace/cli) - schema-driven output
- [GSD](https://github.com/gsd-build/get-shit-done) - context-engineered development

## License

MIT
