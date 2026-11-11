---
name: proxy-infrastructure
description: ES's single-proxy-file convention for Next.js request-time processing (Proxy is Next.js 16's renamed Middleware) — optimistic auth checks, rate limiting, header/redirect handling. Use when adding request-time logic that isn't full route-handler business logic.
---

# ES Proxy Infrastructure

As of Next.js 16, Middleware is called **Proxy** — same functionality, but only one `proxy.ts` file is supported per project (at the project root, alongside `app/`).

## Request flow

```
Request
  → Proxy (proxy.ts)
  → Route Handler / Page
  → Logic Layer
  → Data Layer
  → Response
```

## What Proxy is for

- Optimistic authentication checks (redirects only — **not** full session validation)
- Request filtering
- Header modification
- Redirects and rewrites
- Rate limiting

## What Proxy is NOT for

Full validation, business-logic error handling, and analytics event tracking that need the full request/response body stay in the Route Handler layer (`logic/` and `contract/` — see `backend-architecture`). Proxy is not intended for slow data fetching or full session management.

## Modular composition

Because Next.js allows only one `proxy.ts`, split proxy logic into separate files and compose them inside the single entry point:

```
shared/
└── proxy/
    ├── auth.ts
    ├── rate-limit.ts
    └── analytics.ts
proxy.ts
```

`proxy.ts` itself should just import and call each concern in order — it's a thin composition file, same principle as `app/page.tsx` staying thin over `features/`.

## Field notes (observed across ES repos)

A 2026-07 audit of five ES-governed repos (three Next.js frontends, two NestJS backends) found this convention is frequently **not implemented at all**:

- None of the three Next.js frontends audited (`webapp-v1`, `admin-panel`, `lms-webapp`) had a `middleware.ts` or `proxy.ts` at the project root. There was no request-time interception layer in any of them.
- In its place, auth gating was done entirely inside individual `route.ts` handlers, or — for whole authenticated sections like an admin console — via a **client-side React component** (e.g. an `AuthGuard` wrapping a layout, checking auth state from a store). This is not equivalent to Proxy: it runs after the bundle has already loaded in the browser, can flash protected UI before redirecting, and cannot do anything to a request before it reaches a Server Component or route handler. Treat a client-side guard component as a UX nicety at best, never as the enforcement point for a role- or permission-gated section — see `auth-infrastructure`'s field notes for a concrete case where this went wrong.

**Naming collision to avoid**: one audited repo had a file at `shared/api/proxy.ts` — but it was not Next.js Proxy/Middleware. It was a per-route helper function (`proxyRequest(request, backendPath)`) called from inside `route.ts` handlers to forward a request to an external backend service and relay the JSON response — a "backend-forwarding" or "BFF passthrough" helper, unrelated to request-time interception. This is a legitimate and common pattern for Next.js apps that are thin clients in front of a separate API service, but naming it `proxy.ts` invites a reader (human or AI) to mistake it for the one-per-project Proxy entry point described above. If you write this kind of helper, name it something else — e.g. `shared/api/backend-forward.ts` or `shared/lib/api-relay.ts` — and reserve the term "Proxy" exclusively for the root `proxy.ts` file this skill describes.

**Checklist before assuming Proxy infrastructure exists in a codebase**: grep for `proxy.ts` or `middleware.ts` at the project root specifically — the presence of *some* file with "proxy" in its name elsewhere in the tree is not evidence that request-time interception is implemented.
