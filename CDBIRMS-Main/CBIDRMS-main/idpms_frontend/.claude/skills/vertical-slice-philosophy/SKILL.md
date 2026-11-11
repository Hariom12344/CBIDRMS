---
name: vertical-slice-philosophy
description: ES's core development philosophy — vertical slice development, phase independence, and AI-friendly engineering. Use when deciding feature scope/boundaries, sequencing work across multiple phases, or judging whether a piece of work should wait on something not yet built.
---

# Vertical Slice Philosophy (ES Core Philosophy)

## Every phase must work independently

Each development phase should produce a working frontend, working backend, working database flow, and visible UI or terminal output. No incomplete or placeholder phases.

> Software should remain functional after every phase.

Concretely: don't land a backend endpoint with no UI to exercise it and call it "phase 1"; don't land a UI that calls an endpoint that doesn't exist yet. If a phase must be split, split it so each piece is independently demonstrable.

## Current phase should not depend on future phase

A feature may use outputs from previous features, but must never wait for future development. This is what makes debugging, testing, and onboarding predictable — nothing is "temporarily broken until phase 3 lands."

When scoping work, check: does this plan silently assume something that hasn't been built yet? If so, either build that dependency first (as its own slice) or restructure so the current slice doesn't need it — e.g., a real empty state instead of a stub that assumes future data.

## Vertical slice development

Each feature contains its own frontend, backend, validation, business logic, and database handling as one complete, self-contained slice (e.g., authentication, billing, dashboard, inventory, reports). Every slice should be independently understandable, independently testable, and independently maintainable — see `frontend-architecture` and `backend-architecture` for the concrete folder structure this maps to.

## AI-friendly engineering

The system is designed to reduce AI context overload and hallucination risk: predictable file naming, one clear place for each kind of code, and explicit Server/Client boundaries rather than implicit ones. When something doesn't fit the established pattern, that's a signal to slow down and check with the user rather than improvise a new convention.

## Avoid premature optimization

Don't build for massive distributed systems, highly complex infrastructure, or premature microservices when the project doesn't need them yet. Current priorities are maintainability, predictable development, and rapid iteration — not scale that isn't there yet.
