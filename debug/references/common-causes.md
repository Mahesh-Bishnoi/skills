# Common causes by symptom

Use in Step 4 to generate hypotheses. Find the row that matches your symptom, turn each likely cause into a hypothesis with a prediction, and test the cheapest first. These are starting points, not answers — every hypothesis still needs a probe.

## Symptom → likely causes → cheapest check

| Symptom | Likely causes | Cheapest check |
|---|---|---|
| My change has no effect | Stale build/bundle, server not restarted, cache, editing wrong file/copy, installed package shadows local source, wrong branch/worktree | Tagged canary log at the edit point (Step 3b); `which`/`pip show -f`/`npm ls` to see what's loaded |
| `null` / `undefined` / `None` / `nil` error | Missing key or wrong key name/case, async value used before it resolved, function returned early without value, optional field absent in real data | Print the object right before the failing line, with `repr`/`JSON.stringify` |
| Wrong value, no error | Off-by-one, wrong operator (`=` vs `==`, `and` vs `or`), integer division, float rounding, wrong unit (ms vs s, cents vs dollars), shadowed variable, mutation of shared object | Print inputs and output of the function; compute the expected value by hand |
| Works first time, fails on second | Mutable default argument, module-level/global state, cache not invalidated, resource not closed, one-shot iterator/stream already consumed | Call it twice in a row in a throwaway script |
| Intermittent / flaky | Race condition, missing `await`, test order dependence, shared state between tests, real time/clock, random seed, network, timeouts too tight, unordered collections (set/dict/readdir) | Run with `repeat.sh`; run the test alone vs. in the full suite; run tests in random/reversed order |
| Fails only in CI / prod / another machine | Dependency version drift, env var missing, timezone/locale, case-sensitive filesystem, file path separators, CPU count / parallelism, permissions, data differences | Diff environment output (see loop-recipes "Works locally, fails in CI") |
| Fails only at a certain time/date | Timezone, DST change, month-end/leap-year, date parsing format, token/cert expiry | Run with a pinned clock / `TZ=UTC` vs local TZ / faked date |
| Garbled text / weird characters | Encoding mismatch (UTF-8 vs Latin-1), double encoding/escaping, BOM, normalisation (é as 1 vs 2 code points) | Print `repr()` / byte values of the string |
| Hangs / never returns | Deadlock, waiting on a promise/future that never resolves, infinite loop, blocking I/O without timeout, pool exhausted | Dump stacks while hung (`py-spy dump`, `jstack`, `kill -QUIT` for Go, Node `--inspect` pause) |
| Slow / got slower | N+1 queries, missing DB index, work inside a loop, loading all rows into memory, regex backtracking, sync I/O in hot path, cache miss every time | Profile (see loop-recipes); count queries; `EXPLAIN ANALYZE` |
| Memory grows until crash | Unbounded cache/list/map, listeners/subscriptions never removed, closures holding large objects, unclosed resources | Heap snapshot at two times and diff; check collection sizes over time |
| Error inside a library | You passed wrong type/shape, unsupported version combination, called in wrong order (missing init), library bug (rare — check last) | Read the frame where *your* code calls the library; check installed version vs docs version; search the exact message in the library's issues |
| Import / module not found | Wrong working directory, missing install, circular import, name collision with a local file (e.g. your `random.py`), wrong virtualenv | Print `sys.path` / `require.resolve` / `go env`; check for local files named like the package |
| Permission denied / file not found | Relative path resolved from a different working directory, file created by another user, path case mismatch | Print the absolute path and `os.getcwd()` / `process.cwd()` at runtime |
| Test passes alone, fails in suite | Shared state leaking between tests, test order, global mocks not restored, leftover DB rows/files | Run the suite in a different order; run the failing test together with only the test before it |
| HTTP 4xx/5xx | 400: request body/shape wrong · 401/403: auth/token/scope · 404: wrong URL/route/ID · 409/422: validation · 500: server exception — read server logs, not the client error · CORS: browser-only, check response headers | Read the server-side log for that request; replay with curl |
| Data looks right in DB, wrong in UI (or reverse) | Serialisation/mapping layer, stale client cache, wrong field name between API and UI, timezone conversion at boundary | Inspect the raw API response in between |

## Questions that crack many bugs

- What is the **first** thing that goes wrong? (Not the last error — the earliest wrong value. Later errors are often just consequences.)
- What changed between when it worked and now? (`git log`, lockfile, config, data, environment.)
- What is different between the case that works and the case that fails? (Input, user, environment, timing.) Make the two cases as similar as possible until one difference remains.
- Am I sure the input is what I think it is? Print it.
- Am I sure this code runs? Canary it.
- Am I sure this is the version of the library I read docs for? Check it.

## Classic traps for agents

- Reading code and "seeing" the bug without running anything — then the fix doesn't work.
- Fixing the line in the stack trace instead of the place where the bad value was created.
- Trusting the user's guess of the cause instead of their description of the symptom. Take the symptom literally; treat the diagnosis as one hypothesis.
- Seeing a *different* error during repro and fixing that one instead.
- Making the test pass by changing the test.
- Leaving debug prints, temp files, or probe edits in the final diff.
