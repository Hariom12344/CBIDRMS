---
name: feature-contract
description: ES feature contract convention — the single source of truth spec for one feature (business objective, user story, fields/validation, business rules, API contract, error codes, permissions, test cases, definition of done) that backend, frontend, and QA build against before implementation starts. Use when starting a new feature that touches an API, DB change, or multiple roles, or when asked to write, create, or review a feature contract/spec.
---

# ES Feature Contract

A Feature Contract is the single source of truth for one feature — written and agreed *before* backend/frontend work starts, so both sides (and QA, and future maintainers) build against the same spec instead of discovering fields, error codes, and edge cases mid-implementation.

## When to write one

- Any feature that touches an API, a DB change, or more than one role/permission level.
- Skip it for trivial UI-only tweaks.
- One contract per feature — don't bundle multiple features into one, and don't split one feature across many.

## Where it lives

`docs/feature-contracts/<FEAT-ID>-<kebab-feature-name>.md` in the project repo (e.g. `docs/feature-contracts/FEAT-001-create-project.md`). If the project already has its own contract-doc convention (check for existing `docs/*-contract.md` files or a `docs/feature-contract-template.md`), match that instead of introducing a new folder — copy the existing template as the starting point when one is present.

## Which version

| Version | Use when |
|---|---|
| Full (23 sections) | Non-trivial business rules, multiple roles, or more than one person building it |
| Lean (13 sections) | Early-stage team, intern-led work, or a small self-contained feature |

Start lean when unsure — it's easy to extend into the full version as complexity emerges. Don't retrofit process onto something already shipped.

## Full contract — 23 sections

1. **Feature Information** — ID, name, module, priority, status, owner, backend/frontend assignees, estimate.
2. **Business Objective** — why we're building it, one sentence.
3. **User Story** — As a [actor], I want [X], so that [Y].
4. **Actors** — exactly which roles can use it (name them; don't default to "everyone").
5. **Entry Point** — where in the UI the flow starts.
6. **UI Reference** — screenshot / Figma / wireframe, with key buttons annotated with what they call.
7. **User Flow** — step-by-step from open to redirect. The most important section — walk the whole path, not just the happy click.
8. **Fields** — table: field, type, required, validation (see `validation` skill for how these get enforced server-side).
9. **Validation Rules** — per-field rules beyond "required" (uniqueness, length, trimming, numeric ranges).
10. **Business Rules** — logic beyond validation: default states, ID generation scheme, referential requirements ("client must already exist").
11. **API Contracts** — every endpoint: method, path, auth requirement, headers, request body, success response, failure response. Follow the `api-design` skill's envelope and versioning conventions.
12. **Backend Processing Flow** — step-by-step server logic (auth → validate → check duplicate → generate ID → persist → log → respond), not just the API shape. See `backend-architecture`.
13. **Database Impact** — tables touched, fields created, indexes, foreign keys, transaction boundaries. See `database-orm`.
14. **Permissions** — per-role CRUD matrix (who can create/read/update/delete). See `auth-infrastructure`.
15. **Error Codes** — a defined code for every failure mode (e.g. `PROJECT_EXISTS`, `CLIENT_NOT_FOUND`); never a bare ad-hoc message.
16. **Frontend Behaviour** — UI reaction per error code (toast, inline field error) and per success case (redirect, confirmation).
17. **Loading Behaviour** — button/spinner state machine during the async call (disable → spinner → re-enable).
18. **Notifications** — email / WhatsApp / push, yes or no, per event.
19. **Audit Logs** — who, when, old value, new value, IP, browser — if the feature needs one.
20. **Test Cases** — happy path, validation failures, permission denials, edge cases (boundary lengths, boundary dates). See `testing-strategy`.
21. **Dependencies** — other modules/features this one requires to exist first.
22. **Definition of Done** — checklist: backend done, frontend integrated, tested, API docs updated, logging added, error handling complete, review approved, merged.
23. **Future Improvements** — explicitly out of scope for this pass. Keeps scope creep out of the current implementation; matches ES's "no incomplete or placeholder phases" principle.

## Lean contract — 13 sections

Feature Summary, User Story, UI Screenshot, User Flow, Fields & Validation, Business Rules, API Contract, Backend Flow, Database Changes, Permissions, Error Codes, Acceptance Criteria, Test Cases.

## Reference example: Authentication (worked contract)

A full, filled-in 23-section contract for a real cross-cutting feature (Register, Login, Forgot Password, Reset Password, Refresh Token, Logout). Use it as the shape/depth bar when writing a new contract, or copy it directly for projects that need standard auth.

Treat this as normative. A project-specific `docs/feature-contracts/<timestamp>-authentication.md` should copy it and only adapt the parts explicitly marked **"project decision"** below (topology, delivery channel). Everything else — error codes, payload field names, token claim names, response envelope — should not drift between projects.

This example assumes the `api-design`, `auth-infrastructure`, and `validation` skills — it doesn't restate those conventions, only applies them concretely.

### Topology note (read first)

This contract is written to be topology-agnostic — it covers monorepo Next.js full-stack, separate NestJS + Next.js, and NestJS + Flutter, because different projects use different combinations of these. Two things change by topology and are called out explicitly wherever they matter:

- **Refresh token transport** — cookie vs. bearer (see §11, §14 dual-mode below).
- **CORS / cookie domain settings** — only relevant when frontend and backend are separate origins.

Everything else (field names, error codes, expiry values, envelope) is identical regardless of topology.

### 1. Feature Information

```
Feature ID
AUTH-001

Feature Name
Authentication (Register, Login, Forgot Password, Reset Password, Refresh Token, Logout)

Module
Authentication & Session Management

Priority
Critical — blocks every other authenticated feature

Status
Reference / Adopt-per-project

Owner
(set per project)

Assigned To
Backend: (set per project)
Frontend: (set per project)

Estimated Time
(set per project — this module is larger than a typical single feature; budget accordingly)
```

### 2. Business Objective

Let a user create an account, sign in, recover access if they forget their password, and stay signed in across sessions without repeatedly re-entering credentials — securely, and identically across every client (Next.js web, Flutter mobile) that talks to the backend.

### 3. User Story

```
As a user (new or returning)

I want to register, log in, recover my password, and stay signed in

So that I can use the application securely without friction, on any client
```

### 4. Actors

```
Guest (unauthenticated)   — register, login, forgot-password, reset-password
Authenticated User        — refresh-token, logout
```

No other role distinction applies at this layer. Role/permission checks for *what an authenticated user can do* are a separate concern, enforced per the `auth-infrastructure` skill — never inferred from anything in this contract.

### 5. Entry Point

```
Register    : Signup page → "Create Account"
Login       : Login page → "Sign In"
Forgot Pwd  : Login page → "Forgot password?" link
Refresh     : Not user-triggered. Fired automatically by the client's HTTP layer
              (interceptor/wrapper) when a request gets 401 AUTH_TOKEN_EXPIRED,
              or proactively before the access token's known expiry.
Logout      : Any authenticated screen → "Log out"
```

### 6. UI Reference

Project-specific — attach Figma/screenshots per project. The one hard rule: the reset-password screen (web) or reset-password step (mobile) must make clear whether the user is completing a **link flow** or an **OTP flow** (see §9), since the fields differ.

### 7. User Flow

**Register**
```
Open Signup → Fill form (name, email, password, confirmPassword)
→ Client-side validation → POST /register → Server validation
→ Create user (password hashed) → Issue access + refresh token
→ Success → Client stores tokens → Redirect to authenticated home
```

**Login**
```
Open Login → Fill form (email, password) → POST /login
→ Verify credentials (generic failure message either way — see §15)
→ Issue access + refresh token → Client stores tokens
→ Redirect to authenticated home
```

**Forgot Password — link mode**
```
Click "Forgot password?" → Enter email → POST /forgot-password {email, channel: "email"}
→ Always generic success response (see §10) → Emailed link with reset token
→ User opens link → Reset-password page → Enter new password + confirm
→ POST /reset-password {token, newPassword} → Success → Redirect to Login
```

**Forgot Password — OTP mode**
```
Enter email or phone → POST /forgot-password {email|phone, channel: "sms"|"email"}
→ Always generic success response → OTP delivered
→ User enters OTP + new password in-app → POST /reset-password {otp, identifier, newPassword}
→ Success → Redirect to Login
```

**Refresh Token**
```
Client HTTP layer catches 401 AUTH_TOKEN_EXPIRED
→ If a refresh is already in flight, queue this request behind it (see §17 — critical)
→ POST /refresh-token (cookie auto-attached, or {refreshToken} in body per transport mode)
→ Server validates + rotates refresh token → Issues new access + refresh token
→ Original request(s) retried with new access token
→ If refresh itself fails (expired/invalid/reused) → force logout, redirect to Login
```

### 8. Fields

**Register** — `POST /api/v1/auth/register`

| Field | Type | Required | Validation |
|---|---|---|---|
| name | string | Yes | 2–80 chars, trimmed |
| email | string | Yes | Valid email format, lowercased, unique |
| password | string | Yes | See §9 password rules |
| confirmPassword | string | Yes | Must equal `password` (client-side only — never sent to server) |

**Login** — `POST /api/v1/auth/login`

| Field | Type | Required | Validation |
|---|---|---|---|
| email | string | Yes | Valid email format |
| password | string | Yes | Non-empty |

**Forgot Password (request)** — `POST /api/v1/auth/forgot-password`

| Field | Type | Required | Validation |
|---|---|---|---|
| email | string | Conditional | Required if `channel` is `"email"` |
| phone | string | Conditional | Required if `channel` is `"sms"`; E.164 format |
| channel | enum | Yes | `"email"` \| `"sms"` |

**Reset Password (confirm)** — `POST /api/v1/auth/reset-password`

| Field | Type | Required | Validation |
|---|---|---|---|
| token | string | Conditional | Required for link mode; opaque, from emailed URL |
| otp | string | Conditional | Required for OTP mode; 6 digits |
| identifier | string | Conditional | Required for OTP mode (the email/phone the OTP was sent to) |
| newPassword | string | Yes | See §9 password rules |

Exactly one of `token` (link mode) or `otp`+`identifier` (OTP mode) must be present — never both, never neither. Server rejects with `VALIDATION_ERROR` otherwise.

**Refresh Token** — `POST /api/v1/auth/refresh-token`

| Field | Type | Required | Validation |
|---|---|---|---|
| refreshToken | string | Conditional | **Bearer transport only** (see §14). Omitted entirely in cookie transport — token comes from the httpOnly cookie. |

**Logout** — `POST /api/v1/auth/logout`

| Field | Type | Required | Validation |
|---|---|---|---|
| refreshToken | string | Conditional | Bearer transport only, same rule as above |

### 9. Validation Rules

**Password** (register + reset-password — identical rule, one source of truth, enforced server-side via Zod per the `validation` skill, mirrored client-side for UX only):
```
Minimum 8 characters
At least one uppercase letter
At least one lowercase letter
At least one digit
At least one special character
Maximum 128 characters
Not equal to email local-part (basic anti-reuse check)
```

**Email**: standard format check, lowercased and trimmed before comparison/storage, uniqueness enforced at the DB level (unique index), not just app-level.

**OTP**: exactly 6 numeric digits, expires 10 minutes after issue, max 5 verification attempts before it's invalidated (forces requesting a new one).

**Reset token (link mode)**: opaque random token (≥32 bytes), single-use, expires 60 minutes after issue.

### 10. Business Rules

```
Token expiry
  Access token:  1 hour (3600s)
  Refresh token: 90 days (7,776,000s)

Refresh token rotation
  Every successful /refresh-token call invalidates the presented refresh
  token and issues a brand-new one (rotation). A refresh token can be
  redeemed exactly once.

Refresh token reuse detection
  If an already-used (rotated-away) or already-revoked refresh token is
  presented again, treat it as token theft: revoke the entire token
  family (every token descended from that login session), and require
  full re-authentication. Do not silently issue new tokens in this case.

Password hashing
  bcrypt or argon2id, never reversible encryption, never plaintext logs.

Login attempt limiting
  5 failed attempts per account within 15 minutes → ACCOUNT_LOCKED for
  15 minutes. Applies per-account, not just per-IP (per-IP alone is
  insufficient against distributed attempts).

Forgot-password request limiting
  Max 3 requests per email/phone per hour, max 10 per IP per hour.

User enumeration protection
  /login never reveals whether the email exists (§15: always
  INVALID_CREDENTIALS). /forgot-password never reveals whether the
  account exists (§15: always the same generic success response).

Email verification
  Out of scope for this contract — registration does not block on it.
  If a project needs it, it's a separate, additive feature (see §23).
```

### 11. API Contracts

All endpoints under `/api/v1/auth/`. All follow the standard response envelope (`{ success, message, data, error }`, per the `api-design` skill) — with no exceptions.

**Transport mode selection (project decision, applies to every endpoint below):** the client sends `X-Client-Platform: web | mobile` on every auth request. `web` → refresh token is set/read via httpOnly, secure, `SameSite=Lax` cookie, scoped to path `/api/v1/auth`, never present in the JSON body. `mobile` (or any non-web client) → refresh token is returned in the JSON body; the client is responsible for secure storage (Keychain / EncryptedSharedPreferences) and must send it back explicitly in `refreshToken`. This single header decides behavior consistently across login, register, refresh, and logout — there is no per-endpoint variation.

#### Register

```
POST /api/v1/auth/register
Authentication: None
Headers: X-Client-Platform: web | mobile
```

Request
```json
{
  "name": "Asha Rao",
  "email": "asha@example.com",
  "password": "Str0ng!Pass"
}
```

Success `201`
```json
{
  "success": true,
  "message": "Account created.",
  "data": {
    "user": { "id": "usr_01H...", "name": "Asha Rao", "email": "asha@example.com" },
    "accessToken": "eyJ...",
    "accessTokenExpiresIn": 3600,
    "refreshToken": "eyJ..."
  },
  "error": null
}
```
`refreshToken` present only when `X-Client-Platform: mobile`; omitted (set as cookie instead) for `web`.

Failure `409`
```json
{
  "success": false,
  "message": "An account with this email already exists.",
  "data": null,
  "error": { "code": "EMAIL_ALREADY_EXISTS" }
}
```

#### Login

```
POST /api/v1/auth/login
Authentication: None
Headers: X-Client-Platform: web | mobile
```

Request
```json
{ "email": "asha@example.com", "password": "Str0ng!Pass" }
```

Success `200` — same shape as Register's success response.

Failure `401`
```json
{
  "success": false,
  "message": "Invalid email or password.",
  "data": null,
  "error": { "code": "INVALID_CREDENTIALS" }
}
```

Failure `423` (lockout)
```json
{
  "success": false,
  "message": "Too many failed attempts. Try again in 15 minutes.",
  "data": null,
  "error": { "code": "ACCOUNT_LOCKED" }
}
```

#### Forgot Password (request)

```
POST /api/v1/auth/forgot-password
Authentication: None
```

Request
```json
{ "channel": "email", "email": "asha@example.com" }
```

Success `200` — **identical response regardless of whether the account exists** (§10):
```json
{
  "success": true,
  "message": "If an account exists for this contact, reset instructions have been sent.",
  "data": null,
  "error": null
}
```

Failure `429`
```json
{
  "success": false,
  "message": "Too many reset requests. Try again later.",
  "data": null,
  "error": { "code": "RATE_LIMITED" }
}
```

#### Reset Password (confirm)

```
POST /api/v1/auth/reset-password
Authentication: None
```

Request — link mode
```json
{ "token": "rst_9f8c...", "newPassword": "N3wStr0ng!Pass" }
```

Request — OTP mode
```json
{ "identifier": "asha@example.com", "otp": "482913", "newPassword": "N3wStr0ng!Pass" }
```

Success `200`
```json
{
  "success": true,
  "message": "Password updated. Please log in.",
  "data": null,
  "error": null
}
```
Side effect: all existing refresh tokens for this user are revoked (force re-login everywhere) — see §13.

Failure `400`
```json
{
  "success": false,
  "message": "This reset link is invalid or has expired.",
  "data": null,
  "error": { "code": "RESET_TOKEN_EXPIRED" }
}
```
(or `RESET_TOKEN_INVALID`, `OTP_INVALID`, `OTP_EXPIRED`, `OTP_MAX_ATTEMPTS_EXCEEDED` — see §15 for the full table)

#### Refresh Token

```
POST /api/v1/auth/refresh-token
Authentication: Refresh token (cookie or body, per X-Client-Platform)
```

Request — mobile
```json
{ "refreshToken": "eyJ..." }
```
Request — web: empty body, token read from cookie.

Success `200`
```json
{
  "success": true,
  "message": "Token refreshed.",
  "data": {
    "accessToken": "eyJ...",
    "accessTokenExpiresIn": 3600,
    "refreshToken": "eyJ..."
  },
  "error": null
}
```
`refreshToken` in body only for `mobile`; `web` gets the rotated token set as a new cookie.

Failure `401`
```json
{
  "success": false,
  "message": "Session expired. Please log in again.",
  "data": null,
  "error": { "code": "REFRESH_TOKEN_EXPIRED" }
}
```
(or `REFRESH_TOKEN_INVALID`, `REFRESH_TOKEN_REUSE_DETECTED`)

#### Logout

```
POST /api/v1/auth/logout
Authentication: Access token required
```

Revokes the presented refresh token (and, for "log out everywhere," all tokens in the user's session — project decision whether logout is single-session or all-sessions by default; single-session is the safer default).

Success `200`
```json
{ "success": true, "message": "Logged out.", "data": null, "error": null }
```

### 12. Backend Processing Flow

**Register**
```
Receive request → Validate payload (Zod) → Normalize email (lowercase, trim)
→ Check email uniqueness → Hash password → Insert user row
→ Create session + issue access/refresh token pair → Persist refresh token
  (hashed, never store raw token) → Log registration event → Respond
```

**Login**
```
Receive request → Validate payload → Look up user by email
→ If not found OR password mismatch: increment failed-attempt counter,
  respond INVALID_CREDENTIALS (identical response either way)
→ If found + match: reset failed-attempt counter → Issue token pair
  → Persist refresh token (hashed) → Log login event → Respond
```

**Forgot Password**
```
Receive request → Validate payload → Look up account (do not branch
response on found/not-found) → If found: generate token/OTP, hash it,
persist with expiry, dispatch via email/SMS provider
→ Always respond with the same generic success message → Log attempt
```

**Reset Password**
```
Receive request → Validate payload → Look up pending token/OTP by hash
→ Check not expired, not consumed, attempt count under limit
→ If OTP: verify digits match, else increment attempt counter and fail
→ Hash new password → Update user row → Mark token/OTP consumed
→ Revoke all existing refresh tokens for this user → Log event → Respond
```

**Refresh Token**
```
Receive request → Extract token (cookie or body per X-Client-Platform)
→ Look up by hash → Check not expired, not revoked
→ If already rotated-away/revoked: REVOKE ENTIRE TOKEN FAMILY,
  respond REFRESH_TOKEN_REUSE_DETECTED
→ Else: mark current token rotated, issue new access+refresh pair,
  link new token to same family → Persist → Respond
```

See the `backend-architecture` skill for where each step lives in the `api/ logic/ contract/ data/` layout — validation and orchestration in `logic/`, persistence in `data/`.

### 13. Database Impact

```
users
  id (pk), name, email (unique index), passwordHash,
  failedLoginAttempts, lockedUntil (nullable),
  createdAt, updatedAt

refresh_tokens
  id (pk), userId (fk), tokenHash (unique), familyId,
  sessionId, issuedAt, expiresAt, revokedAt (nullable),
  replacedByTokenId (nullable, fk → refresh_tokens.id),
  userAgent, ip

password_reset_requests
  id (pk), userId (fk), channel (email|sms),
  tokenHash (nullable), otpHash (nullable),
  attempts, expiresAt, consumedAt (nullable), createdAt
```

Never store a raw refresh token, reset token, or OTP — only a hash (same treatment as passwords). This is what makes a DB read/leak non-catastrophic for session security. Indexes: `refresh_tokens.tokenHash`, `refresh_tokens.familyId`, `password_reset_requests.tokenHash`/`otpHash`, all unique or lookup-optimized. See the `database-orm` skill for Prisma conventions.

### 14. Permissions

```
Guest             → register, login, forgot-password, reset-password : allowed
Authenticated     → refresh-token, logout                            : allowed
Anyone            → any other auth endpoint variant                  : N/A, none exist
```

Enforcement split, per the `auth-infrastructure` skill:
- **Optimistic check** (redirect-only, e.g. "already logged in, skip the login page") lives in `proxy.ts` via `shared/proxy/auth.ts`.
- **Actual token validation** (signature, expiry, revocation, rotation, reuse detection) happens in the route handler's `logic/` layer, on every request that needs it — never trust proxy-layer or client-side state as the authorization decision itself.

This module has no role/permission matrix of its own — the token payload (below) intentionally carries no roles or permissions, so there is nothing to gate here beyond "is this a valid, non-revoked session."

**JWT payload — identical for access and refresh, `type` distinguishes them:**
```json
{
  "sub": "usr_01H...",
  "sid": "sess_01H...",
  "jti": "tok_01H...",
  "type": "access",
  "iat": 1735900000,
  "exp": 1735903600
}
```
No roles, no permissions, no email, no name in the payload — identity and session metadata only, per the `auth-infrastructure` skill. Anything else needed by a request is fetched server-side by `sub`.

### 15. Error Codes

Every failure mode gets a defined code — never a bare ad-hoc message. Frontend logic switches on `error.code`, never on `message` (message is for display, code is for logic).

| Code | HTTP | Endpoint(s) | Meaning |
|---|---|---|---|
| `VALIDATION_ERROR` | 400 | all | Payload failed schema validation; `error.details` holds per-field messages |
| `EMAIL_ALREADY_EXISTS` | 409 | register | Email already registered |
| `INVALID_CREDENTIALS` | 401 | login | Wrong email or password — deliberately generic, never distinguishes which |
| `ACCOUNT_LOCKED` | 423 | login | Too many failed attempts, temporary lockout |
| `RATE_LIMITED` | 429 | forgot-password | Too many requests in the window (see §10) |
| `RESET_TOKEN_INVALID` | 400 | reset-password | Token doesn't exist / already consumed |
| `RESET_TOKEN_EXPIRED` | 400 | reset-password | Token past its expiry |
| `OTP_INVALID` | 400 | reset-password | Digits don't match |
| `OTP_EXPIRED` | 400 | reset-password | Past 10-minute window |
| `OTP_MAX_ATTEMPTS_EXCEEDED` | 400 | reset-password | 5 wrong attempts — must request a new OTP |
| `AUTH_TOKEN_EXPIRED` | 401 | any authenticated endpoint | Access token expired — signal to the client to run the refresh flow |
| `AUTH_REQUIRED` | 401 | any authenticated endpoint | No/malformed access token presented |
| `REFRESH_TOKEN_INVALID` | 401 | refresh-token | Token malformed / not found |
| `REFRESH_TOKEN_EXPIRED` | 401 | refresh-token | Past its 90-day expiry |
| `REFRESH_TOKEN_REUSE_DETECTED` | 401 | refresh-token | Already-rotated token reused — full family revoked, force re-login |

`INVALID_CREDENTIALS` and the forgot-password generic-success rule (§10) are the two places where "give the user maximum information" is deliberately overridden by "don't leak account existence." Do not add a more specific error code here later without re-reviewing that tradeoff.

If a project also wants to rate-limit `reset-password` confirmation attempts (distinct from the per-OTP `OTP_MAX_ATTEMPTS_EXCEEDED` limit), add a matching rule to §10 and a test case to §20 first — don't reuse `RATE_LIMITED` here without one.

### 16. Frontend Behaviour

```
VALIDATION_ERROR              → inline, per-field error under each field from error.details
EMAIL_ALREADY_EXISTS          → inline error under the email field
INVALID_CREDENTIALS           → inline error under the password field (form-level is also fine)
ACCOUNT_LOCKED                → toast/banner with the retry-after context
RATE_LIMITED                  → toast: "Too many attempts, try again later"
RESET_TOKEN_INVALID/EXPIRED   → full-page state on the reset screen: "Link invalid or expired,
                                 request a new one" (not a toast — user has no other context)
OTP_INVALID                   → inline under the OTP field, attempts remaining if available
OTP_EXPIRED                   → inline under the OTP field, offer "resend"
OTP_MAX_ATTEMPTS_EXCEEDED     → replace form with "request a new code"
AUTH_TOKEN_EXPIRED            → invisible to the user — triggers silent refresh (§17), not shown
REFRESH_TOKEN_EXPIRED/INVALID/
REUSE_DETECTED                → clear stored tokens, redirect to Login,
                                 optional toast: "Session expired, please log in again"

Success (register/login)      → store tokens per §11 transport rule, redirect to authenticated home
Success (forgot-password)     → replace form with the generic confirmation message (§11) — same
                                 UI regardless of whether the account existed
Success (reset-password)      → redirect to Login with a confirmation toast
```

### 17. Loading Behaviour

Standard forms (register, login, forgot-password, reset-password):
```
Disable submit → show spinner on button → on response, re-enable
(success navigates away, so re-enable is mainly for the failure path)
```

**Refresh token — the one non-standard case, and the most common source of real bugs:**
```
Access token expires → some request gets AUTH_TOKEN_EXPIRED
→ Client HTTP layer must single-flight the refresh call: if a refresh is
  already in progress, every other failed request queues behind that
  ONE in-flight refresh promise instead of firing its own refresh call.
→ Why this matters: refresh tokens rotate on use (§10). Two concurrent
  refresh calls racing on the same (soon-to-be-invalidated) token will
  have one succeed and one hit REFRESH_TOKEN_REUSE_DETECTED, incorrectly
  logging the user out.
→ On refresh success: retry all queued requests with the new access token.
→ On refresh failure: fail all queued requests, force logout.
This has no visible UI — it must not show a spinner or block navigation
unless every in-flight request depends on its result.
```

### 18. Notifications

```
Email        : Yes — reset link (link mode) or OTP (email channel)
SMS/WhatsApp : Yes, if OTP channel is "sms" — project decision whether SMS is offered at all
Push         : No
```

### 19. Audit Logs

Log at minimum: login success, login failure (with reason code), account lockout triggered, password reset completed, refresh-token reuse detected (security-relevant — alert-worthy, not just logged), logout. Capture: userId (when known), timestamp, IP, user agent. Do not log passwords, tokens, OTPs, or reset tokens — hash or omit.

### 20. Test Cases

```
Happy path
  Register with valid data                          → 201, tokens issued
  Login with correct credentials                     → 200, tokens issued
  Forgot-password + link flow end to end              → password changes, old sessions revoked
  Forgot-password + OTP flow end to end                → password changes, old sessions revoked
  Refresh a valid, unexpired, unused refresh token     → 200, new token pair, old one now invalid

Validation
  Register with existing email                        → EMAIL_ALREADY_EXISTS
  Register with weak password                         → VALIDATION_ERROR
  Login with wrong password                            → INVALID_CREDENTIALS (not "wrong password")
  Login with non-existent email                        → INVALID_CREDENTIALS (identical to above)
  Reset-password with both token and otp present       → VALIDATION_ERROR
  Reset-password with neither token nor otp present    → VALIDATION_ERROR

Security-critical edge cases
  6th failed login within 15 min                       → ACCOUNT_LOCKED
  Forgot-password for an email that doesn't exist      → identical generic success as one that does
  4th forgot-password request within an hour            → RATE_LIMITED
  Reuse an already-rotated refresh token                → REFRESH_TOKEN_REUSE_DETECTED,
                                                            entire family revoked
  Use refresh token after 90-day expiry                 → REFRESH_TOKEN_EXPIRED
  Use reset token after 60-minute expiry                → RESET_TOKEN_EXPIRED
  6th OTP attempt                                       → OTP_MAX_ATTEMPTS_EXCEEDED
  Two concurrent 401s trigger two "simultaneous" refreshes
    → only one network call fires (single-flight), both original
      requests eventually succeed

Boundary
  Password exactly 8 chars, meets all classes          → accepted
  Password 7 chars                                     → rejected
  Password exactly 128 chars                            → accepted
  Password 129 chars                                    → rejected
```

See the `testing-strategy` skill for unit vs. integration split — token rotation and reuse-detection logic is a strong candidate for integration tests since it spans the token store and multiple sequential requests.

### 21. Dependencies

```
Requires: User table/module (this contract owns its creation, so nothing upstream)
Requires: Email delivery provider (reset link / OTP-by-email)
Requires: SMS delivery provider — only if OTP-by-SMS is in scope for the project
```

Every other authenticated feature in the project depends on this module — it is typically the first vertical slice built.

### 22. Definition of Done

```
✓ All 6 endpoints implemented per §11 exactly (paths, methods, payload shapes)
✓ Response envelope matches §11 examples byte-for-byte in shape (not just "similar")
✓ Every error in §15 implemented with the exact code string
✓ Refresh token rotation + reuse detection implemented and tested
✓ Cookie vs. bearer transport branches correctly on X-Client-Platform
✓ Password/token/OTP hashing in place — no raw secrets in the DB or logs
✓ Rate limiting + lockout thresholds match §10
✓ Frontend single-flight refresh queue implemented (§17)
✓ Frontend error-code → UI mapping matches §16 exactly
✓ Audit logging in place per §19
✓ Swagger/Postman updated
✓ Review approved, merged
```

### 23. Future Improvements

Explicitly out of scope for this contract — do not fold these into the base implementation:
```
Multi-factor authentication (TOTP/authenticator app)
Email verification flow (registration currently does not require it)
Social/OAuth login (Google, Apple, etc.)
"Active sessions" device management UI (list + revoke individual sessions)
"Log out of all devices" as a distinct action from single-session logout
Passwordless / magic-link login
```

## How this fits the ES workflow

For any request to build a new feature end-to-end (not a bugfix or small change), check for an existing contract before proposing structure — treat it as current-state alongside the code graph (`request-workflow` step 4). If none exists and the feature warrants one (see "When to write one"), either write it first or flag that one is missing before jumping to implementation. If a contract exists and the code disagrees with it, flag the drift rather than silently trusting one over the other.
