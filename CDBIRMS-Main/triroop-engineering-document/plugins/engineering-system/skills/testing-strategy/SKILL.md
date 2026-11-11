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
