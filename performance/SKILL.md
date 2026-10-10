---
name: performance
description: Optimizes measured performance bottlenecks across frontend, backend, queries, and databases. Use when performance budgets or SLAs exist, when slowness or regressions are reported, when Core Web Vitals need improvement, or when profiling points at N+1 queries, indexes, caching, pools, bundles, or rendering.
---

# Performance

Measure before optimizing. Performance work without measurement is guessing, and guessing adds complexity without improving what matters. Profile first, fix the actual bottleneck, measure again. Optimize only what measurements prove matters.

Source: adapted from `addyosmani/agent-skills` (`performance-optimization`, MIT) plus web measurement and Core Web Vitals guidance from `addyosmani/web-quality-skills` (`performance`, `core-web-vitals`, MIT). Rewritten here as language-agnostic guidance for Python, Java/Spring, and TypeScript/Node, with web specifics in [references/cwv-web.md](references/cwv-web.md).

## When to Use

- Performance requirements exist (load-time budgets, response-time SLAs)
- Users or monitoring report slow behavior
- Core Web Vitals scores are below thresholds
- A change is suspected of introducing a regression
- Building features over large datasets or high traffic

**NOT for:**

- Diagnosing a failure happening right now with no perf evidence — use `debug` to build the repro loop first, then bring profiling data back here for profile → fix → verify
- Telemetry design (what to log/measure/alert) — see `observability` (this skill consumes that telemetry)
- Writing or reviewing code with no perf signal — see `clean-code` §9 (clear first); once a signal exists, measure per the `performance` skill §1–§2
- Cache keys that touch tenants, PII, or permissions — check `security-audit` for the leak boundary

## Stack note

Detect the stack from manifests before profiling (see `tech-skills`: `pyproject.toml`/`requirements*.txt` → Python, `pom.xml`/`build.gradle` with Spring Boot → Java/Spring, `package.json` → Node). Prefer that stack's existing profiler and APM. `tech-skills` has no bundled Node/TypeScript guide yet — for Node follow the inline TypeScript pattern plus project conventions. Examples below show the same pattern in Python, Java, and TypeScript — pick one, don't mix.

## Process

```
1. MEASURE  → Establish baseline with real data
2. IDENTIFY → Find the actual bottleneck (not assumed)
3. FIX      → Address the specific bottleneck
4. VERIFY   → Measure again; keep or revert
5. GUARD    → Add monitoring or tests to prevent regression
```

### 1. Measure

Use synthetic and field data together:

- **Synthetic (Lighthouse, DevTools Performance tab, load tests):** controlled, reproducible. Best for CI gates and isolating issues.
- **Field (RUM via `web-vitals`, APM, CrUX):** real users, real conditions. Required to confirm a fix helped users.

**Web pages — field first, then lab.** Field p75 (CrUX or first-party RUM) decides user impact; a lab trace reproduces and diagnoses it. Never compare a single lab value with a field p75, and never claim immediate field recovery after a fix (CrUX needs new visits). Full sequence, thresholds, and LCP/INP/CLS checklists live in [references/cwv-web.md](references/cwv-web.md).

**Frontend:**

```bash
# Synthetic: Lighthouse in CI, Performance tab recording in DevTools
npx lhci autorun
```

```typescript
// RUM: web-vitals in code
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

**Backend:** log response times per endpoint plus per-query timings; prefer the existing APM over ad-hoc timers.

```python
import time
start = time.perf_counter()
result = db.query(...)
elapsed = time.perf_counter() - start
logger.info("query finished", extra={"event": "query_finished", "elapsed_s": elapsed})
```

```java
long start = System.nanoTime();
var result = repository.findFiltered(filter);
long elapsedNs = System.nanoTime() - start;
log.info("event=query_finished elapsedMs={}", elapsedNs / 1_000_000);
```

```typescript
console.time('db-query');
const result = await db.query(...);
console.timeEnd('db-query');
```

#### Where to start

```
What is slow?
├── First page load
│   ├── Large bundle? --> Measure bundle size, check code splitting
│   ├── Slow server response? --> Measure TTFB in the Network waterfall
│   │   ├── DNS long? --> dns-prefetch / preconnect for known origins
│   │   ├── TCP/TLS long? --> HTTP/2, edge deployment, keep-alive
│   │   └── Waiting (server) long? --> Profile backend, queries, caching
│   └── Render-blocking resources? --> Waterfall for blocking CSS/JS
├── Interaction feels sluggish
│   ├── UI freezes on click? --> Main-thread profile, long tasks (>50ms)
│   ├── Form input lag? --> Re-renders, controlled-component overhead
│   └── Animation jank? --> Layout thrashing, forced reflows
├── Page after navigation
│   ├── Data loading? --> API times, request waterfalls
│   └── Client rendering? --> Component render time, N+1 fetches
└── Backend / API
    ├── Single endpoint slow? --> Query log, indexes
    ├── All endpoints slow? --> Pool, memory, CPU
    └── Intermittent? --> Locks, GC pauses, external deps
```

### 2. Identify the bottleneck

**Frontend:**

| Symptom | Likely cause | Investigation |
|---|---|---|
| Slow LCP | Large images, render-blocking resources, slow server | Network waterfall, image sizes; then [references/cwv-web.md](references/cwv-web.md) LCP checklist |
| High CLS | Images without dimensions, late content, font shifts | Layout-shift attribution; then [references/cwv-web.md](references/cwv-web.md) CLS section |
| Poor INP | Heavy main-thread JS, large DOM updates | Long tasks in Performance trace; then [references/cwv-web.md](references/cwv-web.md) INP section |
| Slow initial load | Large bundle, many requests | Bundle size, code splitting |

**Backend:**

| Symptom | Likely cause | Investigation |
|---|---|---|
| Slow API responses | N+1 queries, missing indexes, unoptimized queries | Query log with timings |
| Memory growth | Leaked references, unbounded caches, large payloads | Heap snapshots |
| CPU spikes | Synchronous heavy compute, regex backtracking | CPU profiling |
| High latency | Missing caching, redundant compute, network hops | Request tracing |

### 3. Fix the bottleneck

Fix the one thing Step 2 identified, nothing else. Summaries below; concrete snippets live in [references/optimization-patterns.md](references/optimization-patterns.md). Open the section you need when you reach that code, not before.

**Backend**

- **N+1 queries.** Fetch the relation in the same query (join/include) instead of in the loop. [Pattern](references/optimization-patterns.md#n1-queries).
- **Unbounded data fetching.** Every list endpoint paginates with a limit and a stable order. [Pattern](references/optimization-patterns.md#unbounded-data-fetching).
- **Queries that ignore their index.** `EXPLAIN ANALYZE` is the measurement; "add an index" is the guess. Index for the query shape (equality columns first, then range/sort). Every index taxes every write — re-run the plan after; revert indexes that didn't change it. [Pattern](references/optimization-patterns.md#queries-that-ignore-their-index).
- **Connection pool exhaustion.** Signature: every endpoint slows at once, time spent waiting for a connection, mostly-idle DB sessions. One pool per process, sized so `instances × max` stays under the DB ceiling; on serverless/autoscaling, multiplex via a proxy (pgbouncer, RDS Proxy). [Pattern](references/optimization-patterns.md#connection-pool-exhaustion).
- **Missing caching.** Cache what is expensive and re-read far more than written. Key on every input that changes the response (tenant, locale, permissions, flags) — omitting the viewer serves one user's data to another. State the staleness window and one invalidation strategy; guard hot keys with stale-while-revalidate or single-flight. Never cache what must be fresh. [Pattern](references/optimization-patterns.md#missing-caching).

**Frontend**

- **Missing image optimization.** Every image declares `width`/`height`; LCP image gets `fetchpriority="high"` plus modern formats and `srcset`; below-fold images get `loading="lazy"`. [Pattern](references/optimization-patterns.md#missing-image-optimization).
- **Unnecessary re-renders.** New object/function references per render re-render every receiving child. Reserve memoization for work the profile shows is expensive. [Pattern](references/optimization-patterns.md#unnecessary-re-renders).
- **Large bundle size.** Route-level code splitting and lazy-loading heavy rare features behind `Suspense`; profile before changing import styles. [Pattern](references/optimization-patterns.md#large-bundle-size).
- **Failing LCP, INP, or CLS.** Diagnose by metric phase first, then apply the web checklist. [Guide](references/cwv-web.md).

### 4. Verify (keep or revert)

A fix is a hypothesis until re-measured.

- **Re-measure the way you measured the baseline:** same command, same conditions, same fixed budget. Cold-cache baseline vs warm-cache result measures the cache, not your change.
- **Change one thing at a time.** Measure each in isolation before shipping together.
- **Beat the noise, not just the mean.** Repeat and compare the delta against run-to-run variance. A 3% gain inside ±5% variance is not a gain.

| Result vs. baseline | Action |
|---|---|
| Past the threshold, tests green | **Keep.** Commit with before/after numbers in the message. |
| Within noise | **Revert.** |
| Worse | **Revert.** |
| Improved, but a test went red | **Revert.** A regression wearing a win's clothing. |

**Neutral is a revert, not a keep.** Code you keep, you maintain forever. Make it pay for itself. Log every attempt, kept and reverted, so a dead idea stays discarded (idea, baseline → result, verdict, why — in the PR description or a `PERF.md`).

**Correctness gates the metric.** The suite stays green *and* the number moves. An "optimization" that wins by skipping needed work is a regression.

### 5. Guard against regression

Guard the user-facing metric that justified the fix (LCP, INP, p95 latency), not every available number. Two layers for user-facing surfaces:

- **Synthetic CI gate:** performance budget on reproducible measurements; use medians/trends so normal variance doesn't make the gate flaky.
- **Field monitoring:** alert on meaningful p75 movement in RUM; use attributed `web-vitals` data to locate causes (see `observability` §4–§6). Treat CrUX's rolling window as confirmation, not an immediate alert.

Budgets and CI enforcement live in [references/checklist.md](references/checklist.md).

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "We'll optimize later" | Performance debt compounds. Fix obvious anti-patterns now, defer micro-optimizations. |
| "It's fast on my machine" | Your machine isn't the user's. Profile on representative hardware and networks. |
| "This optimization is obvious" | If you didn't measure, you don't know. Profile first. |
| "Users won't notice 100ms" | 100ms delays move conversion rates. Users notice more than you think. |
| "The framework handles performance" | Frameworks prevent some issues but can't fix N+1 queries or oversized bundles. |
| "The query is slow, add an index" | Read the plan first. The index may exist and be unusable, and every index taxes writes forever. |
| "Just cache it" | Caching an already-cheap call buys nothing and adds a staleness bug. Cache what is expensive *and* re-read far more than written. |
| "Raise the pool size, we're out of connections" | A pool bigger than the DB can serve moves the queue somewhere less visible. Find what holds connections. |
| "It didn't help much, but it doesn't hurt" | Neutral changes are a revert. You pay maintenance on them forever and got nothing back. |
| "We already wrote it, may as well keep it" | Sunk cost. The measurement doesn't care how long the change took. |
| "The improvement is obvious, no need to re-measure" | Then re-measuring is cheap and proves it. Unmeasured wins are how neutral complexity lands. |

## Red Flags

- Optimization without profiling data to justify it
- N+1 query patterns in data fetching
- Index added without a query plan before and after
- Cache key omitting an input the response depends on (tenant, locale, viewer)
- Cache with no stated staleness window and no invalidation strategy
- Pool size raised in response to exhaustion without finding what holds connections
- List endpoints without pagination
- Images without dimensions, lazy loading, or responsive sizes
- Bundle size growing without review
- No performance monitoring in production
- `React.memo` / `useMemo` everywhere (overuse is as bad as underuse)
- Optimizations kept without a re-measurement that justifies them
- Several optimizations bundled into one measurement, so no change can be attributed
- A "win" that required a test to be changed, skipped, or deleted
- The same failed optimization attempted twice because nobody recorded the first attempt

## Verification

After any performance change, walk [references/checklist.md](references/checklist.md):

- [ ] Before/after numbers exist; re-measured the same way as the baseline
- [ ] Improvement exceeds run-to-run variance, not just the mean
- [ ] Neutral or worse changes reverted, not kept
- [ ] Attempts logged, kept and reverted alike
- [ ] Bottleneck identified and addressed; Core Web Vitals in "Good" thresholds
- [ ] Bundle size not significantly increased; no new N+1 queries
- [ ] New indexes justified by plans before/after; write cost considered
- [ ] New caches state key inputs, staleness window, and invalidation
- [ ] User-facing metric has a synthetic budget or field monitor
- [ ] Existing tests still pass
