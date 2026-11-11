---
name: nextjs-deployment-setup
description: Interactive, Next.js-only ES deployment scaffolding — mono-repo layout, Dockerfile, docker-compose pull/build pair, buildspec.yaml CI/CD, Yarn version pinning, and the custom-hostname/mkcert local HTTPS pattern. Use when setting up or auditing how a Next.js (not NestJS) project builds, containerizes, and ships, or when a project wants to adopt the company's standard Next.js deployment pattern in full or in part. Asks the user what scope to apply before touching any files.
---

# ES Next.js Deployment Setup

Actionable counterpart to `deployment-infrastructure` (which covers both NestJS and Next.js as read-only reference). This skill is **Next.js-only** and **writes files** — it applies the company's standard Next.js deployment pattern to the current project, but only after the user chooses how much of it they want.

Source of the pattern: a 2026-07 audit of `webapp-v1` (the company's reference implementation), cross-checked against `chat-service`/`lms-service`/`admin-panel`/`lms-webapp`. Full narrative version lives at `docs/nextjs-deployment-standard.md` in `lms-webapp` if present — read it for extra context, but this file is self-contained.

**Do not apply anything before asking.** Different projects want different slices of this — a standalone app doesn't need the mono-repo layout, a project without cross-subdomain auth doesn't need the custom-hostname dev setup, some teams just want the reference read out loud with no files touched.

## Step 0 — Confirm scope with the user

Before reading further into the project or writing anything, ask (single-select):

1. **Full setup** — mono-repo layout + Docker + compose + buildspec + Yarn pinning + local custom-hostname HTTPS, all applied together.
2. **Pick specific parts** — follow up with a multi-select from: Docker & compose files · Yarn/package-manager pinning · CI/CD (buildspec.yaml) · Local custom-hostname HTTPS dev setup · Mono-repo folder layout (`apps/*`/`packages/*`).
3. **Reference only** — explain the patterns, point out gaps versus the current project, don't write or edit anything.

If the user's original request already specified a slice (e.g. "just set up the Dockerfile"), you may skip straight to that instead of asking — but if it's ambiguous, ask.

Before writing anything, also check whether the target repo is actually Next.js (`next` in `package.json` dependencies). If it's NestJS or another stack, stop and point the user at `deployment-infrastructure` instead — this skill doesn't cover backends.

## Step 1 — Read current state before changing anything

Check what already exists so you don't clobber project-specific work:
- Root `package.json` — does it already have a `workspaces` field? A `next` app at the root, or under `apps/`?
- Existing `Dockerfile`, `docker-compose*.yaml`, `buildspec.yaml`, `.yarnrc.yml`, `.dockerignore`.
- Existing `.env.*` files and whether they're gitignored.

If a piece already exists and roughly matches the pattern below, don't rewrite it wholesale — patch the specific gap (e.g. just add `--frozen-lockfile`, just add the missing `ARG`). If it exists but is structured completely differently, surface that to the user before overwriting — don't silently replace someone's working setup.

## Part A — Mono-repo folder layout

Only apply if the project is meant to house (now or later) more than one Next.js app, or the user explicitly wants this shape.

```
package.json          # root: "workspaces": ["apps/*", "packages/*"]
turbo.json
Dockerfile             # root, parameterized via --build-arg APP_NAME
docker-compose.yaml     # root, pull-based
docker-compose-<app>.yaml  # root, build-based, one per app
buildspec.yaml         # root
apps/
  <app-name>/
    package.json        # workspace name = <app-name>
    next.config.ts
    .env.development     # gitignored, never committed
    .env.production       # gitignored, never committed
    certs/                # gitignored, mkcert output
packages/
  ui/                    # shared components consumed by multiple apps
```

A standalone single-app project (no plan to add a second app) does **not** need this — `yarn dev`/`yarn build` at the root, no `apps/` nesting, no `--build-arg APP_NAME`. Forcing the mono-repo shape onto a single-app project is the same mistake as the reverse (copying a mono-repo Dockerfile onto a standalone app without dropping the `apps/${APP_NAME}` path) — ask which one the project actually is before choosing.

## Part B — Dockerfile + `.dockerignore`

Two-stage build, both stages the **same exact** Node image tag:

```dockerfile
FROM node:24.15.0-alpine3.22 AS app-builder
ARG APP_NAME
ARG APP_ENV
ENV APP_ENV=${APP_ENV}
WORKDIR /app
RUN corepack enable && corepack prepare yarn@<pin> --activate
COPY . .
RUN mv apps/${APP_NAME}/.env.${APP_ENV} apps/${APP_NAME}/.env.local
RUN yarn install --frozen-lockfile
RUN yarn workspace ${APP_NAME} build

FROM node:24.15.0-alpine3.22 AS app-runner
ARG APP_NAME
WORKDIR /app
RUN corepack enable && corepack prepare yarn@<same-pin> --activate
COPY --from=app-builder /app ./
EXPOSE 3000
WORKDIR /app/apps/${APP_NAME}
CMD ["yarn", "start"]
```

For a **standalone** (non-mono-repo) app: drop every `apps/${APP_NAME}` segment — `.env.<APP_ENV>` lives at the repo root, build is `RUN yarn build` (no `workspace` target), runner's final `WORKDIR` is just `/app`.

Non-negotiables — these were found broken in the reference implementation, don't repeat them:
- `--frozen-lockfile`, not plain `yarn install`. A plain install lets the lockfile drift between what was tested locally and what CI ships.
- Always ship a `.dockerignore`: `node_modules`, `.git`, `.gitignore`, `*.md`, `.env*`, `.next`, `.turbo`, `coverage`. Without one, `COPY . .` pulls in build caches and stray `node_modules` from outside the target workspace.
- The Yarn version in `corepack prepare yarn@<pin>` must match `.yarnrc.yml`'s `yarnPath` and root `package.json`'s `packageManager` **exactly**. Check all three before considering this step done.

## Part C — `docker-compose` pull/build pair

Two files per app:

```yaml
# docker-compose.yaml — pulls the CI-built image, no build: block
services:
  app:
    image: <account>.dkr.ecr.<region>.amazonaws.com/<unique-image-repo-name>:main-latest
    container_name: <unique-container-name>
    ports:
      - "<unique-local-port>:3000"
    restart: always
    environment:
      - APP_ENV
      - NEXT_PUBLIC_ENV
      # ...rest of this app's env var names (values sourced from the shell/.env file, not hardcoded)
```

```yaml
# docker-compose-<app>.yaml — builds from source, for local dev
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        APP_NAME: <app>
        APP_ENV: ${APP_ENV}
        # any NEXT_PUBLIC_* the Dockerfile actually declares an ARG for — see note below
    container_name: <unique-container-name>
    ports:
      - "<unique-local-port>:3000"
    restart: always
    environment:
      - APP_ENV
      # ...same list as docker-compose.yaml
```

Checks to run before calling this done:
- `<unique-image-repo-name>`, `<unique-container-name>`, `<unique-local-port>` must not collide with another app in the org — grep sibling projects' compose files for the values you're about to pick, don't assume they're free.
- **Every `args:` entry in the build compose file must have a matching `ARG` in the Dockerfile.** An arg with no matching `ARG` is silently dropped — this exact bug was found live in the reference implementation (build args for `JWT_SECRET`, `NEXT_PUBLIC_API_BASE_URL`, etc. were passed but never declared, so they never reached the build).

## Part D — `buildspec.yaml` (CodeBuild CI/CD)

Same three-phase shape for every app — only the variable values change:

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - set -e
      # DockerHub login from Secrets Manager ("dockerhub/credentials") — avoids anonymous pull rate limits
      # Detect branch: $CODEBUILD_WEBHOOK_HEAD_REF if set, else `git rev-parse --abbrev-ref HEAD`; sanitize "/" -> "-"
      # IMAGE_TAG="${BRANCH_NAME}-${BUILD_NUMBER}" (BUILD_NUMBER = `git rev-list --count HEAD`)
      # ECR login
  build:
    commands:
      - |
        # main -> APP_ENV=production
        # develop | feature-* | bug-* | test-* -> APP_ENV=development
        # anything else -> exit 0, no build
        # docker build --build-arg APP_NAME=<app> --build-arg APP_ENV=$APP_ENV .
        # tag + push both $IMAGE_TAG and $BRANCH_NAME-latest
  post_build:
    commands:
      - |
        # same branch gate selects target EC2 instance (prod vs dev)
        # poll `aws ec2 describe-instances` until target is "running"; fail build if it never comes up
        # pull env secrets from Secrets Manager, secret id "<product>/<env>"
        # aws ssm send-command (AWS-RunShellScript): ECR login -> docker pull -> stop/rm old container ->
        #   docker run -d --restart always --name $CONTAINER_NAME -p $HOST_PORT:$CONTAINER_PORT
        #     -e <secrets as -e flags, sourced from the Secrets Manager fetch above> $REPOSITORY_URI:$IMAGE_TAG
```

Two long-lived environments only: `prod` (`main`) and `dev` (`develop` + `feature-*`/`bug-*`/`test-*`, same dev instance). Every other branch builds and deploys nothing — intentional, not a gap.

**The `-e` secrets injection in `post_build` is not optional** — this is the step the reference implementation skipped (left commented out), which is why it ended up baking `.env.production`/`.env.development` into the image at build time instead, and why those files ended up committed to git. Don't repeat that: secrets come from Secrets Manager at deploy time, never from a file `COPY`'d into the image.

## Part E — Yarn / package-manager pinning

Next.js apps use Yarn 4 (Berry), `nodeLinker: node-modules` (not PnP), workspaces even for a single-app repo.

Pin the exact same version in **three** places and verify they match before finishing this part:
1. `.yarnrc.yml` → `yarnPath: .yarn/releases/yarn-<version>.cjs`
2. root `package.json` → `"packageManager": "yarn@<version>"`
3. `Dockerfile` → `corepack prepare yarn@<version> --activate` (both stages)

This 3-way drift is the single most common bug found across audited repos — check it explicitly, don't assume it's already consistent.

Once a repo has `apps/*` workspaces, scripts run through the workspace name, not bare commands: `yarn workspace <app-name> dev`, `yarn workspace <app-name> build`. A standalone (non-workspace) app just uses `yarn dev`/`yarn build` at the root.

## Part F — Local custom-hostname HTTPS dev setup

Only needed if the app does cross-subdomain, cookie-based auth (or otherwise needs to mirror production `Secure`/`SameSite=None` cookie behavior locally) — `localhost` over plain HTTP can't carry those cookies, so browsers silently drop them in dev.

1. **Pick a unique hostname** per app, e.g. `<app>-dev.<company-domain>` — don't reuse another app's.
2. **Hosts file entry** (one-time per developer machine): `127.0.0.1 <app>-dev.<company-domain>` in `/etc/hosts` (or Windows equivalent).
3. **`mkcert -install`** once per machine — registers a locally-trusted CA.
4. **`mkcert <app>-dev.<company-domain>`**, run inside `apps/<app>/certs/` — issues a cert/key pair. Add `certs/*.pem` to `.gitignore`; never commit these.
5. Expose two dev scripts in that app's `package.json`:
   ```json
   "dev": "next dev -H <app>-dev.<company-domain> -p <port>",
   "dev:https": "next dev --experimental-https -H <app>-dev.<company-domain> -p <port>"
   ```
   Plain `yarn dev` (HTTP) should always keep working as the default — this is opt-in, not a replacement.
6. If more control over the HTTPS server is needed than `--experimental-https` gives, add a custom `server.js` (Express + Node `https`, loading the mkcert cert/key) and a `dev:https:custom` script that runs it with `node server.js`.
7. Write a short cert-setup note in the app's own docs (mirroring `cert_setup.txt` in the reference implementation) so new developers on that specific app know the hostname, the mkcert steps, and that HTTPS is optional.

## After applying

Summarize exactly which parts were applied vs. skipped, and any gaps you found relative to this pattern that you did **not** fix (e.g. "found `.env.production` committed to git — flagging, not deleting without confirmation"). Don't silently fix things outside the scope the user chose in Step 0.
