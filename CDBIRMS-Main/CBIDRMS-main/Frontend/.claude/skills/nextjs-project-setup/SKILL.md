---
name: nextjs-project-setup
description: Scaffold a brand-new Next.js App Router project in any target directory — runs create-next-app, reshapes it into ES's app/ (routing-only) + features/<name>/{components,hooks,model,api} + shared/ folder convention, seeds a first working vertical slice, and offers to chain into nextjs-deployment-setup for Docker/CI. Use when asked to create, scaffold, bootstrap, or start a brand-new Next.js project or app — not for adding deployment infra to an existing project (see nextjs-deployment-setup) or for documenting the target folder shape only (see frontend-architecture).
---

# ES Next.js Project Setup

The creation-only counterpart to two existing skills that don't cover this: `nextjs-deployment-setup` assumes a project already exists (it adds Docker/CI to one); `frontend-architecture` documents the target folder shape but has no action of its own. This skill takes a project from "doesn't exist" to "ES-shaped and running," in a directory of the user's choosing — not necessarily the current working directory.

## Step 0 — Confirm scope and target directory before touching anything

Ask (unless already unambiguous from the user's request):

1. **Target directory** (absolute or relative path). Required — never assume the current directory is meant, since this skill is explicitly for "any directory."
2. **App/package name.**
3. **Single-app project, or will this repo house multiple apps eventually?** Determines whether `features/` sits at the repo root or under `apps/<name>/` per `frontend-architecture`'s mono-repo note.
4. **Chain into `nextjs-deployment-setup` immediately after scaffolding** (Docker/compose/buildspec/Yarn pinning), or stop after the bare ES-shaped app?

Don't guess (1) or (2). (3) and (4) may default to "single-app" and "skip deployment infra for now" if the user doesn't state a preference and nothing in the request implies otherwise — but say which defaults you assumed.

## Step 1 — Make sure the target directory is safe to write into

- If it doesn't exist, create it.
- If it exists and is non-empty, list its contents and confirm with the user before running `create-next-app` into it — never silently overwrite.
- If it's already a git repo with commits, treat existing files as someone's in-progress work: surface what's there and ask, rather than clobbering it.

## Step 2 — Scaffold with create-next-app

```
yarn create next-app <target-dir> --typescript --eslint --app --src-dir=false --import-alias "@/*"
```

- **Yarn, not npm/pnpm** — matches ES's package-manager convention for Next.js frontends (see `deployment-infrastructure`), unless the user explicitly asks for a different package manager.
- **No `src/` directory** — `frontend-architecture` puts `app/` at the project root, not under `src/`.
- If the new project's `AGENTS.md`/`CLAUDE.md` (or the installed `next` version) flags breaking changes from training-data conventions, check `node_modules/next/dist/docs/` before assuming current App Router behavior — same rule `frontend-architecture` states.

## Step 3 — Reshape into ES's frontend-architecture convention

Per `frontend-architecture`:

- Trim the `create-next-app` boilerplate in `app/` down to routing files only (`page.tsx`, `layout.tsx`, `globals.css`, etc.) — no real logic there.
- Create `shared/components/` (and `shared/lib/` if needed) for cross-cutting UI/utilities that aren't owned by one feature.
- Create one first feature folder, `features/<slug>/{components,hooks,model,api}/`, and move the starter page's real content into `features/<slug>/components/`, wired back into `app/page.tsx` as a thin import. This is not optional busywork — it's what satisfies `vertical-slice-philosophy`'s "every phase produces a working, visible output": the app must still render after this step, not sit broken with empty folders until some future phase fills them in.
- Don't scaffold backend folders (`logic/`, `api/` route handlers with real business logic) unless the request also asks for backend code — that's `backend-architecture`'s concern and out of scope here unless asked.

## Step 4 — Verify it actually runs

`yarn dev` (or the workspace-qualified form, `yarn workspace <app-name> dev`, if mono-repo per Step 0) and confirm the app boots and the seeded feature slice renders. Don't report success without having actually run it.

## Step 5 — Offer to chain into deployment setup

If the user opted in at Step 0: hand off to `nextjs-deployment-setup` for Docker/compose/buildspec/Yarn-pinning. That skill asks its own step-0 scope question (full setup vs. specific parts vs. reference-only) — don't duplicate it here; just launch it with the app name and mono-repo/single-app choice already known from this skill's Step 0, so the user isn't asked the same thing twice.

If the user declined: stop here and say so explicitly. Don't silently add deployment infra nobody asked for.

## Why this exists

Neither `nextjs-deployment-setup` nor `frontend-architecture` gets a brand-new, from-zero Next.js project to ES's actual starting shape — one assumes the project exists, the other only documents the target. This skill is the missing first step in that chain.
