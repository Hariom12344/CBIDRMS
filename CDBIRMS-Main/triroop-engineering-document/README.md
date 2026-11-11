# Triroop Engineering System (TES) — Documentation

This repository holds the design documentation for **TES (Triroop Engineering System)**: Triroop Techconsult's reusable software engineering system for building projects in a clean, structured, scalable, and repeatable way, with a focus on AI-assisted development.

> Every development phase should produce a working and visible output.

TES is not tied to one project. It's meant to be the standard, reusable engineering process for future Triroop projects — a consistent architecture, API design, database approach, and workflow that both developers and AI tools can navigate predictably.

**Status:** Living document. Infrastructure scaling, CI/CD automation, deeper analytics, and testing coverage are still open and will be finalized through real project experience — see [13 · Future Scope and Vision](13-future-scope-and-vision.md).

---

## How this repository is organized

The original concept note has been split into focused topic files so each concern can be read, edited, and referenced independently. Read them in order for the full picture, or jump straight to the topic you need.

| # | File | Covers |
|---|------|--------|
| 00 | [Overview and Philosophy](00-overview-and-philosophy.md) | What TES is, why it was created, the four core principles, and the standardization goal |
| 01 | [Frontend Structure](01-frontend-structure.md) | Feature-based frontend folder layout, shared Clean Architecture across platforms — Flutter (MVVM) for mobile, Next.js (Server/Client Components) for web |
| 02 | [Backend Structure](02-backend-structure.md) | Feature-based backend folder layout: `api/ logic/ contract/ data/` |
| 03 | [Vertical Slice Development](03-vertical-slice-development.md) | The slice model — every feature built end-to-end — with example slices and what makes a slice complete |
| 04 | [AI Context Planning System](04-ai-context-planning.md) | Structured planning docs written before coding starts, to keep AI-assisted development accurate and consistent |
| 05 | [Branching and Deployment System](05-branching-and-deployment.md) | Git branch model, release management, CI/CD (GitHub Actions), and the Vercel/Supabase release pipeline |
| 06 | [API Architecture](06-api-architecture.md) | API design goals, versioning (`/api/v1/`), resource-based routing, and standard HTTP methods |
| 07 | [Middleware and Authentication](07-middleware-and-authentication.md) | Middleware-based request pipeline and JWT access/refresh token authentication |
| 08 | [API Payloads and Validation](08-api-payloads-and-validation.md) | Standard success/error JSON response shape and schema-based validation (Zod) |
| 09 | [Database and ORM](09-database-and-orm.md) | Stack (PostgreSQL, Supabase, Prisma), why each was chosen, and core database engineering principles |
| 10 | [Analytics and Monitoring](10-analytics-and-monitoring.md) | Event-driven analytics tracked via middleware, and what it's for |
| 11 | [Testing Philosophy](11-testing-philosophy.md) | Unit and integration testing focus and goals |
| 12 | [Knowledge Transfer Focus](12-knowledge-transfer.md) | Designing the system so new developers can onboard without depending on one person |
| 13 | [Future Scope and Vision](13-future-scope-and-vision.md) | Open decisions (infrastructure, CI/CD, analytics, testing) and the long-term vision |
| 14 | [SEO and Metadata](14-seo-and-metadata.md) | Cross-cutting SEO for web (Next.js) properties: metadata API, sitemap/robots generation, JSON-LD structured data, heading/image semantics, and title/description content-quality standards |
| 15 | [Feature Contract Template](15-feature-contract-template.md) | The single source of truth spec written before a feature is built — full (23-section) and lean (13-section) versions, business objective, user story, fields/validation, API contract, error codes, permissions, test cases, definition of done |
| — | [Clean Architecture + MVVM Guidelines](CLEAN_ARCHITECTURE_AND_MVVM.md) | The detailed **Flutter (mobile)** implementation spec behind file 01: full layer responsibilities (View, ViewModel, UseCase, Repository, Data Sources, Models, Entities), request/response flow, naming conventions, and hard rules |
| — | [Clean Architecture + Next.js Guidelines](CLEAN_ARCHITECTURE_AND_NEXTJS.md) | The **Next.js (web)** equivalent of the above: Server/Client Components + hooks in place of MVVM, same Domain/Data layer responsibilities, request/response flow, naming conventions, and hard rules |

The original, unsplit note — [`Triroop Engineering System (TES) – Concept Note.md`](<Triroop Engineering System (TES) – Concept Note.md>) — is kept in the repo root for reference and history. Treat the numbered files above as the current source of truth; update them going forward rather than the original note.

---

## Core principles at a glance

1. **Every phase must work independently** — no incomplete or placeholder phases; each phase ships a working frontend, backend, database flow, and visible output.
2. **The current phase never depends on a future phase** — it may reuse output from earlier features, but never waits on unbuilt ones.
3. **Vertical slice development** — each feature (authentication, billing, dashboard, ...) is built end-to-end in one slice: frontend + backend + validation + business logic + database, and is independently understandable, testable, and maintainable.
4. **AI-friendly engineering** — predictable structure, naming, and API design so AI tools understand a TES project with minimum context.

Details for each are in [00 · Overview and Philosophy](00-overview-and-philosophy.md).

---

## Planned stack

* **Frontend (mobile):** Flutter, Riverpod, Clean Architecture + MVVM
* **Frontend (web):** Next.js (App Router), React Server Components, TanStack Query / Zustand, Clean Architecture + Server/Client Components
* **SEO (web):** Next.js Metadata API, generated sitemap.xml/robots.txt, JSON-LD structured data
* **Backend architecture:** Modular Monolith, REST APIs
* **Database:** PostgreSQL on Supabase, via Prisma ORM
* **Validation:** Zod
* **Auth:** JWT (access + refresh tokens)
* **Deployment:** Vercel, GitHub Actions

---

## Installing the Claude Code plugin

This repository doubles as a Claude Code plugin marketplace. It ships the **engineering-system** plugin — the ES skills, conventions, and request-workflow enforcement described above — as an installable Claude Code plugin, so any project can pull in TES/ES guidance directly inside Claude Code.

1. Add this repository as a plugin marketplace:

   ```
   /plugin marketplace add triroop-techconsult/triroop-engineering-document
   ```

   (or with the full URL: `/plugin marketplace add https://github.com/triroop-techconsult/triroop-engineering-document.git`)

2. Install the plugin from that marketplace:

   ```
   /plugin install engineering-system@triroop-engineering-document
   ```

3. Restart Claude Code (or run `/plugin` to confirm it's listed as installed and enabled).

Once installed, the `engineering-system` skill set (architecture, API design, auth, database/ORM, validation, proxy, testing strategy, feature contracts, etc.) is available in any project you use Claude Code in — see [plugins/engineering-system](plugins/engineering-system) for the plugin source.

To update later, run `/plugin marketplace update triroop-engineering-document` followed by `/plugin update engineering-system`.

---

## Contributing to this documentation

TES is still evolving. When you learn something from real project work that should change or extend these docs:

1. Edit the relevant numbered file (not the original concept note).
2. Keep one topic per file — if a change doesn't fit any existing file, propose a new numbered file rather than overloading an existing one.
3. Update this README's table if you add, rename, or remove a file.
4. Open a PR so changes are reviewed before they become part of the standard.

---

## Ownership

Internal engineering documentation of **Triroop Techconsult Pvt Ltd**.
