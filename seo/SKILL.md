---
name: seo
description: Optimizes web pages for search crawlability, metadata, headings, and structured data. Use when SEO, search ranking, meta tags, sitemaps, canonical URLs, or JSON-LD structured data is requested, or a Lighthouse SEO score needs improvement.
---

# SEO

Technical and on-page search optimization following Lighthouse SEO audits and Google Search guidelines. Lighthouse covers a useful subset of technical checks — it never predicts rankings, and no score promises a ranking change.

Source: adapted from `addyosmani/web-quality-skills` (`seo`, MIT). Condensed here; Google Search Central wins on conflict.

## When to Use

- SEO audit, search visibility, or ranking diagnosis requested
- Meta tags, headings, canonical URLs, sitemaps, or `robots.txt` defects reported
- JSON-LD structured data requested or flagged ineligible
- New public page about to ship and needs to be discoverable

**NOT for:**

- Content strategy or keyword authority building — this skill verifies technical correctness, not ranking weights
- Performance field data behind a ranking change — see `performance` for measurement
- Accessibility barriers on the same page — see `accessibility`; the `web-quality-audit` orchestrator runs both

## Process

```
1. EVIDENCE → Live Lighthouse SEO checks when the page runs, else source + HTTP inspection
2. SEPARATE  → Crawl/index config vs rendered metadata vs content quality (never invent ranking weights)
3. FIX       → Source change per finding, most specific schema type only
4. VERIFY   → Re-run the same checks; indexation outcomes stay pending until the search engine re-crawls
```

### 1. Evidence

When a rendered page is available, run live Lighthouse SEO checks (with Chrome DevTools MCP, `lighthouse_audit`) to localize rendered-page failures, then inspect what Lighthouse cannot establish alone: response headers, redirects, `robots.txt`, sitemap coverage, canonical consistency across templates, and Search Console evidence when the user provides access.

Without live tooling: category-specific Lighthouse CLI output plus direct source and HTTP inspection (`curl -I` for headers and canonical `Link` headers, fetch `robots.txt` and sitemap). A Lighthouse SEO pass is not proof of indexation.

## Technical SEO

- **Crawlability.** `robots.txt` allows crawling and lists the sitemap; never disallow render-critical `/static/`. Per-page `meta robots` defaults to `index, follow`; `noindex` only where intended. Sitemap holds canonical, indexable URLs only (50k URLs or 50 MB per file; use an index for larger sites).
- **Canonical.** Every indexable page declares a self-referencing absolute canonical; paginated sets canonicalize sensibly instead of duplicating content.
- **URLs.** Short, lowercase, hyphenated, HTTPS, no parameter identity (`/products/blue-widget`, not `/p?id=12345`).
- **HTTPS.** All subresources HTTPS; HSTS and `X-Content-Type-Options: nosniff` set. Mixed content fails the audit.

## On-Page SEO

- **Title.** Unique per page, topic near the beginning, brand when it disambiguates. Treat ~50–60 chars as a linting proxy, not a pass/fail limit — truncation depends on device width, and search engines may rewrite title links from headings and anchors.
- **Meta description.** Unique, page-specific, with a call to action. Treat ~150–160 chars as a proxy; snippets are query-dependent and the engine may select page content instead.
- **Headings.** Primary heading descriptive, hierarchy logical without skipped levels. Do not fail valid HTML solely for multiple `h1`s.
- **Images.** Descriptive filenames, content-describing `alt`, correct dimensions, modern formats with fallbacks, lazy-load below the fold. The same `alt` must also satisfy `accessibility` naming — never keyword-stuff.
- **Internal links.** Descriptive anchors (`Browse our blue widget collection`, not `Click here`); breadcrumbs for hierarchy; fix broken links promptly.
- **Mobile.** Responsive viewport (`width=device-width, initial-scale=1`); readable base font; tap targets at least 48 px on mobile surfaces. (Mobile discoverability ask; WCAG AA minimum is 24×24 per `accessibility` — meet both, use the larger on mobile.)

## Structured Data

Read [references/structured-data.md](references/structured-data.md) when schema markup is requested or an audit surfaces a structured-data issue. Rules: describe visible, accurate content only; use the most specific applicable type; keep identifiers and absolute URLs stable; validate rendered output with the Rich Results Test. Passing syntax never guarantees eligibility or display.

## Agentic Browsing and AI Discoverability

Keep three concepts separate:

- **Lighthouse Agentic Browsing** measures technical agent-readability (accessibility tree, optional `llms.txt`, WebMCP registrations when present). A pass does not prove search or AI-product ingestion.
- **Search indexing and ranking** depend on search-engine systems; never infer them from an Agentic Browsing score.
- **AI citation** is product-specific. Valid `llms.txt` or browsable markup does not guarantee any assistant will cite the page.

Prioritize semantic HTML, descriptive labels, crawlable content, and accurate metadata — they help people, engines, and agents alike. Add WebMCP tools only for real application actions; add `llms.txt` only when the user requests it or a documented consumer reads it. Never reorganize content or duplicate the sitemap to chase this score.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "SEO score is 100, we'll rank" | The score covers technical checks only. Content usefulness and authority decide the rest. |
| "Longer meta description ranks higher" | Length is a display proxy. Uniqueness and content match matter. |
| "One h1 per page or fail" | Valid HTML may use more than one. Judge descriptiveness and hierarchy. |
| "llms.txt guarantees AI citation" | It is an experimental proposal. No cross-vendor ingestion promise exists. |
| "Structured data means rich results" | Syntax is necessary, not sufficient. Eligibility and display are engine decisions. |

## Red Flags

- `noindex` on pages meant to rank, or `robots.txt` blocking render-critical resources
- Missing, duplicate, or generic title tags and meta descriptions
- Missing canonical or conflicting canonicals across templates
- Sitemap listing non-canonical, redirected, or 404 URLs
- Non-descriptive anchors, broken internal links, missing breadcrumbs
- Images without `alt` or with keyword-stuffed filenames
- Non-responsive viewport, unreadable mobile type, tiny tap targets
- Schema describing invisible content or using an over-generic type
- Promising a ranking change from a Lighthouse score

## Verification

- [ ] Same Lighthouse SEO checks re-run; rendered failures clear
- [ ] `robots.txt`, sitemap, canonical, and headers inspected directly
- [ ] Titles, descriptions, headings unique and descriptive per template
- [ ] Structured data validates; eligibility (not ranking) reported honestly
- [ ] Mobile viewport, type size, and tap targets verified
- [ ] Search Console re-crawl or field validation noted as pending where applicable
