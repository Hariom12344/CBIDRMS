---
name: testing-strategy
description: ES testing philosophy — unit tests for isolated business logic, integration tests across API/database/service/middleware boundaries. Use when deciding what kind of test a change needs.
---

# ES Testing Philosophy

## Unit testing

Testing isolated business logic and functions — primarily the `logic/` layer of a backend feature slice, and pure functions/hooks on the frontend.

## Integration testing

Testing feature flow across boundaries: API ↔ database ↔ services ↔ proxy/middleware. This is where a vertical slice's end-to-end behavior gets verified, not just its individual pieces.

## Goal

Safer deployments, predictable releases, reduced production bugs, maintainable engineering quality — not maximal coverage for its own sake. A change that only touches presentation (copy, styling) doesn't need new integration tests; a change that touches validation, auth, or data flow generally does.

## Field notes (observed across ES repos)

A 2026-07 audit of five ES-governed repos (three frontends, two backends) found this philosophy describes intent, not observed baseline: every single repo audited had near-zero test coverage on both tiers. Typical findings — one e2e spec file and a single controller spec for an entire backend service with dozens of endpoints; a whole frontend repo with exactly one test file total, covering an unrelated utility function, with no test runner even wired into the build pipeline (no `test` task in the monorepo's task runner, in more than one repo).

**Do not assume existing coverage exists elsewhere in a codebase you're extending.** If you're told (or infer) that "tests exist for this area," verify it — the audit found the plausible-sounding assumption ("there's probably a spec file per controller/feature") was false in every repo checked. In practice, in an ES-governed repo you join today, the realistic default is: no test currently exercises the code path you're about to touch.

**How to apply this gap going forward**: treat any change that touches `logic/`, `contract/`/`data/` (backend), or auth/permission code as an opportunity to add the missing test for that specific path, rather than waiting for a dedicated "add tests" effort that these five repos show doesn't tend to happen on its own. Don't scope a new test suite for the whole feature unless asked — add coverage for the specific logic you changed, consistent with this project's broader "don't do work beyond what's asked" default.
