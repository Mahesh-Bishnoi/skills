# Feedback loop recipes

Copy-paste starting points for Step 2. Adapt names and paths to the project. Each loop must check the **exact symptom**, not just "exit code 0".

## Run one test only

| Stack | Command |
|---|---|
| Jest / Vitest | `npx vitest run path/to/file.test.ts -t "test name"` · `npx jest path/to/file -t "name"` |
| Node test runner | `node --test --test-name-pattern="name" path/to/file.test.js` |
| pytest | `pytest path/to/test_file.py::test_name -x -q` (`-x` stops at first failure, `-s` shows prints) |
| Go | `go test ./pkg/... -run '^TestName$' -count=1` (`-count=1` disables test cache) |
| Rust | `cargo test test_name -- --nocapture` |
| JUnit / Gradle | `./gradlew test --tests 'com.x.FooTest.bar'` |
| Maven | `mvn -q test -Dtest=FooTest#bar` |
| RSpec | `bundle exec rspec spec/foo_spec.rb:42` |
| .NET | `dotnet test --filter "FullyQualifiedName~FooTest.Bar"` |

## HTTP endpoint

```sh
# Token comes from the environment, never typed literally.
curl -sS -o /tmp/resp.json -w '%{http_code}\n' \
  -H "Authorization: Bearer $API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d @fixtures/bad-order.json \
  http://localhost:3000/api/orders
# Assert the exact symptom:
grep -q '"total":0' /tmp/resp.json && echo "RED: total is 0" && exit 1 || echo GREEN
```

## CLI output vs known-good snapshot

```sh
./mytool --input fixtures/case.csv > /tmp/actual.txt 2>&1
diff -u fixtures/expected.txt /tmp/actual.txt && echo GREEN || echo RED
```

## Throwaway script calling the function directly

Python:

```python
# debug_repro.py  (delete in Step 7)
from app.orders import calculate_total
result = calculate_total([{"price": "10.10", "qty": 3}])
print("[DEBUG-7f3a] result =", repr(result))
assert result == 30.30, f"RED: got {result!r}"
print("GREEN")
```

Node:

```js
// debug-repro.mjs  (delete in Step 7)
import { calculateTotal } from "./src/orders.js";
const result = calculateTotal([{ price: "10.10", qty: 3 }]);
console.log("[DEBUG-7f3a] result =", result);
if (result !== 30.3) { console.error("RED"); process.exit(1); }
console.log("GREEN");
```

## Headless browser (Playwright)

```js
// debug-ui.mjs  (delete in Step 7)
import { chromium } from "playwright";
const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
page.on("pageerror", (e) => errors.push(String(e)));
await page.goto("http://localhost:3000/cart");
await page.getByRole("button", { name: "Checkout" }).click();
await page.waitForTimeout(1000);
console.log("[DEBUG-7f3a] errors:", errors);
const total = await page.getByTestId("total").textContent();
await browser.close();
if (errors.length || total !== "$30.30") { console.error("RED", total); process.exit(1); }
console.log("GREEN");
```

## Replay a captured payload

1. Capture once: log the raw request body / event / message to a file (redact secrets), or export from browser devtools (Network → right-click → Copy as cURL / Save as HAR).
2. Save it under a temp fixtures path.
3. Feed it to the handler directly (throwaway script) or re-send it with curl. Now the bug reproduces without the original user or environment.

## Random-input loop (property / fuzz)

```python
import random
random.seed(1234)                       # deterministic — rerun gives same inputs
for i in range(1000):
    xs = [random.randint(-5, 5) for _ in range(random.randint(0, 8))]
    got = my_sort(xs)
    if got != sorted(xs):
        print("RED at iteration", i, "input", xs, "got", got)
        raise SystemExit(1)
print("GREEN")
```

When it finds a failing input, shrink it by hand (Step 3c) and use it as the regression test.

## Bisect history

```sh
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit-or-tag>
git bisect run bash path/to/bisect-check.sh   # from scripts/bisect-check.template.sh
git bisect log        # save this
git bisect reset      # ALWAYS run when finished
```

Exit codes for the check script: `0` = good, `1` = bad, `125` = can't test this commit (skip). The script must not live in a tracked path that changes between commits — copy it to a temp location first.

## Differential run

```sh
git worktree add /tmp/old-version <good-commit>
(cd /tmp/old-version && ./mytool fixtures/case.csv) > /tmp/old.txt
./mytool fixtures/case.csv > /tmp/new.txt
diff -u /tmp/old.txt /tmp/new.txt
git worktree remove /tmp/old-version
```

Same idea for two configs, two library versions, or two environments (local vs CI): hold everything else equal and diff.

## "Works locally, fails in CI / prod"

Print and diff these from both environments:

```sh
uname -a; date; echo "TZ=$TZ LANG=$LANG"
node --version; python --version; go version     # whichever apply
env | sort | sed -E 's/(TOKEN|KEY|SECRET|PASSWORD)=.*/\1=<REDACTED>/'
npm ls --depth=0 || pip freeze || go list -m all
```

Usual suspects: different runtime/dependency version (lockfile not used), timezone/locale, case-sensitive filesystem, test order or parallelism, missing env var, file ordering from `readdir`/glob, CPU count, network access.

## Debuggers and tracing

| Stack | Breakpoint / debugger | Extra |
|---|---|---|
| Python | `breakpoint()` in code, or `python -m pdb script.py`; `pytest --pdb` stops at failure | `python -X faulthandler` for hangs/segfaults; `traceback.print_stack()` |
| Node | `node --inspect-brk file.js` then `chrome://inspect`; `debugger;` statement | `console.trace()` shows who called; `NODE_DEBUG=http,net` |
| Browser | DevTools Sources → breakpoint; `debugger;` | Network tab, "Pause on exceptions" |
| Go | `dlv debug ./cmd/app` / `dlv test ./pkg -- -test.run TestX` | `go test -race` for data races; `GOTRACEBACK=all` |
| Rust | `rust-gdb` / `rust-lldb` on the binary | `RUST_BACKTRACE=1`; `dbg!(x)` macro |
| JVM | `-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005` | `jstack <pid>` for hangs/deadlocks |
| C / C++ | `gdb --args ./prog arg` → `run`, `bt` | `-fsanitize=address,undefined`; `valgrind` |
| Any process | — | `strace -f -e trace=file,network <cmd>` (Linux) shows files/sockets touched |

Non-interactive agents can still use debuggers via scripted commands, e.g. `gdb -batch -ex run -ex bt --args ./prog`, or `python -m pdb -c continue script.py` (drops into post-mortem on crash).

## Profiling (performance bugs)

| Stack | Tool |
|---|---|
| Python | `python -m cProfile -s cumtime script.py \| head -30`; `py-spy top --pid <pid>` / `py-spy record` |
| Node | `node --cpu-prof script.js` (open `.cpuprofile` in DevTools); `node --prof` |
| Go | `go test -cpuprofile cpu.out -bench .` then `go tool pprof -top cpu.out` |
| Rust / C / C++ | `perf record -g ./prog` then `perf report`; `cargo flamegraph` |
| SQL | `EXPLAIN ANALYZE <query>`; enable query logging and count queries per request |
| Browser | DevTools Performance tab; Lighthouse |

Timing harness: run the operation N times, report min and median — never a single run.

```sh
for i in 1 2 3 4 5; do /usr/bin/time -f "%e s  %M KB" ./mytool fixtures/big.csv > /dev/null; done
```
