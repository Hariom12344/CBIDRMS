---
name: auth-infrastructure
description: ES authentication conventions — JWT access/refresh token architecture, what belongs in the token payload vs. server-side checks. Use when building login, session, or access-control logic.
---

# ES Authentication Infrastructure

JWT-based authentication with refresh-token architecture.

## Access token

Short-lived; used for API access.

## Refresh token

Long-lived; used for silent re-authentication.

## JWT payload contents

Store only:
- user identity
- session ID
- token metadata

**Never** put permissions or business-rule data in the token payload. Permissions and business validations always happen on the server, on every request — the token identifies the session, it doesn't authorize the action.

## Where auth checks live

- **Optimistic checks (redirects only)** — in `proxy.ts` via `shared/proxy/auth.ts`. See `proxy-infrastructure`.
- **Full session validation and permission checks** — in the route handler's `logic/` layer (see `backend-architecture`), where the full request context is available. Proxy is too early/thin a layer for this.

Benefits of this split: persistent sessions, secure authentication, scalable session management, without pushing slow validation work into the request-time proxy layer.

## Field notes (observed across ES repos)

A 2026-07 audit of five ES-governed repos found the token architecture above correctly implemented where checked (matching access/refresh strategies, a shared token issuer across services, identity-and-session-only payloads). The gap was entirely in "where auth checks live":

**Client-side guard components are not a substitute for either enforcement point this doc describes.** One audited frontend gated an entire authenticated admin section using only a client-side React component wrapping the section's layout — no `proxy.ts` optimistic check, and no server-side permission check either, because that frontend had no backend route handlers of its own (it called an external API directly). This is strictly weaker than what this doc requires: it runs after the JS bundle has already loaded, so it can briefly render protected UI before redirecting, and it does nothing to stop a direct API call from a client that skips the UI entirely.

**Concrete failure found**: that same guard component checked only "is the user authenticated," never "does the user have the required role" — despite role-derived selectors and hooks (`selectIsAdmin`, `useHasRole`, etc.) existing elsewhere in the same codebase and clearly having been built for this purpose. The result: any authenticated user of any role could reach every page in a role-restricted admin section at the route level; role checks that did exist were scattered at the individual-widget level (e.g. showing/hiding a badge), which is not access control.

**Checklist**: when a section or route is meant to be role-restricted, don't infer that from the presence of a guard/HOC with a name like `AuthGuard` or `RequireAuth` — read its actual condition. "Is logged in" and "has role X" are different checks, and a component or middleware that only does the former provides no protection against the latter. If the real enforcement needs to live in a route handler's `logic/` layer per this doc but the frontend has no route handlers of its own (it's a thin client to an external API), the role check has to happen server-side in that external API — a frontend-only guard is never sufficient on its own for a role-gated feature.
