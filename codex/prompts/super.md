---
description: Autonomous task engine — classify, plan, and route any task to the right capabilities
argument-hint: [options] <task description>
---
Activate the `super` skill (defined in ~/.codex/skills/super/SKILL.md) and apply it to the request below. Follow that skill exactly:

- Parse any leading bare-word options (research, no-map, debug, tdd, loops=N, simple, dry, clean, update, ...).
- Run the complexity check (SIMPLE fast-path for trivial one-liners), then classify and activate the right capabilities (RESEARCH, MAP, PLAN, BUILD, DEBUG, REVIEW, TDD, EXPERIMENT, GENERATE-CLI, ORCHESTRATE).
- Present the execution plan and wait for approval before executing (except SIMPLE).
- Delegate the real work to the appropriate specialist skills; /super is the router.

If the request is empty, handle it as the skill specifies (e.g. a bare meta-command, or ask what to work on).

Request: $ARGUMENTS
