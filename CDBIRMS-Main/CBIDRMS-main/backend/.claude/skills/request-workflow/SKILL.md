---
name: request-workflow
description: The step-by-step process for handling a user request in an ES-structured project — figure out what changed, match it to an ES skill, inspect current repo state via the code graph, plan the change, size its blast radius, and confirm before executing. Use this for every substantive request in a project that has adopted ES (ENGINEERING-SYSTEM.md present), especially before writing or editing code.
---

# ES Request Workflow

This is the process to run when a user sends a request in an ES project (a project with `ENGINEERING-SYSTEM.md` or an equivalent adopted architecture doc). It's the operational counterpart to the `engineering-system` skill index — that skill tells you *which* architectural rules apply; this skill tells you *how to move* from request to shipped change.

## When to run the full process

Run all 9 steps below for requests that will result in code, schema, config, or file changes.

Skip straight to a direct answer (no gating, no plan-confirmation) for:
- Pure questions ("what does this function do", "why is X structured this way")
- Read-only investigation ("find where Y is defined")
- Requests that are already fully specified and trivial (typo fix, rename a single clearly-identified variable)

Forcing a 9-step ceremony onto a one-line question is not the goal — the goal is that *changes* to the codebase are deliberate, scoped, and confirmed, matching ES's "no incomplete or placeholder phases" and "current phase should not depend on future phase" principles.

## The 9 steps

1. **Read the diff between what's being asked and what exists.** Restate the request in one or two sentences: what is the user actually asking to change, add, or fix?

2. **Match against ES skills.** Check the `engineering-system` skill index — does this fall under `feature-contract`, `frontend-architecture`, `backend-architecture`, `api-design`, `proxy-infrastructure`, `auth-infrastructure`, `validation`, `database-orm`, or `testing-strategy`? Load the matching skill(s) before proceeding. A request can span more than one (e.g., a new authenticated API route touches `backend-architecture`, `api-design`, and `auth-infrastructure`; a brand-new feature also touches `feature-contract`).

3. **If unsure which skill applies, or the request is ambiguous enough that guessing wrong would mean real rework, ask.** Use AskUserQuestion rather than guessing silently. Don't ask about things you can resolve yourself by reading the code — only ask when the answer genuinely depends on a judgment call only the user can make (which of two valid architectural approaches, which existing feature this extends, scope boundaries).

4. **Understand current state before proposing changes.** Use the code graph tool (or Read/Grep/Glob if the graph is empty or insufficient — state why) to see what already exists: is there a matching feature folder already? What does the existing pattern for similar features look like? For a brand-new end-to-end feature, also check for an existing Feature Contract (see `feature-contract` skill) — it's current-state too, and takes precedence over guessing at fields/rules from scratch. Don't propose structure that ignores what's already there.

5. **Restate the requirement precisely**, now informed by steps 2–4 — in terms of the actual feature/file structure involved, not just the user's original phrasing.

6. **List the concrete actions**: which files get created, which get edited, which folders (per ES's `components/hooks/model/api` or `api/logic/contract/data` structure) the new code lands in, and any new routes/endpoints/migrations needed.

7. **Size the blast radius.** What else references or depends on the files being touched? Does this change cross a feature boundary? Would it break an existing vertical slice? This is where the graph's impact/dependency queries are useful.

8. **Present the plan and get confirmation before editing.** A short plan is enough for small, well-scoped changes — you don't need heavyweight ceremony for a one-file addition that clearly follows an established pattern. Use AskUserQuestion (or plan mode, if the change is large/architectural) when there's a real decision point or when the blast radius from step 7 is non-trivial. For truly mechanical, single-file, pattern-matching work, a one-line "I'll do X, matching the pattern in Y" stated up front is sufficient — don't manufacture a confirmation step where there's no real decision left to make.

9. **Execute only after that confirmation** (explicit "yes", or an unambiguous absence of objection to a clearly-stated trivial plan). Then build, verify (typecheck/lint/tests, and in-browser check for UI), and report back concisely — what changed, what's next.

## Why this exists

Matches ES's core philosophy: predictable, AI-friendly, vertical-slice development where AI should "understand project intent with minimum confusion" and every phase produces a working, reviewed output rather than a surprise.
