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
