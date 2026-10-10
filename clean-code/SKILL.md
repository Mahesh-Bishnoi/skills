---
name: clean-code
description: Language-agnostic architecture and clean-code rules for writing, modifying, refactoring, or reviewing code — deep modules, seams, SOLID, dependency injection, TDD, testing, error handling, and anti-slop discipline. Load before any non-trivial code change.
---

Goal: code that stays easy to change after 100 edits by different agents. Every rule serves one test — *can the next change be made locally, safely, and obviously?* Project `AGENTS.md` and existing codebase conventions override this skill.

## 0. Before writing code

1. Read the surrounding code. Find existing helpers, types, patterns, and naming — reuse them. Search (`grep`) before creating any function, type, or file.
2. Read the project's domain glossary (`GLOSSARY.md` or similar) and architecture decision records (location per the `adr-skill` convention rule — match existing, default `docs/decisions/`) if present. Use domain terms for names; don't re-litigate recorded decisions without a concrete new reason.
3. State the change in one sentence. If you can't, split the task.
4. Identify the owner: which module owns this behavior? Put it there, not where it's convenient.
5. Map the blast radius before editing: list every place the change must reach (callers, tests, fixtures, config, exports) and what it could break for users (data destroyed/exposed, callers that stop working). Extra features are not scope.
6. Write or locate the test that will prove it works (§7).
7. Prefer the smallest complete diff that solves the problem cleanly. Boy-scout only the code you touch (rename unclear vars, add missing types, remove dead code in touched functions) — no module restructures, new patterns, or edits to files the task doesn't otherwise require. Be economical about the solution, never about the change itself: finish every caller, test, and fixture the task touches.

## 1. Core principles (ranked — earlier wins on conflict)

1. **Correctness & clarity** over cleverness. Code is read 10× more than written.
2. **KISS / YAGNI** — build for today's requirement. No hooks, flags, params, or layers "for later". Take the first option that fully works: (1) skip it if nobody asked for it; (2) reuse existing codebase helper/pattern; (3) stdlib or platform feature; (4) installed dependency — never add one for a few lines; (5) one line a reader gets at a glance; (6) otherwise the minimum code that works.
3. **Deep modules, high cohesion, loose coupling** — lots of behavior behind small interfaces; things that change together live together; things that change independently are separated by narrow interfaces.
4. **Locality** — a change, a bug fix, or a piece of knowledge should land in one place, not be spread across callers.
5. **DRY by knowledge, not by text** — dedupe a *rule/fact* that must stay consistent. Similar-looking snippets that change for different reasons are NOT duplication. Rule of three: abstract on the 3rd real occurrence, not the 2nd.
6. **Explicit over implicit** — no hidden globals, magic, monkey-patching, or action-at-a-distance. Separate mechanism from policy: pure helpers compute and return values (`isValid(x) -> bool`, `format(x) -> string`, `transform(x) -> y`); callers decide what to do (`if (!isValid(x)) throw ...`, `flag ? transform(x) : x`, `log(format(x))`). Never hide throws, branches, feature-flag checks, or IO inside a helper that reads like a passive check.
7. **Least astonishment** — a function does exactly what its name and signature promise, nothing more. A getter retrieves; it doesn't track analytics, mutate state, or send notifications. Extra work belongs at the call site or in a wrapper whose name advertises it.
8. **Economy with guardrails** — deletion beats addition; keep values in the form the platform already gives you; no wrapper, conversion, option, or boilerplate nobody asked for. The shortest working diff wins once the full blast radius (§0.5) is known — a one-liner needing decoding is not short. Between equal-size options, pick the one correct on edge cases. Never economize away: trust-boundary validation, data-loss error handling, security, accessibility, or anything the user asked for.

## 2. Modules, interfaces, seams

Vocabulary (scale-agnostic — applies to functions, classes, packages, services):
- **Module** = interface + implementation.
- **Interface** = *everything* a caller must know to use it correctly: signature, invariants, call ordering, error modes, required config, performance traits. Not just the type signature.
- **Depth** = behavior a caller gets per unit of interface learned. **Deep** = small interface hiding much behavior (good). **Shallow** = interface nearly as complex as the implementation (pass-throughs, thin wrappers — bad).
- **Seam** = a place where behavior can be swapped without editing that place; where an interface lives. **Adapter** = a concrete thing plugged into a seam (Postgres repo, in-memory fake).

Rules:
- When designing an interface, ask: fewer methods? simpler params? can more complexity hide inside? Pull complexity down into the module rather than pushing it onto every caller.
- **Deletion test:** imagine deleting the module. If complexity vanishes, it was a pass-through — inline it. If complexity reappears across N callers, it earns its keep.
- **One adapter = hypothetical seam; two = real seam.** Introduce an interface/port only when ≥2 implementations are justified (production + test fake counts). A single-implementation interface is indirection.
- **Internal vs external seams:** a deep module may be built from small private parts with their own seams; don't expose them through the public interface just because tests use them.
- **Design it twice:** for any non-trivial interface, sketch 2–3 radically different shapes (minimal entry points / most-common-caller-trivial / maximally flexible) and pick on depth and locality. The first idea is rarely best.
- Don't split code that must be understood together into many tiny modules — bouncing between 6 files to follow one concept is a design failure, not modularity.

## 3. SOLID (applied, not academic)

- **S — Single responsibility:** a module has one reason to change. Smell: name needs "and"/"Manager"/"Helper"/"Util", or >1 unrelated dependency group. Balance with depth: one *responsibility*, not one *line*.
- **O — Open/closed:** add new variants by adding code (new strategy/handler), not by editing a growing `if/switch` scattered across the codebase. Apply only once variation actually exists.
- **L — Liskov:** a subtype must honor the parent's contract — no throwing "not supported", no tightened inputs, no weakened outputs. If it can't, don't inherit.
- **I — Interface segregation:** small role-specific interfaces (`Reader`, `Clock`) over fat ones. Consumers depend only on what they call.
- **D — Dependency inversion:** high-level policy depends on abstractions it *owns*; low-level details (DB, HTTP, FS, SDKs) implement them. Business logic never imports infrastructure.

## 4. Architecture & boundaries

- **Dependencies point inward:** `domain ← application ← adapters/infrastructure ← entrypoint (wiring)`. Domain has zero framework/IO imports.
- **Functional core, imperative shell:** pure logic (calculations, decisions, transformations) in side-effect-free functions; IO, time, randomness, network, DB at the edges. Return results instead of mutating/causing effects where possible. But don't extract pure helpers *only* for testability when the real bugs live in how they're wired — test the module through its interface.
- **Transparent orchestration:** hide computation, show effects. An orchestrator lists every side effect as its own visible line (`save`, `charge`, `notify`, `publish`) so a reader sees the full workflow without opening callees. Never bury N side effects inside one opaque `process(x)` call.
- **Ports & adapters:** define the interface in the consumer's terms (`OrderRepository.save(order)`), implement per technology (`PostgresOrderRepository`, `InMemoryOrderRepository`).
- **Modules are independent:** small public API, hidden internals. No reaching into another module's private files/fields. No circular dependencies — if A↔B, extract the shared concept or invert one edge.
- **Organize by feature/domain**, not technical layer, when the project allows (`billing/`, `auth/` over `controllers/`, `services/`, `models/` dumping grounds).
- **One composition root:** wire concrete dependencies in one place (main / app factory / DI container). Everything else receives dependencies.
- **Config** is loaded once at startup, validated, and passed in as typed values. No `getenv` scattered through logic.

## 5. Dependency injection & coupling

- Pass collaborators in (constructor/function params). Never construct infrastructure inside logic (`new StripeClient()`, `db.connect()` inside a service method).
- Inject nondeterminism: clock, random/UUID, env, filesystem. This makes tests deterministic.
- No singletons / mutable globals / module-level state. Constants are fine.
- Depend on the narrowest type needed (an interface or a function), not a concrete class or a whole context object.
- Law of Demeter: talk to direct collaborators; `a.b().c().d()` signals a missing abstraction.
- **Composition over inheritance.** Inheritance only for true is-a with a stable base; max ~2 levels.
- Avoid temporal coupling (must call `init()` before `run()`): make invalid sequences impossible via constructors/builders, or document the ordering as part of the interface.

## 6. Code-level rules

**Functions**
- Do one thing at one level of abstraction. Aim <30 lines; extract a *private* helper when a block needs a comment explaining *what* it does. New *public* modules must pass the deletion test.
- ≤3–4 params; more → parameter object. No boolean flag params that switch behavior — split into two functions.
- Guard clauses / early return over deep nesting (max ~3 levels).
- Command–query separation: return data or cause a side effect, not both (except well-known idioms like `pop`). Queries (`get`, `is`, `find`, `validate`-that-returns-bool) never mutate, throw for control flow, log, or emit — side effects go in explicitly named commands at the call site.
- Call-site honesty: every branch, throw, and side effect is visible where triggered. Bad: `validate(x)` that throws inside, `applyFeature(x)` that checks a flag inside, `logResult(x)` that hides logger/format/destination. Good: `if (!isValid(x)) throw ...`, `flag ? applyFeature(x) : x`, `log(format(x))`.

**Data & types**
- **Make illegal states unrepresentable:** enums/sum types over string flags; required fields required; no `status` + nullable fields whose validity depends on `status`.
- **Parse, don't validate:** convert untrusted input into a validated type once at the boundary; inner code trusts the type and never re-checks.
- Avoid primitive obsession: `EmailAddress`, `Money`, `UserId` over raw strings/floats where mistakes are costly. Never use floats for money.
- Prefer immutability; mutate only local or clearly owned state. Data flows through return values, never out-params: `result = f(base)` not `f(&result)`. Bind once (`const`); a reader must see where each value comes from at the call site without checking whether the callee also mutated its input.

**Naming**
- Names reveal intent in domain language: `calculateInvoiceTotal`, not `process`/`handle`/`doStuff`/`data2`. If a glossary exists, use its terms; add new domain terms to it.
- Booleans read as predicates (`isActive`, `hasAccess`). Functions are verbs, types are nouns.
- One word per concept across the codebase (don't mix `fetch`/`get`/`load` for the same thing).

**Errors**
- Fail fast and loud where detected; never swallow (`catch {}`, `except: pass`, silent `return null`).
- Catch only where you can *handle* (retry, fallback, translate, report). Otherwise propagate.
- Translate at boundaries (DB error → domain `NotFound`); don't leak infrastructure errors into the domain.
- Use one error idiom per module (exceptions *or* result types), matching the codebase.
- Messages say what failed, with which input/ID, and what was expected.

**Comments**
- Explain *why* (constraints, trade-offs, non-obvious decisions, issue links), never restate *what*.
- A deliberate shortcut with a known limit gets one line in this form: `shortcut: <the limit>, <when to upgrade>`. Prefer it over a vague TODO.
- No commented-out code, changelog comments, or `// added by AI` / `// new code here`.

## 7. Testing & TDD

**TDD loop (default for logic and bug fixes)**
1. **Red** — one failing test for the next small behavior. Run it; confirm it fails *for the right reason*.
2. **Green** — minimum code to pass.
3. **Refactor** — clean code and tests with everything green.
- Bug fix = first a test reproducing the bug, then the fix. Before editing, grep every caller of the touched function and fix the root cause once in the shared code, not per caller. Moved or merged code keeps its error handling and validation.

**The interface is the test surface**
- Callers and tests cross the same seam. Test behavior through the public interface, assert on observable outcomes, not internal state or private calls.
- Tests must survive internal refactors. If a test changes when only the implementation changed, it's testing past the interface — the test or the module is the wrong shape.
- **Replace, don't layer:** when shallow modules are merged into a deeper one, write tests at the new interface and delete the old per-fragment tests.

**Pick test strategy by dependency category**
| Dependency | Strategy |
|---|---|
| In-process (pure logic, memory) | Test directly; no doubles |
| Local-substitutable (DB, FS with local stand-in: SQLite/PGLite, temp dir, test container) | Use the real stand-in in tests; no port needed |
| Remote but owned (your other services) | Port at the seam; in-memory adapter in tests, HTTP/queue adapter in prod |
| True external (Stripe, Twilio, LLM APIs) | Injected port; fake/mock adapter in tests + a few contract tests |

**Good tests**
- Arrange–Act–Assert; one behavior per test; name states the spec: `rejects_order_when_stock_insufficient`.
- Deterministic (no real time, network, randomness, sleeps, shared state), independent (any order, parallel), fast (unit suite in seconds).
- Prefer real objects > in-memory fakes > stubs > mocks. Mock only ports you own, never third-party internals or the unit under test. Needing 5 mocks = too many dependencies.
- Pyramid: many tests on the pure core and module interfaces, fewer integration tests on adapters, few end-to-end tests on critical paths. Run the same contract suite against fake and real adapters.

**Never**
- Weaken, skip, or delete a failing test to make it pass. Change a test only when the *requirement* changed — say so explicitly.
- Assert on nothing, or only "didn't throw", when behavior can be checked.
- Compute expected values with the code under test.

## 8. Design patterns — only when the trigger appears

| Pattern | Trigger |
|---|---|
| Strategy | Same operation, multiple interchangeable algorithms chosen at runtime; replaces a growing `switch` |
| Adapter | Wrap a third-party/legacy API behind your own interface |
| Repository | Isolate persistence behind a collection-like domain interface |
| Factory | Construction is complex or the concrete type is chosen at runtime |
| Decorator | Cross-cutting behavior (caching, retry, logging, metrics) without editing the wrapped code |
| Observer / events | Many independent reactions to one occurrence; decouple producer from consumers |
| Command | Operations must be queued, logged, retried, or undone |
| Builder | Many optional construction params; enforce valid assembly |
| Null Object / Optional | Repeated `if x is null` checks for a default "do nothing" behavior |
| Facade | Give a complex subsystem a small, deep interface for the common case |

No pattern without its trigger. Patterns obey the one-vs-two-adapter rule.

## 9. Cross-cutting concerns

- **Logging:** structured, at boundaries and decision points, with correlation IDs. Never log secrets/PII. Don't log-and-rethrow at every layer. Follow the `observability` skill §3 for event shape and the visible `log(format(x))` call-site rule (never a `logResult(x)` wrapper that hides message, format, or destination). For production telemetry design (RED/USE metrics, tracing, alerting), use the `observability` skill.
- **Security:** validate external input at the boundary; parameterized queries only; least privilege; secrets from env/secret store, never in code. Validate server-side fetch URLs against an allowlist (SSRF); back rate limiters with a shared store when >1 instance serves traffic; strip sensitive fields before any response; treat model/LLM output as untrusted input.
- **Concurrency:** avoid shared mutable state; if unavoidable, give it one owner. Make retried operations idempotent.
- **Performance:** clear first, measure, then optimize the measured hotspot (see the `performance` skill). Watch for N+1 queries and unbounded loops/collections in IO paths.
- **Resources:** always release files, connections, locks via scoped constructs (`with`, `using`, `defer`, try-with-resources).
- **Public APIs/schemas:** hard to misuse; additive changes over breaking ones; version intentionally.

## 10. Anti-slop rules (common LLM failure modes — never do these)

- Duplicating a helper that already exists because you didn't search.
- `utils`/`helpers`/`common` dumping grounds — name modules by domain concept.
- `foo_v2`, `new_foo`, `foo_fixed`, `foo_old`. Change the original; delete the old.
- Dead code, unused imports/params/vars, stale TODOs, debug prints left behind.
- Defensive `try/catch` or null checks around everything "just in case" — handle only failures that can occur.
- Speculative generality: config options, abstract bases, plugin systems, interfaces with one implementation, params nobody uses.
- Shallow wrappers and pass-through layers that add files but no depth.
- Silent fallbacks that hide bugs (`return []` / default values on error).
- Shotgun edits: one concept change touching 10 files means a missing deep module — fix that.
- Backward-compat shims or re-exports for code with no external consumers.
- Rewriting working code wholesale when a targeted edit suffices; reformatting unrelated lines.
- Style inconsistent with the surrounding file (naming, error idiom, import order).
- Narrating comments (`// Now we loop over users`).
- Inventing APIs/library functions — verify they exist in the installed version.
- Claiming done without running tests/linter/type-checker.

## 11. Improving existing code

- Focus where change happens: `git log --oneline` / file churn reveals hot spots. Refactoring cold, stable code is usually waste (YAGNI).
- Look for friction: one concept spread across many tiny modules; shallow modules; tightly coupled modules leaking across seams; code untestable through its current interface.
- Deepen: merge shallow fragments behind one small interface, pick the seam by dependency category (§7), replace old tests with interface tests.
- Refactor with tests green before and after; keep refactor commits separate from behavior changes. Opportunistic cleanup stays adjacent to the task; unrelated restructures are a separate task, not boy-scouting.

| Smell | Fix |
|---|---|
| God class / file >~400 lines with unrelated responsibilities | Split by responsibility |
| Concept scattered across many tiny files | Merge into one deep module |
| Long function | Extract private helper; name the intent |
| Long param list / data clumps | Parameter object / value type |
| Feature envy | Move behavior to the data's owner |
| Repeated `switch` on type | Polymorphism / strategy |
| Shotgun surgery | Consolidate the concept into one module |
| Divergent change (one module, many reasons to change) | Split per reason |
| Deep nesting | Guard clauses, extract function |
| Message chains | Add method on the direct collaborator |

## 12. Self-review before finishing (mandatory)

- [ ] Reused existing code/patterns; no duplicated logic or parallel versions.
- [ ] New modules are deep (pass the deletion test), single-responsibility, domain-named.
- [ ] New interfaces/ports have ≥2 justified adapters; otherwise inlined.
- [ ] Dependencies injected; no new globals; domain doesn't import infrastructure.
- [ ] No hidden control flow or side effects: validators return values (caller throws/branches), flags checked at call site, orchestrators list each IO, getters cause no writes.
- [ ] Untrusted input parsed at the boundary; errors neither swallowed nor leaked raw.
- [ ] Tests exercise behavior through the public interface, are deterministic, and were seen failing first.
- [ ] No dead code, debug output, unused params, commented-out code, or narrating comments.
- [ ] Diff is minimal and scoped; no unrelated reformatting.
- [ ] Formatter, linter, type-checker, and tests run and pass — report what you ran.
- [ ] Reply ends with 1–2 lines: what was skipped or not checked, and any risk the user must know.
