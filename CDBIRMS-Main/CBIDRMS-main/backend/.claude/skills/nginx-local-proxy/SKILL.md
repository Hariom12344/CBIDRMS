---
name: nginx-local-proxy
description: Set up nginx as a local reverse proxy in front of a Next.js dev server on macOS (Homebrew) or Windows — custom hostname, mkcert HTTPS, and the config gotchas (default-port collision, root-vs-user service, cert filenames, allowedDevOrigins). Use when a project needs an nginx-fronted local URL rather than the simpler no-dependency Part F pattern in nextjs-deployment-setup.
---

# ES Nginx Local Reverse Proxy Setup

Actionable pattern for fronting a Next.js dev server with real nginx, reachable at a clean local hostname over HTTPS with no port in the URL. Steps 0–4 are OS-specific (macOS/Homebrew vs. Windows below); Steps 5–6 (server block, `allowedDevOrigins`) are identical on both. Derived from a live setup on `lms-webapp` (`aiforai.local` → `localhost:3231`, macOS).

## When to reach for this vs. Part F

`nextjs-deployment-setup` → Part F already covers local custom-hostname HTTPS using only `next dev -H <hostname> --experimental-https` + mkcert — no extra service, nothing to keep running, nothing to auto-start at boot. **Default to Part F.**

Reach for this skill instead when the project actually needs a reverse proxy in front of the app, not just a hostname/TLS wrapper — e.g.:
- Multiple local services need to sit behind one origin (path- or subdomain-based routing to several dev servers/ports).
- You want the proxy layer to mirror a production nginx/ALB setup.
- You want the URL on port 80/443 with no port suffix, persisted across reboots, independent of whether the dev server happens to be running.

If neither applies, use Part F and stop reading here.

## Step 0 — Confirm scope with the user

Ask (don't assume):
1. **Hostname** — pick something project-specific (e.g. `<app>.local`), not a generic name that could collide with another project's setup on the same machine.
2. **HTTPS or HTTP-only** — HTTPS pulls in mkcert and a local CA trust-store change; HTTP-only skips that.
3. **Confirm before running anything that needs `sudo`** — installing a system-trusted CA and running nginx as a root LaunchDaemon are both machine-wide, persistent changes. Lay out the plan first (see Step 3), get a go-ahead, then execute.

## macOS (Homebrew)

### Step 1 — Install nginx, inspect current state before changing it

```bash
brew install nginx
```

Before writing any config, check what's already there so you don't clobber another project's setup on the same machine:

```bash
ls /opt/homebrew/etc/nginx/servers/
grep -n "include servers" /opt/homebrew/etc/nginx/nginx.conf
grep -n "listen" /opt/homebrew/etc/nginx/nginx.conf
grep -n "<your-hostname>" /etc/hosts
which mkcert
```

### Step 2 — The default-port collision gotcha

Homebrew's nginx ships with a default placeholder `server` block in `nginx.conf` itself listening on **8080** (chosen specifically so nginx can run without sudo out of the box). If the Next.js dev server also ends up on 8080 (or whatever port you pick), nginx's own default block fights it for the socket and **the entire nginx master process fails to bind and exits** — not just that one server block. Symptom: `brew services` reports "Successfully started" but nothing is actually listening (`error.log` shows `bind() ... failed (48: Address already in use)`).

Fix: move nginx's own default placeholder server off whatever port your app uses:

```nginx
# /opt/homebrew/etc/nginx/nginx.conf
server {
    listen       8081;   # anything not used by an app dev server
    server_name  localhost;
    ...
}
```

Always run `nginx -t` after any config change — it validates syntax without needing sudo — but note it does **not** catch port collisions; those only surface at bind time (`error.log`).

### Step 3 — Root vs. user-level service (why it matters for port 80/443)

Port 80/443 are privileged; a plain `brew services start nginx` runs nginx as your user and can only bind unprivileged ports (hence the 8080 default). To actually serve on 80/443 you need nginx running as a **system-level LaunchDaemon**, which requires `sudo` once:

```bash
brew services stop nginx            # stop the user-level agent, if running
sudo brew services start nginx      # installs as a root LaunchDaemon
```

This is a one-time, persistent change — verify it'll survive reboots:

```bash
plutil -p /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
# expect "RunAtLoad" => true
```

`RunAtLoad: true` on a `/Library/LaunchDaemons/*.plist` means launchd starts nginx at boot, system-wide, before any user login — no extra step needed after the initial `sudo brew services start nginx`. The app dev server is a separate, non-persistent process — nginx being up doesn't mean the app is; it'll just proxy to a closed port until you run the dev server.

After switching to root, `nginx -t` still works without sudo (read-only), but starting/stopping/reloading the service needs `sudo brew services restart nginx` from then on.

### Step 4 — mkcert + hosts entry (HTTPS only)

```bash
brew install mkcert nss
mkcert -install                         # installs local CA into system trust store, one-time per machine
mkdir -p ~/Certificates && cd ~/Certificates
mkcert <hostname>                       # e.g. mkcert aiforai.local
sudo sh -c 'echo "127.0.0.1 <hostname>" >> /etc/hosts'
```

**Cert filename gotcha:** `mkcert <hostname>` with a single domain name outputs `<hostname>.pem` / `<hostname>-key.pem` — no `+1` suffix. The `+N` suffix only appears when you pass multiple domains to a single `mkcert` invocation (e.g. `mkcert foo.local api.foo.local` → `foo.local+1.pem`). Match the actual output filenames in the nginx config, don't assume the suffix.

## Windows

The overall shape is the same (install nginx → install mkcert → hosts entry → server block → `allowedDevOrigins`), but the OS-level mechanics differ enough to trip you up if you follow the macOS commands literally.

### Step 1 — Install nginx, inspect current state before changing it

No Homebrew; use Chocolatey or Scoop (either is fine, pick whichever the machine already has), or the official zip if neither package manager is present:

```powershell
choco install nginx -y
# or
scoop install nginx
# or: download the zip from nginx.org/en/download.html and unzip to e.g. C:\nginx
```

Find the install layout and current config before changing anything — it varies by install method:

```powershell
# Chocolatey typically lands under C:\tools\nginx-<version>\
# Scoop typically lands under ~\scoop\apps\nginx\current\
Get-Content <nginx-dir>\conf\nginx.conf | Select-String "listen"
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "<your-hostname>"
Get-Command mkcert -ErrorAction SilentlyContinue
```

There's no Homebrew-style auto-`include servers/*` convention out of the box on Windows builds — either add `include servers/*.conf;` yourself inside the `http {}` block of `nginx.conf` and create a `servers\` folder next to it, or add server blocks directly in `nginx.conf`. Either way, apply the same default-port-collision check as macOS Step 2 (Chocolatey's nginx defaults to listening on 8080; the official zip's default `nginx.conf` defaults to 80) — check the shipped default before assuming it's out of your way.

### Step 2 — Running on port 80/443 (no `sudo` equivalent needed)

This is the one place Windows is actually simpler: Windows does **not** reserve ports below 1024 for admin/elevated processes the way Unix does. A plain (non-elevated) `nginx.exe` can bind directly to 80/443 with no admin prompt — there's no "root vs. user-level service" split to worry about here.

What Windows *does* need admin/elevated rights for:
- Editing `C:\Windows\System32\drivers\etc\hosts` (Step 3 below).
- `mkcert -install` writing to the Windows certificate store (Step 3 below) — this triggers a UAC prompt.
- Registering nginx as a **Windows Service** so it survives reboots without you manually launching it (optional — see below).

### Step 3 — mkcert + hosts entry (HTTPS only)

```powershell
choco install mkcert -y
# or: scoop install mkcert

mkcert -install                          # writes to the Windows cert store; expect a UAC prompt
mkdir $HOME\Certificates; cd $HOME\Certificates
mkcert <hostname>                        # e.g. mkcert aiforai.local

# From an elevated PowerShell (Run as Administrator):
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 <hostname>"
ipconfig /flushdns
```

Same cert filename gotcha as macOS applies (`<hostname>.pem`/`<hostname>-key.pem` for a single domain, `+N` suffix only for multi-domain invocations).

### Step 4 — Auto-start at boot (optional, roughly maps to macOS Step 3)

Running `nginx.exe` from a terminal only lasts until that terminal closes — there's no LaunchDaemon equivalent built in. To persist across reboots, wrap it as a Windows Service (needs an elevated prompt to install, same one-time-per-machine idea as the macOS root LaunchDaemon):

```powershell
# Using NSSM (the common non-sucking service manager approach):
choco install nssm -y
nssm install nginx "<nginx-dir>\nginx.exe"
nssm set nginx AppDirectory "<nginx-dir>"
nssm start nginx
# nssm sets the service to auto-start on boot by default; verify with:
Get-Service nginx | Select-Object StartType
# expect "Automatic"
```

If you don't need it to survive reboots, skip this — just run `<nginx-dir>\nginx.exe` from an ordinary (non-admin) terminal each session, same tradeoff as choosing not to persist on macOS.

Reload after any config change: `nginx -s reload` if run manually, or `Restart-Service nginx` if installed as a service. `nginx -t` (config syntax check) works the same as macOS, no elevation needed.

**Cert path syntax:** nginx on Windows still expects forward slashes in `ssl_certificate` paths, even though the rest of Windows uses backslashes: `ssl_certificate C:/Users/<user>/Certificates/<hostname>.pem;` — not `C:\Users\...`.

## Step 5 — Server block (macOS + Windows, identical)

One file per hostname — under `/opt/homebrew/etc/nginx/servers/` on macOS (already `include`d from `nginx.conf`), or in whatever `servers\` folder you set up in the Windows Step 1 `include`:

```nginx
server {
    listen 80;
    server_name <hostname>;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name <hostname>;

    # macOS: /Users/<user>/Certificates/<hostname>.pem
    # Windows: C:/Users/<user>/Certificates/<hostname>.pem (forward slashes even on Windows)
    ssl_certificate     <path-to-hostname.pem>;
    ssl_certificate_key <path-to-hostname-key.pem>;

    location / {
        proxy_pass http://localhost:<app-port>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Use `listen 443 ssl; http2 on;` (two lines) on nginx ≥ 1.25.1 — the older combined `listen 443 ssl http2;` form is deprecated.

Give the app a dedicated non-default dev script for this port so plain `next dev` (no proxy) keeps working unmodified:

```json
"dev:local": "next dev -p <app-port>"
```

Test and reload after any server-block change:

```bash
nginx -t
sudo brew services restart nginx   # macOS, once nginx runs as root (Step 3)
```
```powershell
nginx -t
nginx -s reload                    # Windows, manual run
Restart-Service nginx              # Windows, installed as a service
```

## Step 6 — Next.js `allowedDevOrigins`

Next.js's dev server blocks cross-origin requests to dev-only assets (`/_next/webpack-hmr`, etc.) by default, and requests arriving via the nginx hostname look cross-origin to it. Without this, HMR breaks (webpack-hmr requests get blocked, page still loads but no hot reload). Add the proxy hostname:

```js
// next.config.mjs
const nextConfig = {
  allowedDevOrigins: ["<hostname>"],
  // ...
};
```

Verify the key still exists in the installed Next.js version before relying on it (`grep -rl "allowedDevOrigins" node_modules/next/dist/` — it's schema-validated, so a typo or removed key fails config load, not silently ignored).

## After applying

Summarize: hostname chosen, app port, whether HTTPS was set up, and confirm the persistent machine-wide changes made — `mkcert -install` CA trust always, plus nginx as a root LaunchDaemon (macOS) or a Windows Service (Windows) if boot-persistence was set up. These outlive the current project and apply to the whole machine, so the user should know they're there next time they touch nginx for a *different* project (same instance, one more server-block file, don't duplicate the CA/persistent-service steps).
