---
name: engineering-system
description: Index of the ES (Engineering System) skill set — use when a request touches architecture, folder structure, API design, auth, database/ORM, validation, proxy/middleware, testing strategy, or when deciding where new frontend/backend code should live in an ES-structured repo. Also the entry point for "which ES skill applies" triage.
---

# Engineering System (ES) — Skill Index

ES is a reusable, feature-based, vertical-slice engineering system for AI-assisted development. Full narrative source: `ENGINEERING-SYSTEM.md` at the root of whichever project repo is open (read it if present — it may contain project-specific amendments this skill index doesn't know about).

## Core idea

> Every development phase should produce a working, visible output. Build feature by feature as complete vertical slices (frontend + backend + validation + business logic + data), not layer by layer.

## Sub-skills

| Skill | Use when the request involves... |
|---|---|
| `request-workflow` | **Always check this first.** The step-by-step process for handling any user request in an ES project — triage, plan, confirm, execute. |
| `feature-contract` | Starting a new feature that touches an API, DB change, or multiple roles — writing, locating, or reviewing the feature's spec before implementation. |
| `vertical-slice-philosophy` | Deciding feature scope/boundaries, phase sequencing, "should this depend on unbuilt future work" questions. |
| `frontend-architecture` | UI code on either platform — Next.js (components/hooks/model/api, Server vs Client Component decisions) or Flutter (presentation/domain/data, MVVM). |
| `backend-architecture` | Server-side feature code — route handlers, business logic, contracts/DTOs, data access layer placement. |
| `api-design` | New or changed HTTP endpoints — versioning, resource naming, HTTP verbs, request/response envelope shape. |
| `proxy-infrastructure` | Request-time cross-cutting concerns — auth redirects, rate limiting, header rewriting (Next.js `proxy.ts`, formerly middleware). |
| `auth-infrastructure` | Login, sessions, tokens, access control. |
| `validation` | Input validation, schemas, DTOs at system boundaries. |
| `database-orm` | Schema design, migrations, queries, ORM usage, exposing DB data to the frontend. |
| `testing-strategy` | Deciding what/how to test a change. |
| `seo-metadata` | New/changed pages on a Next.js property — metadata, sitemap/robots, structured data, or SEO content quality. Not applicable to Flutter/mobile. |

## Triage rule

If a request doesn't clearly match any sub-skill and you're not confident it's out of scope for ES entirely, say so and ask — don't silently apply ES conventions where they may not fit, and don't silently skip them either.
