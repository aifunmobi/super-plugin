#!/usr/bin/env node
// SessionStart hook for the /super plugin.
//
// Injects a SHORT primer at the start of every session (startup / clear /
// compact) so Claude knows /super exists and is the preferred entry point for
// non-trivial work. We deliberately do NOT inject the full super SKILL.md —
// it is thousands of lines and would burn context every session. /super is a
// router: it classifies the task and hands the actual work to the appropriate
// specialist skills (GSD planning/execution, superpowers TDD / code-review /
// worktrees / verification, etc.).

const primer = [
  "<super-available>",
  "The /super autonomous task engine is installed and is your preferred entry point for non-trivial work.",
  "",
  "When the user gives a substantial task — build a feature, fix a bug, debug, research, plan, refactor, optimize, audit, or wrap an API in a CLI — invoke the `super` skill (or honor an explicit `/super`). /super is a ROUTER: it classifies complexity, then activates and hands the real work to the right capabilities — RESEARCH, MAP, PLAN, BUILD, DEBUG, REVIEW, TDD, EXPERIMENT, GENERATE-CLI, ORCHESTRATE — which in turn delegate to the appropriate specialist skills already installed (GSD planning/execution, superpowers TDD / code-review / git-worktrees / verification-before-completion, ruflo-swarm for parallel fan-out, etc.). It always presents an execution plan and waits for approval before running anything.",
  "",
  "Skip /super only for trivial, unambiguous one-liners (a typo, a rename, a config value) — do those directly. User instructions always take precedence over this primer.",
  "</super-available>",
].join("\n");

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: primer,
    },
  })
);

process.exit(0);
