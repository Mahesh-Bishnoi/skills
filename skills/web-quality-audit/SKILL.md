---
name: web-quality-audit
description: Runs an evidence-led web quality audit across performance, accessibility, SEO, and best practices. Use when a multi-category Lighthouse audit, a pre-launch quality gate, or triage of which category blocks release is requested.
---

# Web Quality Audit

Orchestrates `performance`, `accessibility`, and `seo` into one evidence-led review. Combines live browser evidence with source inspection, keeps measured failures separate from code-only hypotheses, and never treats an aggregate score as proof of quality.

Source: adapted from `addyosmani/web-quality-skills` (`web-quality-audit`, MIT). Category detail lives in the sibling skills; this file only routes and reports.

## When to Use

- User asks to audit a site, review web quality, or run a Lighthouse audit
- Pre-launch or pre-deploy quality gate across more than one category
- Triaging which category (speed, a11y, SEO) actually blocks release

**NOT for:**

- Deep single-category work once the blocker is known — load `performance`, `accessibility`, or `seo` directly
- Security penetration testing or auth review — see `security-audit` (guidance vs full-audit modes apply)
- Design taste — do that work without a skill unless the user ran `/setup` for the `ui-ux` stack (`@ui-ux-pro-max` / `@design-taste-frontend` after install)

## Process

```
1. SCOPE   → Representative URLs, states, journeys, auth, mobile vs desktop
2. BASELINE → Minimal live evidence before broad source search (see Tool routing)
3. LOCALIZE → Runtime failures point at components; keep hypotheses labeled as hypotheses
4. CATEGORIZE → Severity by user impact and confidence (§ Severity)
5. VERIFY   → Re-run the same automated checks plus affected manual flows; report pending field validation
```

### Tool routing

Use the best capability already available; never block the audit on optional setup.

| Need | Preferred route | Fallback |
|---|---|---|
| Performance and Core Web Vitals | Browser performance trace with focused insights; with Chrome DevTools MCP, `performance_start_trace` then `performance_analyze_insight` | Lighthouse CLI or PageSpeed Insights lab data; CrUX for field context |
| Accessibility, SEO, best practices | Live Lighthouse audit; with Chrome DevTools MCP, `lighthouse_audit` | Category-specific Lighthouse CLI audits plus manual checks |
| Rendered semantics and interaction | Accessibility-tree snapshot plus keyboard walk of the affected flow | Manual browser testing |
| Source smoke test | Framework-aware inspection of the implicated templates only | Full-repo search when localization failed |

Notes: DevTools `lighthouse_audit` intentionally excludes performance — use the trace route for speed. Navigation mode reloads the page; use snapshot mode when preserving auth or user-created state. A static analyzer is a smoke test, not a substitute for a rendered audit. Lighthouse 13+ shares Performance Insights with DevTools; follow current insight names, never require retired audit IDs.

## What to check (delegate, don't duplicate)

- **Performance.** See `performance` (and its `references/cwv-web.md`) for field-p75-first diagnosis via trace insights.
- **Accessibility.** See `accessibility` for automated failures plus keyboard, focus, form-error, and screen-reader checks.
- **SEO.** See `seo` for crawl/index config, rendered metadata, and structured-data eligibility (never promise ranking changes).
- **Best practices.** HTTPS/mixed content, vulnerable dependencies, deprecated APIs, valid doctype and charset, clean console. Findings that cross a trust boundary: see `security-audit`; launch-hardening concerns: see `hardening`.
- **Telemetry.** Gaps in RUM, logging, or alerting surfaced by the audit: see `observability`.
- **Agentic browsing.** Report accessibility-tree exposure and optional `llms.txt` as agent-readability only — never as SEO or AI-citation evidence.

## Severity

| Level | Meaning | Action |
|---|---|---|
| Critical | Security exposure or complete failure | Fix immediately |
| High | Failing Core Web Vitals, major a11y barrier | Fix before launch |
| Medium | Performance opportunity, SEO improvement | Fix within sprint |
| Low | Minor optimization, code quality | Fix when convenient |

## Audit output format

```markdown
## Audit results

### Evidence
| Signal | Scope/conditions | Result | Source |
|---|---|---|---|
| LCP | URL, device, p75/28d | 3.1s needs-improvement | CrUX |
| Accessibility | URL, mobile navigation | 92, 2 failing nodes | Lighthouse |

### Critical issues (X found)
- **[Category]** Description. File: `path/to/file:line`
  - **Impact:** Why this matters
  - **Evidence:** Measured failure, runtime observation, or source hypothesis
  - **Fix:** Specific code change or recommendation

### High priority (X found)
...

### Summary
- Performance: measured status and X findings
- Accessibility: automated status, X findings, manual checks pending/passed
- SEO: X findings
- Best practices: X findings

### Recommended priority
1. First fix this because...
2. Then address...

### Verification
- Re-run results under the same conditions
- Manual checks completed
- Field validation still pending
```

## Checklists

Before every deploy: Core Web Vitals status known, no new accessibility errors, no console errors, HTTPS valid, meta tags present.

Weekly: Search Console issues, Core Web Vitals trends, dependency updates, one screen-reader flow.

Monthly: full audit, performance profile, a11y pass with real users where stakes justify it.

## Verification

- [ ] Scope (URLs, states, auth, mobile/desktop) recorded before auditing
- [ ] Baseline evidence collected before broad source search
- [ ] Measured failures separated from hypotheses
- [ ] Findings carry file references and specific fixes
- [ ] Same checks re-run; pending field or human validation explicitly listed
