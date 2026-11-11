---
name: seo-metadata
description: ES SEO/metadata conventions for web (Next.js) properties — Metadata API usage, generated sitemap.xml/robots.txt, JSON-LD structured data, heading/image semantics, and title/description content-quality standards. Use when adding or editing a page's metadata, structured data, or SEO-facing copy. Not applicable to Flutter/mobile — no crawlable surface.
---

# ES SEO and Metadata

Cross-cutting, like `proxy-infrastructure` — not owned by one feature slice, resolved through one shared system every page plugs into. Web (Next.js) only.

Every indexable route ships two things:

- **Mechanism** — metadata, robots control, canonical URL, structured data, sitemap entry. Mandatory, engineering-owned.
- **Content quality** — the actual title/description/heading/keyword wording. A quality bar, copy-owned, reviewed like code.

## Mechanism

- Metadata (`title`, `description`, canonical, `robots`) goes through Next.js's Metadata API — `generateMetadata()` for dynamic routes, static `metadata` export for static ones. Never hand-written `<head>` tags.
- `app/sitemap.ts` generates `sitemap.xml`; `app/robots.ts` generates `robots.txt`. Never hand-maintained.
- JSON-LD structured data (schema.org) through one shared component/helper in `shared/seo/`, not reimplemented per page. Site-wide `Organization` schema everywhere; page-type schema (`Service`, `Product`, `LocalBusiness`, `FAQPage`, `BreadcrumbList`, ...) where the page warrants it.
- Exactly one `H1` per page; heading levels nest without skipping. Images always carry `alt` text. `lang` set explicitly.
- Internal links use descriptive anchor text; no orphan pages.

## Content quality

| Element | Target | Notes |
|---|---|---|
| Title | ~50–60 visible chars (≤ 70 with brand suffix) | Primary keyword near the front, brand name included |
| Description | ~140–160 chars | Primary + secondary keyword used naturally |
| Keywords meta | Optional, 5–8 phrases | Low ranking value on modern search engines; only if genuinely on-topic |
| H1 | Mirrors the title's search intent | Contains the primary keyword; don't restate the title verbatim |

Not enforced by a build failure — reviewed for quality the way copy is reviewed, not the way a lint rule is.

## Ownership

Engineering owns the mechanism (metadata plumbing, sitemap/robots generation, JSON-LD, heading semantics, alt text). Content/marketing owns the wording. A page isn't done until both passes are complete — treat as part of the feature's definition of done alongside `testing-strategy` checks.

Full spec (complete rule set, ownership workflow): `14-seo-and-metadata.md` in the project repo, if present.
