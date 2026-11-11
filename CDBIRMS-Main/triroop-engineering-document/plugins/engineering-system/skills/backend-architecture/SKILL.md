---
name: backend-architecture
description: ES backend folder structure — feature-based api/logic/contract/data layout, and the rule that route.ts files stay thin. Use when adding or editing server-side/API code, or deciding where a new handler, business-logic function, DTO, or DB query belongs.
---

# ES Backend Structure

Backend also follows feature-based architecture, mirroring the frontend's `features/` convention.

```
features/<name>/
├── api/       # Route Handlers and request handling
├── logic/     # Business logic and workflows
├── contract/  # Validation, schemas, DTOs, API contracts
└── data/      # Database operations and repositories
```

## Folder meaning

- **`api/`** — the feature's real handler logic lives here. The corresponding `app/api/.../route.ts` file stays thin: it imports and re-exports from this folder so routing and feature logic remain separate (same principle as the frontend's thin `app/page.tsx`).
- **`logic/`** — business logic and workflows, independent of HTTP concerns.
- **`contract/`** — validation, schemas, DTOs, API contracts. See `validation` skill for the Zod convention.
- **`data/`** — database operations and repositories. See `database-orm` skill.

## Separate database models from API contracts

Raw database records should never be directly exposed to the frontend. Map through `contract/` (DTO mapping, response contracts, structured API payloads) — this is the main purpose of that folder. If you find yourself passing a Prisma model straight out of a route handler, stop and add a DTO mapping step.

## Why this shape

Improves modularity, maintainability, onboarding speed, AI understanding, and debugging — the same reasoning as the frontend split in `frontend-architecture`. A backend feature slice should be independently understandable without needing to trace through unrelated features.
