# Optimization Patterns

Concrete implementations of the fixes in `SKILL.md` §3. Pick the section you need; each is self-contained. Examples show Python, Java/Spring, and TypeScript — apply the same invariant in any stack.

## N+1 queries

One query per row is the most common backend bottleneck. Fetch the relation in the same query instead of in the loop.

```python
# BAD: 1 + N queries
orders = db.query("SELECT * FROM orders WHERE user_id = %s", (user_id,))
for o in orders:
    o.items = db.query("SELECT * FROM items WHERE order_id = %s", (o.id,))

# GOOD: join / eager load
rows = db.query(
    "SELECT o.*, i.* FROM orders o JOIN items i ON i.order_id = o.id "
    "WHERE o.user_id = %s", (user_id,))
```

```java
// BAD: N+1 via lazy loading in a loop
List<Order> orders = orderRepository.findByUserId(userId);
orders.forEach(o -> o.getItems().size()); // one SELECT per order

// GOOD: fetch join / entity graph
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.userId = :userId")
List<Order> findByUserIdWithItems(@Param("userId") long userId);
```

```typescript
// BAD (Prisma-style): query per row
const orders = await prisma.order.findMany({ where: { userId } });
for (const o of orders) {
  o.items = await prisma.item.findMany({ where: { orderId: o.id } });
}

// GOOD: include the relation
const orders = await prisma.order.findMany({
  where: { userId },
  include: { items: true },
});
```

Verify with the query log: row count fetched should be ~constant in query count as rows grow.

## Unbounded data fetching

Every list endpoint paginates with a limit and a stable order. No `SELECT *` without `LIMIT`, no unbounded in-memory accumulation.

```python
# BAD
rows = db.query("SELECT * FROM events ORDER BY created_at DESC")

# GOOD: keyset pagination, capped page size
rows = db.query(
    "SELECT * FROM events WHERE created_at < %s "
    "ORDER BY created_at DESC LIMIT %s", (cursor, min(page_size, 100)))
```

```java
// GOOD: Spring Data pageable with a hard cap
Pageable page = PageRequest.of(pageIndex, Math.min(size, 100),
    Sort.by(Sort.Direction.DESC, "createdAt"));
Page<Event> events = eventRepository.findAll(page);
```

```typescript
// GOOD: cursor pagination, capped
const rows = await db.query(
  'SELECT * FROM events WHERE created_at < $1 ORDER BY created_at DESC LIMIT $2',
  [cursor, Math.min(pageSize, 100)],
);
```

Stable order matters: paginating without `ORDER BY` (or on a non-unique column alone) duplicates/skips rows under concurrent writes. Prefer keyset cursors over large `OFFSET`s.

## Queries that ignore their index

`EXPLAIN ANALYZE` is the measurement. A `Seq Scan` where you expected an index, a `rows=` estimate off by an order of magnitude, or a `Sort` node above the scan each call for a different fix.

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 20;
-- want: Index Scan / Index Only Scan on (user_id, created_at), not Seq Scan + Sort
```

Rules:

- Index for the query shape: equality columns first, then the range or sort column — e.g. `(user_id, created_at)` for `WHERE user_id = ? ORDER BY created_at`.
- A bad `rows=` estimate means stale statistics: run `ANALYZE`, don't add an index.
- A plain index won't help a low-selectivity dominant value (use a partial index for the rare value), a leading wildcard `LIKE '%foo'` (needs trigram/full-text), or a function on the column (index the expression, e.g. `lower(email)`).
- Every index taxes every write. Re-run the plan afterwards; revert indexes that didn't change it.

## Connection pool exhaustion

Signature: *every* endpoint slows at once, time is spent waiting for a connection rather than executing, and the database shows mostly idle sessions.

```python
# Size so instances × max stays under the DB ceiling; one pool per process
pool = ConnectionPool(min_size=2, max_size=10, timeout=5.0)
```

```java
// HikariCP: small, explicit, with a checkout timeout
HikariConfig cfg = new HikariConfig();
cfg.setMaximumPoolSize(10);
cfg.setConnectionTimeout(5_000);
```

```typescript
// pg Pool: same rule — instances × max < DB max_connections
const pool = new Pool({ min: 2, max: 10, connectionTimeoutMillis: 5_000 });
```

Bigger is not faster — it relocates the queue to the database where it is harder to see. With unbounded instance counts (serverless, autoscaling), multiplex through a proxy (pgbouncer, RDS Proxy) instead of raising `max`. Find what holds connections (long transactions, missing `close`/`release`, oversized timeouts) before touching the size. Always release via scoped constructs (`with`, try-with-resources, `pool.query` / `release()` in `finally`).

## Missing caching

Cache what is expensive to produce and read far more often than it changes. Caching an already-fast query adds a hop and a staleness bug for nothing.

```python
# Single-flight: concurrent misses share one in-flight computation
import asyncio
_inflight: dict[str, asyncio.Task] = {}

async def get_config(key: str):
    if (t := _inflight.get(key)) is None:
        t = _inflight[key] = asyncio.create_task(_load_config(key))
        try:
            return await t
        finally:
            _inflight.pop(key, None)
    return await t
```

```java
// Caffeine-style: bounded size, TTL, single-flight load
Cache<String, Config> cache = Caffeine.newBuilder()
    .maximumSize(1_000)
    .expireAfterWrite(Duration.ofMinutes(5))
    .build();
Config cfg = cache.get(key, k -> loadConfig(k));
```

```typescript
// Serve stale while one request recomputes (pseudo)
const hit = await cache.get(key);
if (hit && !isStale(hit)) return hit.value;
if (hit) { void recomputeInBackground(key); return hit.value; } // stale-while-revalidate
return recomputeSingleFlight(key); // coalesce concurrent misses
```

Checklist for every cache: key includes every input that changes the response (tenant, locale, permissions, feature flags); one invalidation strategy (TTL, event/tag-based, versioned keys) with an explicit staleness window; hot-key stampede guard; never cache what must be fresh (balances, permissions, inventory at checkout). Negative caching (short-TTL caching of misses) only where the miss is expensive and slightly-stale absence is safe.

## Missing image optimization

```html
<!-- GOOD: dimensions (CLS), modern formats, responsive sizes, LCP priority -->
<picture>
  <source type="image/avif" srcset="hero-800.avif 800w, hero-1600.avif 1600w" sizes="100vw" />
  <source type="image/webp" srcset="hero-800.webp 800w, hero-1600.webp 1600w" sizes="100vw" />
  <img src="hero-800.jpg" width="1600" height="900"
       fetchpriority="high" decoding="async" alt="..." />
</picture>

<!-- Below the fold: lazy -->
<img src="card.jpg" width="600" height="400" loading="lazy" decoding="async" alt="..." />
```

Rules: every image declares `width`/`height`; LCP image is eager with `fetchpriority="high"`; below-fold images are `loading="lazy"`; serve AVIF/WebP via `<picture>` with `srcset`/`sizes`. Keep above-fold images small (see checklist budgets).

## Unnecessary re-renders

An object or function created in render is a new reference every time and re-renders every child that receives it.

```tsx
// BAD: new reference each render
<Table rows={rows} config={{ dense: true }} onSelect={(id) => select(id)} />

// GOOD: hoist constants, stabilize callbacks; memoize only profiled-hot paths
const CONFIG = { dense: true } as const;

function List({ rows }: Props) {
  const onSelect = useCallback((id: string) => select(id), [select]);
  const visible = useMemo(() => rows.filter(isVisible), [rows]);
  return <Table rows={visible} config={CONFIG} onSelect={onSelect} />;
}
```

Reserve `React.memo`/`useMemo` for work the profile shows is expensive — overuse is its own cost (memory, stale-closure bugs). For lists with hundreds of rows, virtualize instead of memoizing each row.

## Large bundle size

```tsx
// GOOD: route-level splitting, heavy rare features behind Suspense
import { lazy, Suspense } from 'react';

const ReportBuilder = lazy(() => import('./ReportBuilder'));

<Route path="/reports" element={
  <Suspense fallback={<Skeleton />}>
    <ReportBuilder />
  </Suspense>
} />
```

Modern bundlers tree-shake ESM named imports on their own — profile before changing import styles. The real gains are route-level splitting, lazy heavy/rare features, and auditing the bundle (`source-map-explorer`, `webpack-bundle-analyzer`, `next/bundle-analyzer`) for duplicated or oversized dependencies. Check the checklist budget before and after.
