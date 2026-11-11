# SEO and Metadata

TES treats SEO as a cross-cutting infrastructure concern, the same way [10 · Analytics and Monitoring](10-analytics-and-monitoring.md) is — not owned by any single feature slice, resolved through one shared system that every page/feature plugs into.

This applies to **web (Next.js) properties only**. Mobile (Flutter) apps have no crawlable surface, so this doc does not apply there.

Every indexable route ships two things:

* **Mechanism** — metadata, robots control, canonical URL, structured data, sitemap entry. Mandatory, testable, engineering-owned.
* **Content quality** — the actual wording of title/description/headings/keywords. A quality bar, copy-owned, reviewed like code.

---

# Mechanism (Technical SEO)

## Metadata API

Every route defines its metadata through Next.js's Metadata API (`generateMetadata()` for dynamic routes, static `metadata` export for static ones) — never hand-written `<head>` tags.

Required per route:

* `title`
* `description`
* canonical URL (self-referencing on indexable pages)
* `robots` (`index, follow` by default; `noindex` explicit where intended — never accidental)

## Sitemap and robots.txt

* `app/sitemap.ts` generates `sitemap.xml` — never hand-maintained.
* `app/robots.ts` generates `robots.txt` — single source of truth, references the generated sitemap.

## Structured data (JSON-LD / schema.org)

* Site-wide `Organization` schema on every page (name, url, logo).
* Page-type-specific schema where the page warrants it — `Service`, `Product`, `LocalBusiness`, `FAQPage`, `BreadcrumbList`, etc.
* Rendered through one shared JSON-LD component/helper (`shared/seo/`), not reimplemented per page.

## Semantic structure

* Exactly one `H1` per page.
* Heading levels nest logically (`H2` → `H3` → `H4`), never skipped.
* Images carry `alt` text always; `title` attribute only where it adds distinct value.
* `lang` attribute set explicitly at the document level.

## Linking

* Internal links use descriptive anchor text, not "click here" / "read more".
* No orphan pages — every indexable route is reachable from at least one internal link.

---

# Content Quality (Marketing SEO)

Guidelines, not hard mechanism rules — reviewed for quality, not enforced by a build failure.

| Element | Target | Notes |
|---|---|---|
| Title | ~50–60 visible characters (≤ 70 including brand suffix) | Primary keyword near the front, brand name included |
| Description | ~140–160 characters | Primary + secondary keyword used naturally, include a reason to click |
| Keywords meta | Optional, 5–8 phrases | Low ranking value on modern search engines; only include phrases that genuinely match on-page content |
| H1 | Mirrors the title's search intent | Contains the primary keyword; do not restate the title verbatim |
| Body content | Enough substantive content to avoid "thin content" | No fixed word-count floor — judged per page type |

---

# Ownership and Workflow

* Engineering owns the mechanism: metadata plumbing, sitemap/robots generation, JSON-LD, heading semantics, alt text.
* Content/marketing owns the wording: title, description, keyword phrases, H1 copy.
* A page is not "done" until both passes are complete — add an SEO check to the feature's definition of done alongside functional and validation checks (see [11 · Testing Philosophy](11-testing-philosophy.md)).
* Audit with an SEO inspection tool (e.g. AIOSEO's on-page analyzer) before shipping a new page, and periodically for existing ones.

---

Benefits:

* consistent crawlability across every web property
* no accidental `noindex` or missing canonical
* structured data that search engines can actually parse
* a repeatable content bar instead of ad-hoc copywriting
