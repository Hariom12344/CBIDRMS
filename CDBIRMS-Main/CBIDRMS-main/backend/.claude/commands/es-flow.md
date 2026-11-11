---
name: es-flow
description: Manually run the full ES 9-step request workflow (triage, skill match, current-state check, plan, blast-radius, confirm, execute) against the user's next instruction, even for a request that might otherwise seem simple.
---

Load the `request-workflow` skill from the `engineering-system` plugin and follow its 9-step process in full for the user's next request in this conversation, regardless of how small it looks. Load the `engineering-system` skill index alongside it to pick the right sub-skill(s) (feature-contract, frontend-architecture, backend-architecture, api-design, proxy-infrastructure, auth-infrastructure, validation, database-orm, testing-strategy, vertical-slice-philosophy).

Work through the steps explicitly and visibly:
1. Restate what's being asked.
2. Say which ES skill(s) apply (or that none clearly do).
3. If genuinely unsure or the request is ambiguous, ask via AskUserQuestion before continuing.
4. Inspect current repo state (graph tool first, then Read/Grep/Glob only if the graph is insufficient — say why).
5. Restate the requirement precisely in terms of the actual codebase.
6. List concrete file/folder actions.
7. State the blast radius — what else is affected.
8. Present the plan and get explicit confirmation before editing anything.
9. Only then execute, verify, and report back concisely.

If the user hasn't given the actual request yet, ask what they'd like done and then run this process against it.
