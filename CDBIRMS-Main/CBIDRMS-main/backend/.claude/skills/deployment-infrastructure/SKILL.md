---
name: deployment-infrastructure
description: ES containerization and deployment conventions — package manager choice per stack, multi-stage Dockerfile shapes for NestJS and Next.js, the docker-compose pull-vs-build pair, and the standard AWS CodeBuild → ECR → SSM → EC2 pipeline. Use when creating a new service/app's Dockerfile, docker-compose files, or buildspec.yaml, or when deciding how a new project should build and ship.
---

# ES Deployment Infrastructure

Derived from a 2026-07 audit of five ES repos (`chat-service`, `lms-service` — NestJS backends; `webapp-v1`, `admin-panel`, `lms-webapp` — Next.js frontends). All five ship the same way: a Docker image built by AWS CodeBuild, pushed to ECR, and run as a single long-lived container on a dedicated EC2 instance via SSM — no ECS, no Fargate, no Kubernetes. This is the standard target for new ES projects unless a project explicitly calls for something else.

## Package manager

- **Next.js frontends**: Yarn 4 (Berry), `nodeLinker: node-modules` (not PnP), workspaces even for a single-app repo (`workspaces: ["apps/*", "packages/*"]` in the root `package.json`, one real app under `apps/<name>`). Pin the version in **both** `.yarnrc.yml` (`yarnPath: .yarn/releases/yarn-<version>.cjs`) and `package.json` (`packageManager: "yarn@<version>"`) — keep them identical to each other and to whatever version the Dockerfile's `corepack prepare yarn@<version>` uses. All three audited frontends had at least one of these three places out of sync with the other two; treat that drift as a bug to fix on sight, not a cosmetic detail.
- **NestJS backends**: npm (`package-lock.json`). Both audited backend services use plain npm consistently — don't introduce Yarn here without a deliberate, separate decision; this is the current standard for standalone services.
- **Command convention in a workspace**: once a repo has `apps/*` workspaces, run scripts through the workspace, not bare `next`/`yarn` commands — `yarn workspace <app-name> dev`, `yarn workspace <app-name> build`. This is why you won't see a plain `npm run dev` in these frontends' actual usage; the workspace name is required to disambiguate which app's script runs. If a frontend is genuinely standalone (no `apps/*`, single top-level package — e.g. a project shaped like `lms-webapp`), it has no workspace to target and `yarn dev`/`yarn build` at the root is correct instead — but see the Dockerfile note below, since copying the monorepo Dockerfile template onto a standalone app without adjusting for this is exactly how a real bug happened.

## Dockerfile — NestJS backend (canonical shape)

Two-stage build, both stages `node:24-alpine`:

```dockerfile
# ---------- Stage 1: Builder ----------
FROM node:24-alpine AS builder
RUN apk add --no-cache openssl        # Prisma's query engine needs this on musl libc
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
RUN npx prisma generate
COPY . .
RUN npm run build

# ---------- Stage 2: Runner ----------
FROM node:24-alpine AS runner
RUN apk add --no-cache openssl
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/tsconfig.json ./
EXPOSE 3000
CMD ["node", "/app/dist/src/main.js"]
```

- Copy `package*.json` + `prisma/` before the rest of the source, so `npm ci` and `prisma generate` are cached layers that don't rebust on every source change.
- If the service has standalone maintenance/seed scripts run inside the deployed container (`scripts/`, a seed-specific `tsconfig.seed.json`), copy those into the runner too — don't assume they're dev-only.
- Neither audited backend runs `prisma migrate deploy` in the Dockerfile or the buildspec — migrations are applied out-of-band (manually or via a separate step) in both. Follow this unless a project has an explicit reason to migrate at container start; if you do add an at-start migration step, do it deliberately and document it, since it changes container startup semantics (concurrent replicas would all try to migrate).
- **Always ship a `.dockerignore`** (`node_modules`, `.git`, `.gitignore`, `*.md`, `.env*`, `coverage`, `test`, `spec`) — one of the two audited backends was missing this entirely, which lets `COPY . .` pull in things the build context shouldn't have.
- `docker-compose.yml` is optional but useful for local dev: single `app` service, `restart: always`, bare (host-shell-sourced) env var passthrough for the small set of vars needed locally (`NODE_ENV`, `DATABASE_URL`, `JWT_SECRET`, `JWT_ISSUER`, plus any provider keys). Don't try to make this compose file match production's full secret set — it's a local-dev convenience, not a deploy artifact; the real secret set is injected by the buildspec at deploy time (see below).

## Dockerfile — Next.js frontend (canonical shape)

Two-stage build, both stages `node:24.15.0-alpine3.22` (pin the exact patch version; keep it the same across both stages):

```dockerfile
FROM node:24.15.0-alpine3.22 AS app-builder
ARG APP_NAME
ARG APP_ENV
ENV APP_ENV=${APP_ENV}
WORKDIR /app
RUN corepack enable && corepack prepare yarn@<pin-this-to-match-.yarnrc.yml> --activate
COPY . .
# .env.local is what Next.js loads by default; promote the right per-environment
# file to it before build so NEXT_PUBLIC_* vars get inlined correctly.
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

- **`--frozen-lockfile` is required, not optional** — a plain `yarn install` in a Docker build lets the lockfile drift silently between local dev and what actually gets built/deployed. (Audited repos had this commented out; treat that as a gap to close, not a pattern to repeat.)
- **The final `WORKDIR /app/apps/${APP_NAME}` (and the `apps/${APP_NAME}` reference in the `mv` command) only applies to a real monorepo with `apps/*` workspaces.** If the app is standalone (no `apps/` directory, no workspaces — check `package.json` for a `workspaces` field before assuming), drop `apps/${APP_NAME}` entirely: the `.env` file lives at `app/.env.<APP_ENV>` (or wherever the project's env loader actually reads from — check `next.config.*` for a custom env loader first), the build is `RUN yarn build` (no workspace target), and the runner's final `WORKDIR` is just `/app`. **This exact mistake — copying the monorepo template onto a standalone app without removing the `apps/${APP_NAME}` path — was found live in one audited repo** (`WORKDIR /app/apps/${APP_NAME}` pointing at a path that doesn't exist because the repo has no `apps/` directory). Check whether `apps/` actually exists before writing this Dockerfile from a template.
- The runner stage copying the entire builder `/app` (full `node_modules` + source, not a pruned `.next/standalone` output) is the current pattern in all three audited frontends — acceptable as the baseline, but if image size or build time becomes a real problem, `output: "standalone"` in `next.config` + a `turbo prune --scope=<app>` step in the builder is the leaner alternative; none of the audited repos have adopted this yet, so treat it as an optional future improvement rather than the current standard.
- **Always ship a `.dockerignore`** — same rationale as the backend section above.

## docker-compose — the pull-vs-build pair (frontends)

Ship two compose files per app, not one:

- **`docker-compose.yaml`** — pulls the CI-built image from ECR (`image: <account>.dkr.ecr.<region>.amazonaws.com/<image-repo-name>:main-latest`), no `build:` block. This is what a target host consumes after CI has already pushed.
- **`docker-compose-<app-name>.yaml`** — builds from source (`build: { context: ., dockerfile: Dockerfile, args: { APP_NAME: <app>, APP_ENV: ..., ...NEXT_PUBLIC_* vars... } }`). This is what a developer runs locally via a `deploy.sh <app> <env>` wrapper script (`docker compose --env-file apps/<app>/.env.<env> -f docker-compose-<app>.yaml up -d --build`).

Both files should declare the same `environment:` passthrough list and the same host:container port mapping for a given app. **Two audited frontends both used the ECR image name `website` and both mapped host port `3005`** — harmless individually, but they'd collide if run side by side on one host, and it strongly suggests one was copy-pasted from the other without renaming. Give every new app its own image repo name and, ideally, a distinct local compose port even if the real deployed port (via buildspec, below) already differs — don't rely on the two pipelines' ports happening to diverge by accident.

## buildspec.yaml — the standard CodeBuild pipeline

Identical three-phase shape across all five audited repos (`version: 0.2`). Copy this structure for a new service/app rather than reinventing it — the only things that should change per project are the env var *values* (region/account/image name/instance IDs/ports), not the phase logic itself:

```yaml
version: 0.2
env:
  variables:
    AWS_DEFAULT_REGION: "<region>"       # ap-south-1 in all audited repos
    AWS_ACCOUNT_ID: "<account-id>"
    IMAGE_REPO_NAME: "<org>/<service-name>"   # unique per app — do not reuse across apps
    PROD_EC2_INSTANCE_ID: "<instance-id>"
    DEVELOP_EC2_INSTANCE_ID: "<instance-id>"
    CONTAINER_NAME: "<unique-container-name>"
    HOST_PORT: <port>
    CONTAINER_PORT: 3000
phases:
  pre_build:
    # 1. Pull Docker Hub creds from Secrets Manager (`dockerhub/credentials`) and log in —
    #    avoids Docker Hub's anonymous pull rate limit during `FROM node:...` pulls.
    # 2. Detect branch: $CODEBUILD_WEBHOOK_HEAD_REF if set (webhook build), else
    #    `git rev-parse --abbrev-ref HEAD`. Sanitize `/` -> `-` for tag safety.
    # 3. IMAGE_TAG = "${BRANCH_NAME}-${BUILD_NUMBER}", BUILD_NUMBER = `git rev-list --count HEAD`.
    # 4. Log in to ECR.
  build:
    # Branch -> environment gate:
    #   main                          -> APP_ENV=production
    #   develop|feature-*|bug-*|test-* -> APP_ENV=development
    #   anything else                 -> exit 0, no build
    # docker build -t $REPOSITORY_URI:$IMAGE_TAG --build-arg ... .
    # docker tag $REPOSITORY_URI:$IMAGE_TAG $REPOSITORY_URI:$BRANCH_NAME-latest
    # docker push both tags
  post_build:
    # Branch -> deploy target gate (mirrors the build-phase gate):
    #   main -> $PROD_EC2_INSTANCE_ID, develop/feature-*/bug-*/test-* -> $DEVELOP_EC2_INSTANCE_ID, else skip
    # Poll `aws ec2 describe-instances` until the target instance is "running"
    #   (start it first if stopped); fail the build if it never comes up.
    # Pull environment secrets from Secrets Manager, secret ID "<product>/<env>"
    #   (e.g. "chat/prod", "ai-academy/dev") — extract DATABASE_URL, JWT_SECRET,
    #   and any provider keys (Firebase/Razorpay/MSG91/S3/etc.) as needed.
    # aws ssm send-command (document: AWS-RunShellScript) on the target instance:
    #   ECR login -> docker pull $REPOSITORY_URI:$IMAGE_TAG ->
    #   docker stop/rm $CONTAINER_NAME || true ->
    #   docker run -d --restart always --name $CONTAINER_NAME
    #     -p $HOST_PORT:$CONTAINER_PORT -e ... $REPOSITORY_URI:$IMAGE_TAG
```

Notes worth carrying forward deliberately:
- Two long-lived environments only — `prod` (branch `main`) and `dev` (branch `develop`, plus feature/bug/test branches deploying to the same dev instance). Any other branch builds nothing and deploys nothing; this is a cheap, intentional gate, not an oversight.
- Secrets are never baked into the image and never committed — they're injected as `-e` flags at `docker run` time on the target host, sourced fresh from Secrets Manager on every deploy. Don't add a secret to a `.env.production`/`.env.development` file that gets `COPY`'d into the image; add it to the Secrets Manager secret for that environment instead.
- `HOST_PORT` here does not need to match a frontend's local `docker-compose` port — they serve different purposes (real deployed port vs. local dev port) — but pick it deliberately and keep it stable per app; don't let it silently drift between the two files for the same app without a reason.
- Give every new service its own `IMAGE_REPO_NAME` and `CONTAINER_NAME` — never reuse one app's naming for another, even temporarily.

## Checklist for a new service/app

1. Pick the package manager per the rule above (Yarn+workspaces for a Next.js frontend, npm for a NestJS backend) and pin the version in every place that names it (`.yarnrc.yml`, `package.json`, Dockerfile).
2. Confirm whether the repo actually has `apps/*` workspaces before copying a Dockerfile template — adjust `WORKDIR`/build commands if it doesn't.
3. Write a `.dockerignore`. Every audited repo missing one had `COPY . .` in its builder stage.
4. Give the app a unique ECR image repo name and container name — grep sibling projects' `buildspec.yaml`/`docker-compose*.yaml` for the name you're about to pick, don't assume it's free.
5. Use the standard three-phase buildspec shape above; only the variable values should change per project.
