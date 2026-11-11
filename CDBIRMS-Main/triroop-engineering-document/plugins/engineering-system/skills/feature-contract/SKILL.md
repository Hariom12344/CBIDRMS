---
name: feature-contract
description: ES feature contract convention — the single source of truth spec for one feature (business objective, user story, fields/validation, business rules, API contract, error codes, permissions, test cases, definition of done) that backend, frontend, and QA build against before implementation starts. Use when starting a new feature that touches an API, DB change, or multiple roles, or when asked to write, create, or review a feature contract/spec.
---

# ES Feature Contract

A Feature Contract is the single source of truth for one feature — written and agreed *before* backend/frontend work starts, so both sides (and QA, and future maintainers) build against the same spec instead of discovering fields, error codes, and edge cases mid-implementation.

## When to write one

- Any feature that touches an API, a DB change, or more than one role/permission level.
- Skip it for trivial UI-only tweaks.
- One contract per feature — don't bundle multiple features into one, and don't split one feature across many.

## Where it lives

`docs/feature-contracts/<FEAT-ID>-<kebab-feature-name>.md` in the project repo (e.g. `docs/feature-contracts/FEAT-001-create-project.md`). If the project already has its own contract-doc convention (check for existing `docs/*-contract.md` files or a `docs/feature-contract-template.md`), match that instead of introducing a new folder — copy the existing template as the starting point when one is present.

## Which version

| Version | Use when |
|---|---|
| Full (23 sections) | Non-trivial business rules, multiple roles, or more than one person building it |
| Lean (13 sections) | Early-stage team, intern-led work, or a small self-contained feature |

Start lean when unsure — it's easy to extend into the full version as complexity emerges. Don't retrofit process onto something already shipped.

## Full contract — 23 sections

1. **Feature Information** — ID, name, module, priority, status, owner, backend/frontend assignees, estimate.
2. **Business Objective** — why we're building it, one sentence.
3. **User Story** — As a [actor], I want [X], so that [Y].
4. **Actors** — exactly which roles can use it (name them; don't default to "everyone").
5. **Entry Point** — where in the UI the flow starts.
6. **UI Reference** — screenshot / Figma / wireframe, with key buttons annotated with what they call.
7. **User Flow** — step-by-step from open to redirect. The most important section — walk the whole path, not just the happy click.
8. **Fields** — table: field, type, required, validation (see `validation` skill for how these get enforced server-side).
9. **Validation Rules** — per-field rules beyond "required" (uniqueness, length, trimming, numeric ranges).
10. **Business Rules** — logic beyond validation: default states, ID generation scheme, referential requirements ("client must already exist").
11. **API Contracts** — every endpoint: method, path, auth requirement, headers, request body, success response, failure response. Follow the `api-design` skill's envelope and versioning conventions.
12. **Backend Processing Flow** — step-by-step server logic (auth → validate → check duplicate → generate ID → persist → log → respond), not just the API shape. See `backend-architecture`.
13. **Database Impact** — tables touched, fields created, indexes, foreign keys, transaction boundaries. See `database-orm`.
14. **Permissions** — per-role CRUD matrix (who can create/read/update/delete). See `auth-infrastructure`.
15. **Error Codes** — a defined code for every failure mode (e.g. `PROJECT_EXISTS`, `CLIENT_NOT_FOUND`); never a bare ad-hoc message.
16. **Frontend Behaviour** — UI reaction per error code (toast, inline field error) and per success case (redirect, confirmation).
17. **Loading Behaviour** — button/spinner state machine during the async call (disable → spinner → re-enable).
18. **Notifications** — email / WhatsApp / push, yes or no, per event.
19. **Audit Logs** — who, when, old value, new value, IP, browser — if the feature needs one.
20. **Test Cases** — happy path, validation failures, permission denials, edge cases (boundary lengths, boundary dates). See `testing-strategy`.
21. **Dependencies** — other modules/features this one requires to exist first.
22. **Definition of Done** — checklist: backend done, frontend integrated, tested, API docs updated, logging added, error handling complete, review approved, merged.
23. **Future Improvements** — explicitly out of scope for this pass. Keeps scope creep out of the current implementation; matches ES's "no incomplete or placeholder phases" principle.

## Lean contract — 13 sections

Feature Summary, User Story, UI Screenshot, User Flow, Fields & Validation, Business Rules, API Contract, Backend Flow, Database Changes, Permissions, Error Codes, Acceptance Criteria, Test Cases.

## How this fits the ES workflow

For any request to build a new feature end-to-end (not a bugfix or small change), check for an existing contract before proposing structure — treat it as current-state alongside the code graph (`request-workflow` step 4). If none exists and the feature warrants one (see "When to write one"), either write it first or flag that one is missing before jumping to implementation. If a contract exists and the code disagrees with it, flag the drift rather than silently trusting one over the other.
