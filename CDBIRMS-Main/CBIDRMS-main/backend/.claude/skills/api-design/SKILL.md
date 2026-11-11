---
name: api-design
description: ES API design conventions — versioned, resource-based REST routes, standard HTTP methods, and a consistent JSON success/error envelope. Use when adding, changing, or reviewing HTTP API endpoints.
---

# ES API Structure

Resource-oriented, versioned REST design, inspired by API practices at companies like Microsoft, Google, and Stripe.

## Versioning

All APIs are versioned:

```
/api/v1/
```

```
/api/v1/auth/login
/api/v1/projects
/api/v1/vendors
/api/v1/invoices
```

Benefits: backward compatibility, safer future updates, support for multiple app versions, reduced breaking changes.

## Resource-based, not RPC-style

Design around business resources (nouns), not actions (verbs).

Correct:
```
/projects
/vendors
/invoices
/users
```

Avoid:
```
/createProject
/getVendorData
/deleteInvoice
```

## Standard HTTP methods

| Method | Purpose |
|---|---|
| GET | Read data |
| POST | Create data |
| PATCH | Update partial data |
| PUT | Replace full data |
| DELETE | Remove data |

```
GET    /api/v1/projects
POST   /api/v1/projects
PATCH  /api/v1/projects/:projectId
DELETE /api/v1/projects/:projectId
```

## Response envelope

Success:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "error": null
}
```

Error:
```json
{
  "success": false,
  "message": "Unauthorized",
  "data": null,
  "error": {
    "code": "AUTH_REQUIRED"
  }
}
```

Every endpoint response — success or error — follows this shape. This is what makes frontend error handling and AI-generated client code predictable across the whole API surface.

## Field notes (observed across ES repos)

A 2026-07 audit of five ES-governed repos found real, live divergence from every rule above — not hypothetical risk. Treat these as things to check for explicitly, not assume away:

**Versioning**: only one of two audited NestJS backends put a version in the path at all, and even that one didn't use a single global `/api/v1/` prefix — it baked the version into each controller's literal base path per feature (`@Controller('auth/v1')`, `@Controller('chat/v1')`, with a `chat/v2` controller added later for one endpoint). The other backend used a single global prefix (`app.setGlobalPrefix('api')`) with **no version segment anywhere**. Per-feature literal versioning is workable but fragile: it already produced one confirmed route collision in the audited codebase, where two unrelated controllers registered the identical literal path and the app silently resolved it by controller-registration order. If you use per-feature versioning instead of a global prefix, treat every new controller's base path as a namespace that must be checked against the rest of the app for collisions — don't assume the framework will catch it.

**Resource-based, not RPC-style — the recurring exception**: multiple audited backends implement a deliberate, repeated pattern where a "read" endpoint is a `POST` whose body is `{ query, variables }`, executed in-process against the app's own GraphQL schema and returned over what looks like a REST path. This showed up independently in two unrelated codebases (one for an entire public catalog API, one for an admin-only surface), which means it's a working, intentional convention for exposing GraphQL through REST-shaped infrastructure — not a one-off mistake. It does genuinely break the GET-is-safe/cacheable/idempotent contract this section otherwise asks for. If you adopt this pattern, name it explicitly in the feature contract (see `feature-contract`) as a "GraphQL-facade" or "REST-tunneled-GraphQL" endpoint rather than letting it pass as a plain REST read — a caller (or an AI generating a client) that assumes GET semantics from the resource name will be wrong.

**Response envelope — a live, unresolved variance**: the canonical envelope above (`{success, message, data, error}`) is followed exactly by one audited backend. A second backend and its companion frontend both instead use `{success, statusCode, data}`, with error detail nested inside `data: { message, code? }` rather than a top-level `error` field. This is not a hypothetical alternative — it's the current, shipped shape in that service, and any client code for it must not assume the canonical envelope. When starting new feature work, check which envelope the target service actually emits (don't assume from this doc) and flag a mismatch as a real backward-compatibility decision to make explicitly, not something to silently paper over in a client-side adapter.
