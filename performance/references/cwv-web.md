# Web Core Web Vitals

Web-specific companion to `SKILL.md` §2–§3. Assumes a runnable URL; without one, findings are hypotheses, not measured regressions.

Source: adapted from `addyosmani/web-quality-skills` (`core-web-vitals`, `performance`, MIT).

## Evidence order

1. Field p75 first: CrUX (or Search Console) for the URL, origin fallback only when page data is missing and clearly labeled as such.
2. Lab trace second: one controlled browser session (with Chrome DevTools MCP, `performance_start_trace` plus focused insight analysis) to reproduce and diagnose.
3. First-party RUM (prefer the `web-vitals` library) to segment by route, device, and release. Raw `PerformanceObserver` snippets describe one session, not real users.
4. Re-run equivalent lab measurements after the fix. Field recovery needs new user visits — never claim immediate CrUX improvement.

Do not route web performance through `lighthouse_audit` (it covers non-performance categories). Do not compare a single lab value directly with a field p75.

## Thresholds (p75, Good)

LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1. Needs-improvement: LCP ≤ 4.0s, INP ≤ 500ms, CLS ≤ 0.25. Budgets and CI gates live in [checklist.md](checklist.md).

## LCP checklist

- [ ] TTFB < 800ms (CDN, edge caching, efficient backend)
- [ ] LCP element in initial HTML, not JS-rendered; discoverable without waiting on stylesheets
- [ ] LCP image prioritized (`fetchpriority="high"`, eager); preload only when the trace shows late discovery
- [ ] Image optimized (AVIF/WebP via `<picture>`, correct size, `srcset`); critical CSS inlined (< ~14 KB); no render-blocking JS in `<head>`
- [ ] Fonts don't block text (`font-display: swap`, preload only critical weights, subset)
- [ ] Likely-next navigations prerendered with Speculation Rules at `moderate` eagerness, scoped `href_matches`, side effects gated on `prerenderingchange` (Chromium-only progressive enhancement)

```html
<script type="speculationrules">
{"prerender": [{"where": {"href_matches": "/products/*"}, "eagerness": "moderate"}]}
</script>
```

Scope prerendering to safe, idempotent URLs only — never prerender logout, cart, checkout, or account URLs. Measure hit rate, bytes, and server cost before widening scope. A wrong prerender costs roughly a full page load.

## INP (diagnose by phase)

Split the slow interaction into input delay, processing time, and presentation delay. Common causes: main-thread contention before the handler, expensive app work, delayed rendering after it.

- Yield long tasks (break up >50 ms work, `scheduler.yield` or `setTimeout` chunks where supported).
- Stabilize callbacks and memoize only profiled-hot paths; virtualize lists over ~100 rows (`content-visibility: auto` or a windowing library).
- Defer third-party scripts (`async`/`defer`, load on interaction, facade placeholders for embeds).
- Framework fast paths: Next.js `dynamic()` for heavy components, React `useTransition` for expensive state, Nuxt async components.

## CLS (find the trigger, not the victim)

Use field attribution or a trace to identify the shifted node and its trigger; the visible victim rarely caused the shift.

- Reserve space: `width`/`height` on all images and embeds, `aspect-ratio` for responsive slots, skeleton placeholders for async content.
- Never insert content above existing content after load (banners, consent bars need reserved slots).
- Prefer `transform` over layout-inducing properties for animations; keep view-transition snapshots in mind (they don't count toward CLS).
- Web fonts: `font-display: swap` plus size-matched fallbacks to limit FOUT shift.

## Framework quick mapping

- Next.js: `next/image` with `fetchPriority="high"` for the LCP image; `dynamic()` for INP; image dimensions handle CLS.
- React: preload LCP image with `fetchpriority`; `useTransition` for INP; explicit dimensions for CLS.
- Vue/Nuxt: `NuxtImg` preload/eager for LCP; async components for INP; `aspect-ratio` CSS for CLS.
