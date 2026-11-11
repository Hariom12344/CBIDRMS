# engineering-system

Personal Claude Code plugin encoding the ES (Engineering System) architecture — converted from `ENGINEERING-SYSTEM.md`. Installed under `~/.claude/skills/` (scope: user), so it's active across all local projects, not just one repo.

## What's in it

- **`SKILL.md`** — index of all ES sub-skills, loaded whenever a request touches architecture/structure decisions.
- **`skills/`** — one skill per ES sub-topic: `feature-contract` (the pre-implementation spec template), `frontend-architecture` (Next.js + Flutter), `backend-architecture`, `api-design`, `proxy-infrastructure`, `auth-infrastructure`, `validation`, `database-orm`, `seo-metadata` (Next.js only), `testing-strategy`, `vertical-slice-philosophy`, and `request-workflow` (the 9-step request-handling process).
- **`commands/es-flow.md`** — `/es-flow` — manually force the full 9-step workflow on the next request.
- **`hooks/`** — `UserPromptSubmit` hook that automatically injects a short pointer to the ES workflow into every prompt's context (harness-only, no extra model turn).

## Updating

Edit files directly under `~/.claude/skills/engineering-system/`. Run `/reload-plugins` in an active session (or start a new session) to pick up changes — plugin components load at session start, not live.

## Removing

`claude plugin disable engineering-system@skills-dir` to disable, or delete this directory to remove entirely.
