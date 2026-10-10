# Performance Checklist

At-a-glance version of the Verification list in `SKILL.md`, plus budgets and CI enforcement.

## Budgets

```
JavaScript bundle: < 200KB gzipped (initial load)
CSS: < 50KB gzipped
Images: < 200KB per image (above the fold)
Fonts: < 100KB total
API response time: < 200ms (p95)
Lighthouse Performance score: >= 90
```

Adjust per product, then enforce — an unenforced budget is a wish.

## Core Web Vitals targets

| Metric | Good | Needs improvement | Poor |
|---|---|---|---|
| LCP | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## Enforce in CI

```bash
# Bundle budget check via the repo's configured checker
# (e.g. size-limit or Lighthouse CI budgets — pick one, don't mix)
npx size-limit

# Lighthouse CI
npx lhci autorun
```

Repeat noisy measurements or compare medians/trends so normal run-to-run variance doesn't make the gate flaky.

## Attempt log

| Idea | Baseline → Result | Verdict | Why |
|---|---|---|---|
| Memoize the row component | INP 240ms → 235ms | reverted | Inside noise (±15ms); rows weren't the bottleneck |
| Virtualize the list | INP 240ms → 90ms | kept | Long tasks gone from the trace |
| Preconnect to the API origin | LCP 2.8s → 2.8s | reverted | Already same-origin |

Keep in the PR description or a `PERF.md`. The next person (or agent) reads it before proposing an experiment.

## Verification

Canonical checklist lives in `SKILL.md` ## Verification — follow it there. This file adds budgets, CI enforcement, and the attempt log only.
