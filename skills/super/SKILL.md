---
name: super
description: Use when tackling any task from trivial to ambitious - autonomously classifies complexity, supports +/- capability overrides, caches map results incrementally, and activates the right combination of research, planning, building, experimentation, orchestration, and codebase mapping sub-skills without requiring explicit sub-commands
---

# Super - Autonomous Task Engine

When `/super` is invoked (or this skill activates), **do not ask which sub-command to use.** Analyze the user's request and autonomously activate the right combination of capabilities. The GSD planning backbone (discuss -> plan -> verify) is always active for any task that involves writing code or making changes.

## Meta-Commands

These are recognized before routing. They control the `/super` session itself rather than performing a task.

### `/super clean`

Archives or removes the `.super/` directory for the current project.

**Behavior:**
1. If `.super/` doesn't exist, say so and exit
2. Show a summary of what's in `.super/` (artifact count, total size, age)
3. Ask the user to confirm: **archive** (move to `.super.bak.<timestamp>/`) or **delete** (remove entirely)
4. Execute the chosen action
5. If archiving, mention the backup path so the user can recover if needed

**Auto-clean:** If `.super/state.json` shows all capabilities completed and the last update was >30 days ago, suggest cleanup proactively when `/super` is next invoked.

### `/super --dry-run <task>`

Shows which capabilities the router would activate — without executing anything.

**Output format:**
```
Dry run: "Add caching to the API"

Router decision:
  SIMPLE:       no  (task involves architectural decisions)
  MAP:          yes (existing codebase detected)
  RESEARCH:     no  (no unknowns — caching approach is well-known)
  PLAN:         yes (always on for code tasks)
  BUILD:        yes (creating/modifying code)
  EXPERIMENT:   no  (not optimizing)
  GENERATE-CLI: no  (not wrapping an API)
  ORCHESTRATE:  no  (single task)

Activation order: MAP -> PLAN -> BUILD

Map cache: fresh (2 files changed since last map, partial re-map of Tech only)

Override suggestion: Use +research if you want to compare caching strategies first
```

**Rules:**
- No artifacts are written, no `.super/` directory is created
- If `+`/`-` overrides are included, show the router's base decision AND the final decision after overrides
- If `--loops N` is included, show the loop configuration for each active capability
- Include map cache status if `.super/state.json` exists

## Autonomous Router

```dot
digraph router {
  rankdir=TB;
  node [shape=box];

  "User request arrives" [shape=ellipse];
  "Parse overrides" [shape=box];
  "Complexity check" [shape=diamond];
  "Classify task signals" [shape=diamond];

  "User request arrives" -> "Parse overrides";
  "Parse overrides" -> "Complexity check";

  "Complexity check" -> "SIMPLE (just do it)" [label="trivial"];
  "Complexity check" -> "Classify task signals" [label="non-trivial"];

  "Classify task signals" -> "PLAN (always for code tasks)";
  "Classify task signals" -> "RESEARCH (if unknowns exist)";
  "Classify task signals" -> "MAP (if existing codebase)";
  "Classify task signals" -> "BUILD (if creating/modifying code)";
  "Classify task signals" -> "EXPERIMENT (if optimizing/comparing)";
  "Classify task signals" -> "GENERATE-CLI (if wrapping API/tool)";
  "Classify task signals" -> "ORCHESTRATE (if independent subtasks)";
}
```

### Step 0: Parse Capability Overrides

Before classifying, check if the user included `+capability` or `-capability` flags in their request. These override the router's decisions.

**Syntax:** `/super [--loops N] [+cap ...] [-cap ...] "task description"`

| Flag | Effect |
|------|--------|
| `--loops N` | Set max iterations for all loops (research re-research, plan verify, experiment hypotheses) |
| `--loops 0` | Single-pass mode: no re-research, no plan re-verify, one experiment only |
| `+research` | Force RESEARCH on, even if the router wouldn't activate it |
| `-map` | Force MAP off, even if the router would activate it |
| `+experiment -research` | Force EXPERIMENT on, force RESEARCH off |
| `+simple` | Force SIMPLE mode (skip all heavyweight capabilities) |
| `-simple` | Force full routing even for trivial-looking tasks |

**Loop defaults (when `--loops` is not specified):**

| Loop type | Default max | Applies to |
|-----------|-------------|------------|
| Research re-research | 2 | RESEARCH gap-filling iterations |
| Plan verification | 2 | PLAN revision loops before escalating to user |
| Experiment hypotheses | 3 | EXPERIMENT iterations per session |

When `--loops N` is provided, all loop types use N as their max.

**Loop safety cap:** If the user specifies `--loops` with a value over 100, stop at 100 iterations and ask the user if they want to continue. This prevents runaway token consumption.

**Rules:**
1. Parse `--loops N` first if present (N must be a non-negative integer)
2. Parse all `+`/`-` prefixed words (case-insensitive) before the task description
3. Valid capability names: `simple`, `plan`, `research`, `map`, `build`, `experiment`, `generate-cli`, `orchestrate`
4. Invalid names are ignored with a warning to the user
5. User overrides are applied AFTER the router classifies the task — they always win
6. Announce overrides and loop setting: `"User override: +research, -map | Loops: 5"`

### Step 1: Complexity Check (SIMPLE Fast Path)

Before full classification, check if the task is trivial. **SIMPLE mode skips PLAN, RESEARCH, and MAP entirely** — just do the work and commit.

**SIMPLE activates when ALL of these are true:**
- Task affects 1-2 files at most
- Change is mechanical, not architectural (no design decisions)
- No unknowns — the user stated exactly what to do
- No dependencies between changes

**SIMPLE signal words/patterns:**
- "fix typo", "rename X to Y", "change X to Y", "update version", "remove unused"
- "s/old/new/", regex-style substitution requests
- Single-line or few-line changes with no ambiguity
- Config value changes ("set timeout to 30s", "change port to 8080")
- Import/dependency additions ("add lodash", "install X")
- Toggling flags, booleans, feature switches

**SIMPLE does NOT activate when:**
- The task says "refactor", "redesign", "migrate", "add feature"
- Multiple files need coordinated changes
- The user asks a question ("should we...", "what's the best...")
- There are unknowns or alternatives to evaluate
- The change touches tests, CI, or infrastructure

**When SIMPLE is active:**
1. Skip MAP, RESEARCH, PLAN — go straight to execution
2. The plan guard hook is suppressed (no warning for missing plan.md)
3. Make the change directly
4. Commit: `fix(super-simple): description`
5. Write a one-line entry to `.super/state.json` logging the simple task

**Announce:** `Activating: SIMPLE (trivial change, skipping full pipeline)`

### Step 2: Classification Rules

Read the user's request and activate capabilities based on these signals. **Multiple capabilities activate together** -- this is not pick-one. Apply any user overrides from Step 0 after classification.

| Signal in the request | Activates | Why |
|----------------------|-----------|-----|
| Any task involving code changes | **PLAN** (always) | GSD backbone: discuss gray areas, create verified atomic tasks, wave-based execution |
| Unknowns, options to evaluate, "which/what/how should we" | **RESEARCH** | Need information before committing to an approach |
| Working in an existing codebase the agent hasn't mapped | **MAP** | Must understand what exists before modifying it |
| Creating features, fixing bugs, building systems | **BUILD** | Multi-phase pipeline with quality gates |
| "Faster", "optimize", "improve", "try different approaches" | **EXPERIMENT** | Scientific iteration loop with keep/discard tracking |
| "Wrap this API", "make a CLI for", "scriptable interface" | **GENERATE-CLI** | Auto-generate CLI from schema/source |
| 2+ independent tasks, "audit all", "do X for each" | **ORCHESTRATE** | Parallel agent fan-out |

### Typical Combinations

| User says | What activates | Flow |
|-----------|---------------|------|
| "Fix the typo in README.md" | **SIMPLE** | Direct fix, no pipeline |
| "Rename getUserData to fetchUserData" | **SIMPLE** | Direct rename, commit |
| "Change the timeout from 30s to 60s" | **SIMPLE** | Direct config change |
| "Add user authentication to this app" | MAP -> PLAN -> BUILD | Map codebase, plan with gray-area discussion, build through phases |
| "What's the best database for our use case?" | RESEARCH | Iterative research with parallel agents |
| "Build a notification system" | MAP -> RESEARCH -> PLAN -> BUILD | Map existing code, research approaches, plan, then build |
| "Make this endpoint faster" | MAP -> PLAN -> EXPERIMENT | Map context, plan approach, iterate with measurements |
| "Audit security across all 5 services" | ORCHESTRATE (with MAP per service) | Parallel fan-out, each agent maps + audits its service |
| "Create a CLI for our internal API" | PLAN -> GENERATE-CLI | Plan the interface, then generate it |
| "Refactor the billing module to use events" | MAP -> RESEARCH -> PLAN -> BUILD | Full pipeline: understand, research patterns, plan, execute |
| "Compare CRDT vs OT for our editor" | RESEARCH -> PLAN | Research both, then plan the chosen approach |
| `/super +research "add caching"` | MAP -> RESEARCH -> PLAN -> BUILD | User forced RESEARCH even though router might skip it |
| `/super -map "add a util function"` | PLAN -> BUILD | User suppressed MAP — knows the codebase already |
| `/super +simple "add the import"` | **SIMPLE** | User forced simple mode for a borderline task |

### When in doubt

- If the task is trivial and unambiguous: **SIMPLE** — just do it.
- If the task changes code and isn't trivial: **PLAN is always on.** No code without a verified plan.
- If there's an existing codebase: **MAP first** (unless already mapped this session or maps are fresh).
- If you're unsure about the right approach: **RESEARCH before PLAN.**
- If there are independent subtasks: **ORCHESTRATE** wraps the other capabilities.
- If the user provided `+`/`-` overrides: **those always win** over the router's judgment.

### Announce what you're activating

Before starting work, briefly tell the user which capabilities you're activating and why. Include any user overrides.

```
Activating: MAP -> RESEARCH -> PLAN -> BUILD
User override: +research (forced on)
- MAP: This is an existing Next.js project, need to understand patterns first
- RESEARCH: Event-driven architecture has multiple approaches worth comparing (user requested)
- PLAN: Will create verified atomic tasks before coding
- BUILD: Multi-phase implementation with quality gates
```

For simple tasks:
```
Activating: SIMPLE (trivial change, skipping full pipeline)
```

---

## Artifact Persistence (.super/ directory)

All `/super` work is persisted to a `.super/` directory in the working directory. This survives context resets and enables resume across sessions.

### Directory Structure

```
.super/
  state.json          # Auto-maintained: capabilities, timestamps, map cache metadata, simple log
  research.md         # RESEARCH output: stack, architecture, features, pitfalls, don't-hand-roll
  plan.md             # PLAN output: atomic tasks with waves, verification criteria, dependencies
  experiments.md      # EXPERIMENT output: baseline, hypothesis log, results table
  map-tech.md         # MAP output: stack analysis
  map-architecture.md # MAP output: architecture analysis
  map-quality.md      # MAP output: quality analysis
  map-concerns.md     # MAP output: concerns analysis
```

### When to Write Artifacts

- **Always write** research, plan, and map outputs to `.super/` files
- **Always write** experiment logs as they progress
- The `super-research-tracker` hook automatically updates `state.json` when artifacts are written
- The `super-plan-guard` hook warns if source code is being edited without `.super/plan.md` existing

### Resuming Across Sessions

When `/super` activates, check for existing `.super/` directory:
1. If `state.json` exists, read it to understand what was already done
2. For MAP artifacts, run staleness detection (see MAP section) — don't blindly reuse stale maps
3. Skip other capabilities whose artifacts already exist (e.g., don't re-RESEARCH if `research.md` exists and the task hasn't changed)
4. Resume from where the previous session left off

### Enforcement Hooks (registered in settings.json)

| Hook | Event | What It Enforces |
|------|-------|-----------------|
| `super-plan-guard.js` | PreToolUse (Write/Edit) | Warns if editing source code without `.super/plan.md` existing |
| `super-research-tracker.js` | PostToolUse (Write) | Tracks artifact writes, updates `state.json`, validates artifact quality |
| `gsd-context-monitor.js` | PostToolUse | Warns at 35%/25% remaining context (shared with GSD) |
| `gsd-prompt-guard.js` | PreToolUse | Scans for prompt injection in planning files (shared with GSD) |

### Artifact Quality Validation

The research tracker hook checks that artifacts contain expected markers:
- **research.md** must contain confidence tags (`[HIGH]`, `[MEDIUM]`, `[LOW]`)
- **plan.md** must contain `Verify:` and `Dependencies:` markers
- **experiments.md** must contain `Baseline` and `Hypothesis` markers

If markers are missing, an advisory warning is injected so the agent can fix the artifact.

---

## PLAN (GSD Backbone -- Always Active for Code Tasks)

**From: GSD (discuss -> plan -> verify -> execute with context freshness)**

This is the foundation. Every task that produces code goes through this cycle.

### Discuss: Surface Gray Areas

Before planning, identify decisions that affect implementation:
- **Visual features?** Ask about layout, responsive behavior, interactions
- **API work?** Ask about error handling, auth, rate limiting
- **Data model?** Ask about relationships, constraints, migration strategy
- Lock decisions into a context document so downstream work doesn't re-debate them
- If the user said `/super` with enough context that gray areas are obvious, surface them in a concise list rather than an extended Q&A

### Plan: Create Atomic Tasks

Each task specifies:
- **Name**: What this task accomplishes
- **Files**: Which files will be created or modified
- **Action**: Precise implementation steps
- **Verify**: How to confirm the task succeeded
- **Dependencies**: Which tasks must complete first

### Verify: Check Before Executing

Before writing any code, verify the plan against:
1. Every requirement has at least one task covering it
2. Tasks are atomic (one concern each, independently testable)
3. Dependencies correctly ordered (no circular, no missing)
4. Scope is achievable, not over-ambitious
5. No gaps between what was asked and what's planned

Default max 2 revision loops (override with `--loops N`). If it can't pass, escalate to user. Diminishing returns rule applies: if a revision produces <10% improvement in coverage, stop and escalate.

### Execute: Wave-Based with Fresh Contexts

Group tasks into dependency waves:
- **Wave 1**: All tasks with no dependencies (run in parallel)
- **Wave 2**: Tasks depending only on Wave 1 (parallel after Wave 1)
- Each task gets a fresh agent context (prevents context rot)
- Each completed task produces an atomic git commit: `feat(wave-task): description`

### Human Checkpoint

Pause after planning for user approval. Be autonomous during execution, but surface problems immediately rather than working around them silently.

---

## RESEARCH (Deep Domain Investigation)

**From: AutoResearch (autonomous loop) + OpenSpace (evolving strategy) + GSD (4-domain parallel research, expert modeling, pitfall-driven investigation)**

Activated when there are unknowns, options to evaluate, or decisions to inform. This is not a library lookup -- it's expert modeling: "how do experts build this?"

### Protocol

```dot
digraph research {
  rankdir=TB;
  "Capture user constraints" -> "Dispatch 4 parallel researchers";
  "Dispatch 4 parallel researchers" -> "Stack researcher";
  "Dispatch 4 parallel researchers" -> "Architecture researcher";
  "Dispatch 4 parallel researchers" -> "Features researcher";
  "Dispatch 4 parallel researchers" -> "Pitfalls researcher";
  "Stack researcher" -> "Synthesize findings";
  "Architecture researcher" -> "Synthesize findings";
  "Features researcher" -> "Synthesize findings";
  "Pitfalls researcher" -> "Synthesize findings";
  "Synthesize findings" -> "Quality gate: gaps?";
  "Quality gate: gaps?" -> "Evolve strategy + re-research" [label="gaps > 30%"];
  "Quality gate: gaps?" -> "Produce structured report" [label="sufficient"];
  "Evolve strategy + re-research" -> "Synthesize findings";
}
```

### Step 1: Capture Constraints

Before researching, lock what's already decided:
- **User decisions** from the discuss phase are NON-NEGOTIABLE -- research works within them
- **Areas of discretion** where research can recommend freely
- **Out of scope** items to ignore

### Step 2: Parallel 4-Domain Research

Dispatch 4 parallel agents, each investigating one domain:

| Agent | Investigates | Produces |
|-------|-------------|----------|
| **Stack** | Libraries, frameworks, versions, alternatives with tradeoffs, installation commands | Recommended stack with specific versions and "why standard" reasoning |
| **Architecture** | Project structure, named patterns with conditions, code examples from official sources, anti-patterns to avoid | Architecture recommendation with real code from authoritative sources |
| **Features** | What users expect (table stakes vs differentiators vs defer-to-v2), competitive landscape | Prioritized feature list: must-have, should-have, defer |
| **Pitfalls** | What goes wrong, root causes, prevention strategies, warning signs for early detection | Pitfall list with "how to avoid" AND "how to detect early" |

### Step 3: Don't Hand-Roll Analysis (from GSD)

A critical output of research. Explicitly identify problems that *look simple but aren't*:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| (looks simple) | (custom code) | (existing solution) | (edge cases you'd miss) |

This prevents custom implementations that introduce bugs and maintenance burden. Research identifies what experts DON'T build themselves.

### Step 4: Synthesize + Quality Gate

Merge findings across all 4 domains. Tag confidence per section:

| Confidence | Meaning | Source Type |
|------------|---------|-------------|
| `[HIGH]` | Verified with official sources, docs, or authoritative code | Primary: official docs, Context7 |
| `[MEDIUM]` | Multiple community sources agree | Secondary: verified web sources |
| `[LOW]` | Single source or inference, needs validation | Tertiary: needs validation during implementation |

If gaps > 30%, evolve strategy and loop (default max 2 iterations, or `--loops N` if set). Each iteration must reduce gaps or stop.

### Step 5: Validation Architecture

Research also produces HOW to verify the implementation succeeded:
- What tests prove the chosen approach works
- What metrics indicate success
- What warning signs indicate the approach is failing

This feeds directly into the PLAN's verification criteria.

### Output Structure

```markdown
## Research: <topic>

### User Constraints (locked)
- [decisions from discuss phase -- non-negotiable]

### Executive Summary
[2-3 paragraphs: what was researched, recommended approach, key risks]
**Primary recommendation:** [one-liner actionable guidance]

### Recommended Stack
| Technology | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
[Specific versions, not just names]

### Architecture Patterns
[Named patterns with conditions and code from official sources]
**Anti-patterns to avoid:** [with reasoning]

### Don't Hand-Roll
| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
[What experts DON'T build themselves]

### Feature Priorities
- **Must-have (table stakes):** [users expect this]
- **Should-have (competitive):** [differentiators]
- **Defer (v2+):** [not essential for launch]

### Critical Pitfalls
For each: what goes wrong, root cause, prevention, warning signs

### Validation Architecture
[How to verify the implementation succeeds]

### Confidence Assessment
| Area | Confidence | Notes |
|------|------------|-------|
[Per-section confidence so planner knows what needs extra validation]

### Open Questions
[Gaps that couldn't be resolved + how to handle during implementation]

### Sources
- **Primary (HIGH):** [official docs, authoritative]
- **Secondary (MEDIUM):** [community, multiple sources agree]
- **Tertiary (LOW):** [single source, needs validation]

### Strategy Evolution Log
[How research strategy adapted across iterations]
```

### Anti-Loop Guard

- Default max 2 iterations (override with `--loops N`)
- Each iteration must reduce gaps or the loop stops early
- **Diminishing returns rule:** If an iteration produces <10% new findings compared to the previous, stop immediately regardless of remaining iterations
- **Safety cap:** If `--loops` exceeds 100, pause at 100 and ask user to confirm before continuing

### Output feeds into PLAN

Research findings become input context for planning. Locked decisions carry forward. Don't-hand-roll list prevents the planner from reinventing solved problems. Pitfalls become verification criteria. Confidence gaps become areas needing extra testing.

---

## MAP (Brownfield Analysis)

**From: GSD (parallel codebase mappers)**

Activated when working in an existing codebase. Uses incremental caching to avoid redundant re-mapping.

### Staleness Detection (Incremental Map Reuse)

Before dispatching map agents, check if cached maps can be reused:

1. **Read `.super/state.json`** — check `map_metadata.git_sha` and `map_metadata.timestamp`
2. **Run `git diff --stat <cached_sha>..HEAD`** to see what changed since last map
3. **Apply staleness rules:**

| Condition | Action |
|-----------|--------|
| No cached maps exist | Full MAP (all 4 agents) |
| Cached maps exist, 0 files changed since cached SHA | **Skip MAP entirely** — reuse cached artifacts |
| Cached maps exist, <10 files changed, no new dependencies | **Partial MAP** — only re-run agents whose domain was affected (see domain rules below) |
| Cached maps exist, >10 files changed OR new deps/config | Full MAP (all 4 agents) — too much changed |
| Cached maps >7 days old | Full MAP regardless of diff — staleness ceiling |
| User passed `+map` override | Full MAP regardless of cache |
| User passed `-map` override | Skip MAP regardless of cache |

**Domain-to-file mapping for partial MAP:**

| Changed files match | Re-run agent |
|--------------------|--------------|
| `package.json`, `*.lock`, dependency configs | **Tech** |
| New directories, moved files, new entry points | **Architecture** |
| Test files, CI config, lint config | **Quality** |
| Security-sensitive files, perf-critical paths | **Concerns** |

4. **After mapping, update `state.json`:**
```json
{
  "map_metadata": {
    "git_sha": "<current HEAD sha>",
    "timestamp": "<ISO timestamp>",
    "partial": false,
    "agents_run": ["tech", "architecture", "quality", "concerns"]
  }
}
```

**Announce reuse:** `"MAP: Reusing cached maps (3 files changed since last map, none affect architecture)"`
**Announce partial:** `"MAP: Re-running Tech agent only (package.json changed, other maps still fresh)"`

### Protocol

Dispatch up to 4 parallel agents (or fewer for partial MAP):

| Agent | Focus |
|-------|-------|
| **Tech** | Stack, frameworks, dependencies, versions |
| **Architecture** | Directory structure, patterns, data flow |
| **Quality** | Test coverage, lint config, CI/CD, conventions |
| **Concerns** | Tech debt, security issues, performance risks |

### Output feeds into PLAN and BUILD

Map results inform planning (match existing patterns) and building (follow existing conventions). The rule: **respect what exists.** Match code style, use existing abstractions, understand the test strategy before writing tests differently.

---

## BUILD (Multi-Phase Pipeline)

**From: CLI-Anything (7-phase) + OpenSpace (quality monitoring)**

Activated when creating or modifying code. Always preceded by PLAN.

### Phases

| Phase | Deliverable | Gate |
|-------|-------------|------|
| 1. Analyze | Requirements + acceptance criteria | All requirements have criteria |
| 2. Design | Architecture decisions, interfaces | User confirms |
| 3. Implement | Working code, atomic commits | Compiles/runs clean |
| 4. Test | Test suite passing | Acceptance criteria covered |
| 5. Refine | Gap analysis: spec vs result | No gaps or gaps documented |
| 6. Document | Only if user requests | -- |
| 7. Deliver | Final summary | User confirms |

### Quality Monitoring (3 layers)

- **Task**: Is each task meeting its criteria?
- **Integration**: Do components work together?
- **Goal**: Does the whole thing solve the original problem?

Stop and fix if quality degrades at any layer.

### Iterative Refinement

After testing, run gap analysis: what was requested but not built? What edge cases were missed? What could be simplified? Each refinement cycle is additive and non-destructive.

---

## EXPERIMENT (Scientific Iteration)

**From: AutoResearch (autonomous loop with time budgets)**

Activated when optimizing, comparing approaches, or tuning performance.

### Session Continuity

Experiments persist across sessions via `.super/experiments.md`. When EXPERIMENT activates:

1. **Check for existing `.super/experiments.md`** — if it exists, read it first
2. **Load prior state:**
   - Last baseline measurement and how it was taken (command, metric, environment)
   - All previous hypotheses with their outcomes (kept/discarded/reset)
   - Current best result and which experiment produced it
   - Strategy evolution notes from prior sessions
3. **Resume, don't restart:**
   - If a baseline already exists and the code hasn't changed since, **reuse it** — don't re-measure
   - If prior experiments were discarded, don't re-try the same hypothesis unless conditions changed
   - Number experiments sequentially across sessions (e.g., if last session ended at Experiment #3, start at #4)
4. **Detect stale baselines:** If `git diff` shows changes to the measured code since the last baseline timestamp, re-measure the baseline before continuing

### experiments.md Format

```markdown
## Experiment Log: <optimization target>

### Baseline
- **Measured:** <timestamp>
- **Git SHA:** <sha>
- **Command:** `<how the measurement was taken>`
- **Result:** <metric value>
- **Environment:** <relevant env details>

### Experiment #1 — <hypothesis name>
- **Hypothesis:** <what we expect and why>
- **Implemented:** <timestamp> (commit <sha>)
- **Result:** <metric value> (<% change from baseline>)
- **Decision:** kept | discarded | reset
- **Notes:** <what we learned>

### Experiment #2 — ...

### Current Best
- **Result:** <best metric value>
- **From:** Experiment #<N>
- **Improvement over baseline:** <% or absolute>

### Strategy Notes
- <what approaches have been tried>
- <what to try next>
- <dead ends to avoid>
```

### Protocol

1. **Baseline** - Measure current state (or reuse existing if fresh)
2. **Hypothesize** - State expected change and why (check prior experiments to avoid repeats)
3. **Implement** - Make the change (git commit)
4. **Measure** - Same evaluation as baseline
5. **Decide**: Better = keep. Worse = reset. Crashed = reset + adjust.
6. **Loop** - Default max 3 experiments per session (override with `--loops N`). Reassess strategy if no improvement after 2 consecutive experiments.

### Constraints

- One hypothesis per experiment (never bundle)
- Simpler wins when results are comparable
- Track all attempts in a results log (including discarded ones)
- Never re-test a hypothesis that was already discarded unless conditions explicitly changed
- Always update `.super/experiments.md` after each experiment — this is the cross-session journal

---

## GENERATE-CLI (Tool Interface Creation)

**From: CLI-Anything + Google Workspace CLI (schema-driven)**

Activated when wrapping an API, codebase, or software in a CLI.

### Pipeline

1. **Discover** - Read schema (OpenAPI, GraphQL, Discovery docs) or source code
2. **Design** - Map to CLI commands grouped by resource. `+` prefix for convenience helpers. `--json` on everything.
3. **Implement** - Generate CLI (Click/Python or commander/Node). Self-describing via `--help`. Consistent exit codes.
4. **Test** - Run against real backend
5. **Document** - Auto-generate SKILL.md for agent discovery

### Principles

- Real backend, no reimplementation
- Dual output: human-readable default, `--json` for machines
- Schema-driven when schema exists

---

## ORCHESTRATE (Parallel Fan-Out)

**From: Claude Peers (multi-agent) + OpenSpace (quality monitoring)**

Activated when there are 2+ independent tasks. Wraps other capabilities -- each parallel agent can run its own MAP/PLAN/BUILD internally.

### Protocol

1. **Decompose** - Identify independent tasks (must not share state)
2. **Dispatch** - One agent per task with complete, self-contained prompt
3. **Collect** - Gather structured results
4. **Synthesize** - Deduplicate, resolve conflicts, identify gaps, score confidence
5. **Retry** - Failed agents get one retry with adjusted prompt; then report partial results

---

## Progress Updates (Streaming Status)

During long-running capabilities, emit structured progress updates so the user knows what's happening. These are short, inline status lines — not full reports.

### When to emit

Emit a progress line at each of these milestones:

| Capability | Milestones |
|------------|-----------|
| **RESEARCH** | After each of the 4 parallel agents completes; after synthesis; after each re-research loop |
| **MAP** | After staleness check result; after each agent completes (or is skipped); after merge |
| **PLAN** | After gray areas surfaced; after plan draft; after each verify loop; after user approval |
| **BUILD** | After each phase gate (Analyze, Design, Implement, Test, Refine, Deliver) |
| **EXPERIMENT** | After baseline; after each hypothesis result (keep/discard/reset) |
| **ORCHESTRATE** | After decomposition; after each agent completes; after synthesis |

### Format

Use a consistent single-line format with a capability tag:

```
[RESEARCH 2/4] Architecture researcher complete — recommends event-driven pattern
[MAP skip] Reusing cached maps (0 files changed since abc123)
[MAP 1/2] Tech agent complete (partial re-map)
[PLAN verify 1/3] Missing coverage for error handling — revising
[BUILD 3/7] Implement phase complete — 4 files written, compiles clean
[EXPERIMENT 2/5] Hypothesis "inline queries" — 15% faster, keeping
[ORCHESTRATE 3/5] Service-C audit complete, 2 findings
```

### Rules

- One line per milestone, no multi-paragraph updates mid-capability
- Include counts where applicable (agent N/total, phase N/total, loop N/max)
- Include the key outcome or finding in the line — not just "done"
- If a capability is skipped entirely (e.g., MAP reused from cache), emit one skip line
- Don't emit progress for SIMPLE mode — it's too fast to need it

---

## Cross-Cutting Principles (Always Active)

### Context Freshness (from GSD)
- Fresh agent context per substantial task (prevents rot)
- Materialize decisions into documents, not conversation history
- Thin orchestrator, fat agents -- heavy work in fresh contexts

### Git as Memory (from AutoResearch)
- Atomic commits per task: `feat(wave-task): description`
- Reset on failure, commit on success
- The git log is the experiment journal

### Self-Evolving Strategy (from OpenSpace)
- If an approach isn't working, pivot -- don't persist
- Log strategy changes so the user can see reasoning
- Default max 2 iterations on any loop (override with `--loops N`, hard cap at 100 with user confirmation)
- **Diminishing returns rule (all loops):** If an iteration produces <10% new value vs the previous, stop early regardless of remaining budget

### Simplicity Criterion (from AutoResearch)
- Simpler wins when results are comparable
- Removing code for equal results is always a win
- Complexity must justify itself with measurable improvement

### Structured Output (from Google Workspace CLI)
- Tables for comparisons
- Confidence tags: `[VERIFIED]` `[INFERRED]` `[ASSUMED]`
- Clear sections, actionable next steps

### Verify Before Execute (from GSD)
- Plans checked before execution, not just after
- Requirement coverage, atomicity, dependencies, scope
- Default max 2 revision loops (override with `--loops N`); escalate if still failing

### Brownfield First (from GSD)
- Map before modifying
- Match existing patterns
- Use existing abstractions before creating new ones
