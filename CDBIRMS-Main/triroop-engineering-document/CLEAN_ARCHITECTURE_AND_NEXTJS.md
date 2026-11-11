# Clean Architecture + Next.js Guidelines

Version: 1.0

Platform: **Next.js (web)**. This is the presentation-layer implementation spec referenced from [01-frontend-structure.md](01-frontend-structure.md). For the Flutter/mobile equivalent, see [CLEAN_ARCHITECTURE_AND_MVVM.md](CLEAN_ARCHITECTURE_AND_MVVM.md).

---

# Objective

This project follows **Clean Architecture**, implemented on the web via Next.js **Server/Client Components** instead of MVVM.

Clean Architecture organizes the entire application.

There is no single "ViewModel" object on the web. Its responsibilities split across Server Components (fetch + render, no client state) and Client Component hooks (client state + presentation logic).

Both coexist and complement each other.

---

# Architecture Overview

```
Presentation (Server/Client Components)
        ↓
Domain
        ↓
Data
```

---

# Presentation Layer

## Server Component

Responsibilities

- Fetch initial data (via the `api/` layer)
- Render UI
- Compose Client Components where interactivity is needed

Server Component must NEVER

- Hold client-only state (`useState`, `useEffect`)
- Use browser APIs
- Import client-only libraries

---

## Client Component + Hook

The `"use client"` component is the View; its paired hook is the ViewModel-equivalent.

Responsibilities

- Display UI, collect user input
- Hold UI state (via the hook)
- Handle presentation logic
- Validate UI inputs
- Call use cases
- Update UI state

Examples

- isLoading
- errorMessage
- selectedTab
- form state (controlled inputs / React Hook Form)

Client Component + Hook must NEVER

- Call HTTP directly, bypassing `api/`
- Query the database directly
- Parse raw JSON outside the data layer

---

## `app/` is routing only

Next.js App Router's `app/` directory holds routing files only: `page.tsx`, `layout.tsx`, `route.ts`, `loading.tsx`, `error.tsx`. These stay thin — they import from the matching `features/<name>/` folder and compose, with no real logic of their own.

---

# Domain Layer

The Domain layer contains business rules.

It has no dependency on React, Next.js, HTTP, or Database.

---

## Entity

Entity represents business objects.

Example

```
User
Project
Invoice
PurchaseOrder
```

Entities never contain

- Serialization logic
- HTTP
- Database code

---

## Use Case

A Use Case represents one business action.

Examples

```
loginUser
registerUser
createProject
approveInvoice
generateBOQ
assignWorker
```

Responsibilities

- Execute Business Rules
- Coordinate repositories
- Return Entities

Use Cases must NEVER

- Parse JSON directly
- Know HTTP
- Know Firebase

---

## Repository (Contract)

Repository is a Contract.

It defines WHAT operations are available.

Example

```typescript
interface AuthRepository {
  login(email: string, password: string): Promise<UserEntity>;
  logout(): Promise<void>;
}
```

Repository never contains implementation.

Think

"What can be done?"

NOT

"How it is done."

---

# Data Layer

Contains implementation.

---

## Repository Implementation

Implements Repository Contract.

Responsibilities

- Fulfill Repository Contract
- Convert Model → Entity
- Call Data Sources

Think

"How is the contract fulfilled?"

---

## Remote Data Source

Responsible for

- REST API
- Server Actions
- Firebase
- Supabase
- External Services

Responsibilities

- HTTP requests / Server Action calls
- Parse API response
- Return Models

Must NEVER contain Business Logic.

---

## Client-side Storage

Responsible for

- Cookies (session-adjacent, non-sensitive UI state)
- localStorage / IndexedDB

Used far less than Flutter's Local Data Source — Next.js favors server-side session handling (httpOnly cookies) over client-persisted state.

---

## Models

Models represent external data.

Examples

```
UserModel
InvoiceModel
ProjectModel
```

Responsibilities

- Parse/serialize (Zod schemas)
- API Mapping
- Database Mapping

Models are NOT Business Objects.

---

# Complete Request Flow

```
User
↓
Client Component (or Server Component)
↓
Hook (if client-side)
↓
UseCase
↓
Repository (Contract)
↓
Repository Implementation
↓
Remote Data Source (api/)
↓
REST API / Server Action / Supabase
```

---

# Complete Response Flow

```
REST API / Server Action / Supabase
↓
Remote Data Source (api/)
↓
UserModel
↓
Repository Implementation
↓
UserEntity
↓
UseCase
↓
Hook
↓
Component
↓
User
```

---

# Responsibilities Summary

| Layer | Responsibility |
|---------|----------------|
| Server Component | Fetch + render, no client state |
| Client Component | UI + input collection |
| Hook | Presentation logic + UI state (ViewModel-equivalent) |
| UseCase | Business Logic |
| Repository | Contract |
| Repository Implementation | Contract Implementation |
| Remote Data Source | API / Server Action |
| Model | External Data Mapping |
| Entity | Business Object |

---

# Dependency Rule

Always

```
Presentation
↓
Domain
↓
Data
```

Never the opposite.

Data must never know Presentation.

Domain must never know React or Next.js.

Presentation must never know the database.

---

# Feature Folder Structure

```
features/<name>/
    components/   # Server Components by default; "use client" only where needed
    hooks/        # Business/presentation logic, client-side state
    model/        # Types and data structures (domain entities + data models)
    api/          # Data fetching, Server Actions, external data handling
```

This is **flatter than Flutter's nested `presentation/domain/data`** — `hooks/` and `api/` each span more than one Clean Architecture layer (e.g. `api/` covers both Repository Implementation and Remote Data Source; `hooks/` covers both View-adjacent state and use-case calls). The layering *discipline* — dependency direction, no layer-skipping, contracts before implementations — still applies; there are just fewer physical folders enforcing it than on Flutter. Treat `presentation/domain/data` as the conceptual model to reason with, not a literal folder tree, on this platform.

Every feature must follow this structure.

---

# Naming Convention

Component (Server or Client)

```
LoginForm.tsx
```

Hook

```
useLogin.ts
```

Use Case (lives in `hooks/` or `api/`)

```
loginUser.ts
registerUser.ts
forgotPassword.ts
```

Repository (Contract)

```
auth.repository.ts
```

Repository Implementation

```
auth.repository.impl.ts
```

Remote Data Source / Server Action

```
auth.api.ts
```

Model

```
user.model.ts
```

Entity

```
user.entity.ts
```

---

# Important Rules

✅ Component never calls Repository directly.

✅ Component talks only to its hook (or fetches via Server Component).

✅ Hook talks only to UseCases.

✅ UseCase talks only to Repository.

✅ Repository is only a Contract.

✅ Repository Implementation fulfills the Contract.

✅ Repository Implementation talks to Data Sources (`api/`).

✅ Data Sources communicate with external systems.

✅ Models belong only to the Data layer.

✅ Entities belong only to the Domain layer.

---

# Mental Model

Component
→ "Show the screen."

Hook
→ "Manage the screen."

UseCase
→ "Perform the business action."

Repository
→ "These operations are available."

Repository Implementation
→ "This is how those operations work."

Remote Data Source
→ "Talk to the server."

Model
→ "Represent external data."

Entity
→ "Represent business data."

---

# Golden Rule

Server/Client Components + hooks exist INSIDE the Presentation Layer.

Clean Architecture organizes the entire application.

```
Presentation (Server/Client Components)

    Component
    Hook

↓

Domain

    UseCases
    Entities
    Repository Contracts

↓

Data

    Repository Implementations
    Remote Data Sources (api/)
    Models
```

This separation must be preserved throughout the project, even though the physical folders are flatter than Flutter's.
