# TES Frontend Structure

Frontend uses a clean feature-based structure, built on **Clean Architecture**.

Clean Architecture organizes every feature into three layers — presentation, domain, data. This three-layer split, and the dependency rule between them, is the same on every platform TES targets. What changes per platform is *how the presentation layer is implemented internally* — that part gets a platform-specific pattern (MVVM for Flutter, Server/Client Components for Next.js), documented in its own sibling file.

Each Flutter feature contains:

```txt
presentation/
    pages/
    widgets/
    viewmodels/
domain/
    entities/
    repositories/
    usecases/
data/
    models/
    repositories/
    datasources/
        remote/
        local/
```

Each Next.js feature contains a flatter structure (see [CLEAN_ARCHITECTURE_AND_NEXTJS.md](CLEAN_ARCHITECTURE_AND_NEXTJS.md) for why it isn't nested the same way):

```txt
features/<name>/
    components/
    hooks/
    model/
    api/
```

## Layer Meaning

### presentation/

Displays UI and holds UI/presentation state. Never calls APIs, touches a database, or parses JSON directly — it only talks to the domain layer's use cases. How this is implemented depends on the platform:

* **Flutter (mobile):** MVVM. Pages/widgets (View) display UI and observe state; viewmodels hold UI state and presentation logic, and call use cases. See [CLEAN_ARCHITECTURE_AND_MVVM.md](CLEAN_ARCHITECTURE_AND_MVVM.md).
* **Next.js (web):** Server/Client Components + hooks. There is no single "ViewModel" object — Server Components fetch and render with no client state, while Client Component hooks hold UI state and call use cases. See [CLEAN_ARCHITECTURE_AND_NEXTJS.md](CLEAN_ARCHITECTURE_AND_NEXTJS.md).

### domain/

Business rules, independent of any UI framework, HTTP, or database. Entities are business objects; usecases execute one business action each; repositories are contracts (interfaces) only — no implementation. This layer's responsibilities are identical on Flutter and Next.js, even where Next.js doesn't give it a dedicated folder.

### data/

Implementation layer. Repository implementations fulfill the domain contracts and convert models to entities; datasources (remote/local) talk to REST APIs, Firebase, Supabase, Server Actions, or local storage; models handle serialization (`fromJson()`/`toJson()` in Flutter, Zod parsing in Next.js) and API/database mapping. Same responsibilities on both platforms — only the concrete datasource implementations differ.

## Stack by platform

* **Mobile:** Flutter, Riverpod, Clean Architecture + MVVM
* **Web:** Next.js (App Router), React Server Components, TanStack Query / Zustand, Clean Architecture + Server/Client Components

See [CLEAN_ARCHITECTURE_AND_MVVM.md](CLEAN_ARCHITECTURE_AND_MVVM.md) for the full Flutter layer responsibilities, request/response flow, naming conventions, and rules — or [CLEAN_ARCHITECTURE_AND_NEXTJS.md](CLEAN_ARCHITECTURE_AND_NEXTJS.md) for the Next.js equivalent.
