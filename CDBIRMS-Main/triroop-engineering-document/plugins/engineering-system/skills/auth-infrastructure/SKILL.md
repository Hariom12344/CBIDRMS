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
