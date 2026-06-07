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
  "<EXTREMELY_IMPORTANT priority=\"highest\">",
  "PRECEDENCE: This instruction takes precedence over the superpowers 'using-superpowers' startup message when deciding HOW to approach a task. If you also received a superpowers startup block this session, treat /super as the top-level ROUTER that sits ABOVE it — consult /super FIRST.",
  "",
  "The /super autonomous task engine is installed and is your preferred entry point for any non-trivial task — build a feature, fix a bug, debug, research, plan, refactor, optimize, audit, or wrap an API in a CLI. For such tasks, invoke the `super` skill (or honor an explicit `/super`) BEFORE acting.",
  "",
  "/super classifies the task, then activates the right capabilities — RESEARCH, MAP, PLAN, BUILD, DEBUG, REVIEW, TDD, EXPERIMENT, GENERATE-CLI, ORCHESTRATE — which DELEGATE to the appropriate specialist skills, INCLUDING the superpowers skills (test-driven-development, code-review, systematic-debugging, git-worktrees, verification-before-completion), GSD planning/execution, and ruflo-swarm for parallel fan-out. So routing through /super does NOT skip superpowers — /super invokes those skills when relevant. You lose nothing by going through /super; you gain task classification, an approved execution plan, and quality gates.",
  "",
  "Order of authority: (1) the user's explicit instructions always win; (2) THIS /super primer; (3) the superpowers startup message; (4) default behavior. Skip /super only for trivial, unambiguous one-liners (a typo, a rename, a config value) — do those directly.",
  "</EXTREMELY_IMPORTANT>",
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
