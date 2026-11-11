---
name: database-orm
description: ES database/ORM stack and principles — PostgreSQL via Supabase, Prisma ORM, DTO separation from raw DB models, avoiding premature optimization. Use when designing schema, writing migrations/queries, or deciding how DB data should reach the API/frontend.
---

# ES Database and ORM Philosophy

## Stack

- **Database**: PostgreSQL
- **Platform**: Supabase (managed Postgres, faster backend setup, built-in auth support)
- **ORM**: Prisma (type-safe queries, predictable schema management, AI-friendly query generation)
- **Validation**: Zod (see `validation` skill)
- **Architecture**: Modular monolith — not microservices
- **API style**: REST (see `api-design` skill)

## Why this stack

Chosen for maintainability, scalability, development speed, predictable engineering, and long-term flexibility over premature distributed-systems complexity. Don't reach for microservices, sharding, or exotic infra unless the project has actually outgrown this — see `vertical-slice-philosophy`'s "avoid premature optimization."

## Separate DB models from API contracts

Raw database records must never be directly exposed to the frontend. Every query result that crosses into `api/` should be mapped through a DTO in `contract/` first (see `backend-architecture`). This is not optional scaffolding — it's what keeps schema changes from becoming breaking API changes.

## Standardization

Keep schema naming, migration workflows, and query patterns consistent across features — this is what makes onboarding and AI-assisted changes predictable in a modular-monolith codebase where many features share one database.
