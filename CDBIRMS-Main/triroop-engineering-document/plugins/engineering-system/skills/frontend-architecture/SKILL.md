---
name: frontend-architecture
description: ES frontend folder structure across both platforms — Next.js App Router (Server/Client Component boundary) and Flutter (Clean Architecture + MVVM). Use when adding or editing UI code, deciding where a new component/hook/model/viewmodel/data-fetcher belongs, or deciding whether something needs "use client".
---

# ES Frontend Structure

Frontend uses a clean feature-based structure, built on Clean Architecture. The three layers — presentation, domain, data — and the dependency rule between them (presentation → domain → data, never reversed) are the same on every platform. What differs per platform is how the **presentation** layer is implemented internally: Next.js uses Server/Client Components + hooks; Flutter uses MVVM. Pick the section below for the platform you're working in.

---

## Web (Next.js)

### `app/` is routing-only

Next.js App Router's `app/` directory is reserved for routing files only: `page.tsx`, `layout.tsx`, `route.ts`, `loading.tsx`, `error.tsx`. Route files stay thin — they import from the matching feature folder and compose, with no real logic of their own.

### Feature code lives in `features/<name>/`

```
features/<name>/
├── components/   # Screens, layouts, visual components
├── hooks/        # Business logic, client-side state, application flow
├── model/        # Types and data structures
└── api/          # Data fetching, Server Actions, external data handling
```

- **`components/`** — Server Components by default. A component only gets `"use client"` when it genuinely needs interactivity, browser APIs, or client-only state.
- **`hooks/`** — business logic and client-side state management (`useState`/`useMemo`-driven filtering, TanStack Query/Zustand/Jotai usage).
- **`model/`** — plain type definitions and data structures for the feature, no logic.
- **`api/`** — static content, data fetching, Server Actions.

Cross-cutting UI (site-wide nav, header, footer) is not "feature" content — it belongs in `shared/components/`, not inside any one feature's folder.

This structure is flatter than Flutter's nested `presentation/domain/data` — `hooks/` and `api/` each span more than one Clean Architecture layer. The layering discipline (dependency direction, contracts before implementations) still applies; there are just fewer physical folders enforcing it.

### Server / Client Component boundary

Default to Server Components. Opt into `"use client"` per-component, not per-feature, only where interactivity is actually required (e.g. a category filter using `useState`/`useMemo`, a mobile nav toggle). This decision must be made explicitly for every component — there's no repo-wide default that makes it for you.

### Stack

Next.js (App Router), React Server Components, TanStack Query / Zustand (or Jotai) for client-side state, Server Actions for mutations where applicable.

### Before writing code in a new Next.js major version

If the project's `AGENTS.md`/`CLAUDE.md` flags that the installed Next.js version has breaking changes from training data, check `node_modules/next/dist/docs/` for the relevant page (layouts/pages, linking, images, fonts, metadata) before assuming current App Router conventions match what you already know.

---

## Mobile (Flutter)

### Feature folder structure

```
features/<name>/
├── presentation/
│   ├── pages/        # Screens
│   ├── widgets/       # Reusable UI pieces
│   └── viewmodels/    # UI state + presentation logic
├── domain/
│   ├── entities/      # Business objects
│   ├── repositories/  # Contracts (interfaces) only
│   └── usecases/      # One business action each
└── data/
    ├── models/        # fromJson()/toJson(), API/DB mapping
    ├── repositories/  # Contract implementations
    └── datasources/
        ├── remote/    # REST, Firebase, Supabase
        └── local/     # SQLite, Hive, SharedPreferences, secure storage
```

### MVVM (presentation layer only)

- **View** (page/widget) — displays UI, observes the ViewModel. Never calls APIs, touches a database, or parses JSON.
- **ViewModel** — holds UI state (`isLoading`, `errorMessage`, `selectedTab`), handles presentation logic, calls use cases. Never calls HTTP directly, queries a database, or parses JSON.

### Dependency rule

`View → ViewModel → UseCase → Repository (contract) → Repository Implementation → Data Source`. Data must never know Presentation; Domain must never know Flutter; Presentation must never know the database.

### Stack

Flutter, Riverpod, Clean Architecture + MVVM.

Full spec (naming conventions, request/response flow, complete rule set): `CLEAN_ARCHITECTURE_AND_MVVM.md` in the project repo, if present.
