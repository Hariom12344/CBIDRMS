---
name: backend-architecture
description: ES backend folder structure — two supported shapes, Next.js feature-based api/logic/contract/data layout, and the canonical NestJS standalone-service layout (feature-first modules, chat-service/lms-service style). Use when adding or editing server-side/API code, or deciding where a new handler, business-logic function, DTO, or DB query belongs.
---

# ES Backend Structure

ES supports two backend shapes. Pick the one matching what the target project actually is — don't force one into the other's folder layout.

- **Next.js Route Handlers** — the backend *is* a Next.js app's `app/api/**/route.ts` layer (a thin BFF, or a full app with API routes alongside pages).
- **Standalone Service (NestJS)** — a dedicated backend microservice with its own lifecycle, deployed independently (see `deployment-infrastructure`). This is the canonical shape for a new "real backend" project — `chat-service` and `lms-service` are the reference implementations.

---

## Next.js Route Handlers

```
features/<name>/
├── api/       # Route Handlers and request handling
├── logic/     # Business logic and workflows
├── contract/  # Validation, schemas, DTOs, API contracts
└── data/      # Database operations and repositories
```

- **`api/`** — the feature's real handler logic lives here. The corresponding `app/api/.../route.ts` file stays thin: it imports and re-exports from this folder so routing and feature logic remain separate (same principle as the frontend's thin `app/page.tsx`).
- **`logic/`** — business logic and workflows, independent of HTTP concerns.
- **`contract/`** — validation, schemas, DTOs, API contracts. See `validation` skill for the Zod convention.
- **`data/`** — database operations and repositories. See `database-orm` skill.

Don't assume every Next.js project needing backend code has all four folders per feature — a thin client that only forwards requests to an external service (see the "backend-forwarding helper" note in `proxy-infrastructure`) may only need `api/`, with no `logic/`/`data/` at all, because there's no real business logic or DB access on this side of the boundary.

---

## Standalone Service (NestJS)

This is the required shape for a new dedicated backend service — feature-first, one folder per business domain, each a self-contained NestJS module:

```
src/
├── main.ts                 # bootstrap: global pipe/filter/interceptors, Swagger, CORS
├── app.module.ts           # root module — wires GraphQLModule (if used) + every feature module
├── <feature>/
│   ├── <feature>.controller.ts
│   ├── <feature>.service.ts
│   ├── <feature>.module.ts
│   ├── <feature>.resolver.ts    # only if this feature also exposes GraphQL
│   ├── dto/                     # hand-written request/response DTOs for this feature only
│   └── *.type.ts                 # hand-written GraphQL object types, kept distinct from Prisma models
├── auth/
│   ├── guards/          # JWT/role guards — guards live with the feature that owns them
│   ├── strategies/      # Passport strategies (access + refresh)
│   └── decorators/      # e.g. @Roles(...) — feature-owned, not shared
├── common/               # true cross-cutting code only: global exception filter,
│                          # logging/transform interceptors, GraphQL DataLoader factory
└── prisma/ (or database/) # a @Global() module wrapping PrismaClient, exported once
```

### Rules

- **File naming**: strict `<feature>.<artifact>.ts` (`courses.controller.ts`, `courses.service.ts`, `courses.module.ts`). One controller class per file as the default — if a feature genuinely needs multiple versioned controllers (`ChatV1Controller`, `ChatV2Controller`), that's acceptable, but don't let a single controller file grow past a few hundred lines without reconsidering the split.
- **Guards, strategies, and decorators live inside the feature that owns them** — typically only `auth/` needs any of these. Do **not** create a top-level shared `guards/`/`decorators/`/`pipes/` folder; if a check is genuinely cross-cutting (applies to every request regardless of feature), it belongs in a global interceptor/filter in `common/`, not a shared guard.
- **`common/` is for true cross-cutting code only**: the global exception filter, logging/transform interceptors, and (if using GraphQL) the per-request DataLoader factory. If you're tempted to put a guard or a DTO in `common/`, it almost certainly belongs in the feature that uses it instead.
- **No generic `pipes/` folder** — validation is one global `ValidationPipe` (`whitelist: true, forbidNonWhitelisted: true, transform: true`) registered once in `main.ts`. Don't write custom pipes for per-field validation; that belongs in a DTO with `class-validator` decorators.
- **DTOs and GraphQL types are feature-local**, not centralized — `<feature>/dto/*.dto.ts` for REST request/response shapes, `<feature>/*.type.ts` for hand-written GraphQL object types. There is no separate `contract/`/`data/` split like the Next.js shape above — the feature folder itself plays both roles.
- **Never expose a raw Prisma model** through a controller or resolver. Wrap list responses in a dedicated type (e.g. `PaginatedCoursesResponse`), and keep hand-written GraphQL `*.type.ts` definitions distinct from generated Prisma types — this is the one rule shared with the Next.js shape above, and it's the part of ES most consistently followed in practice.
- **Registering controllers**: either register each feature's controller in its own `<feature>.module.ts`, or centralize all controller registration in `app.module.ts` — pick one convention per project and apply it consistently. If a project centralizes registration (some do, to avoid DI-ordering issues with a global GraphQL schema), document that decision in the module file itself so it isn't mistaken for an oversight later.
- **main.ts bootstrap checklist**: global `ValidationPipe`; a global exception filter that normalizes both HTTP and (if applicable) GraphQL errors into one response envelope (see `api-design`); logging + response-transform interceptors; Swagger mounted only outside production (`NODE_ENV !== 'production'`) if the project uses REST; CORS restricted to known origins outside production, open (or allowlist-based) in production; explicit body-size limits on `express.json()`/`express.urlencoded()` if the service accepts uploads or large payloads.

### GraphQL-facade controllers — a recognized pattern, not a smell

A recurring, deliberate pattern in ES NestJS services: a controller whose only job is a single `POST` handler that accepts `{ query, variables }` and executes it in-process against the app's own Apollo schema (via `GraphQLSchemaHost`), returning the result over what looks like a plain REST endpoint. This exists so REST-only tooling (an admin panel, an API-key client) can reach a GraphQL-first backend without shipping a GraphQL client. Use this when you have a GraphQL-first service and a caller that can only speak REST — but name it explicitly as a facade in the feature contract (see `feature-contract`) rather than letting it pass as a normal resource endpoint; a caller assuming normal REST semantics (cacheable GET, resource-oriented path) will be wrong (see `api-design`).

### Why this shape

Same reasoning as the Next.js shape and the frontend split in `frontend-architecture`: modularity, onboarding speed, AI understanding, debugging. A feature slice — REST controller, GraphQL resolver, service, DTOs — should be understandable end to end without tracing through unrelated features.
