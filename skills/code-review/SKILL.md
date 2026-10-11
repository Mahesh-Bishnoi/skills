---
name: code-review
description: Review PRs, commits, diffs, modules, folders, or whole repos for correctness, normal security, performance, tests, and clean-code lean. Use on explicit review requests (including explicit pre-merge review). For deep OWASP or full security audits use security-audit instead.
---

# Code Review

Review-only skill. Report findings, change no code, never merge, deploy, or approve on the author's behalf. The best review is high-signal and actionable: concrete cases with file and line references, ordered by severity, no vague worries or style taste.

Project `AGENTS.md` and existing codebase conventions override this skill. Companion skills: `clean-code` for depth/SOLID/anti-slop judgments, `security-audit` for deep security (ask the user to invoke `@security-audit`, do not duplicate), `skill-inspector` for third-party skill installs (ask the user to invoke `@skill-inspector`, do not duplicate).

## 0. Resolve the target

Review what the user names; nothing named means uncommitted changes, or the last commit if the tree is clean.

- Diff targets: `uncommitted`, `staged`, `branch <name>`, `PR <link|number>`, `commit <sha>`, or explicit `paths`.
- Scope targets: `module`, `folder`, or whole repo (user must say `folder <path>` or `whole repo`).
- Confirm the diff is non-empty (`git diff`, `git log --oneline -5`, `gh pr diff`) before reviewing. State the resolved target in one line at the start of the report.
- Diff review covers changed lines plus bugs in unchanged lines of touched functions the change re-exposes. Folder/repo review covers mapped flows (see §1).

## 1. Gather context first

Read before judging. A change can break code it does not touch.

1. Read the project `AGENTS.md` for stack, entry points, and conventions. Newly introduced violations of its explicit rules are findings; silent or inferred "spirit" violations are not.
2. For diffs: read every hunk, then the enclosing function for each hunk, then callers of every changed function, the functions it calls, and the tests. Then check entry wiring the diff could orphan: app entrypoints, CLI commands, scheduled jobs. Find expected load from README or config (one person vs many users/processes) and state the load assumed.
3. For folder/repo: map first — README, build/deploy config, dependencies, entry points, tests. Trace main flows and read fully the paths with user input, money, auth, data writes, background jobs, and shared state. Before calling code unused, grep the whole tree including tests, fixtures, config, and string references.
4. For deleted or replaced lines, name the invariant the old code enforced and search the new code for where it is re-established. A dropped guard, narrowed validation, lost error path, or deleted test covering a real case is a candidate finding. Extend the same check to docs: grep `docs/` and README for moved modules, symbols, and entrypoints — stale runnable instructions are findings (fix live docs; closed decision records get a superseding note, not a rewrite).
5. A `shortcut:` comment that names its limit is a decision, not a finding.
6. For moved symbols, expect caller/test imports updated at the new path; flag backward-compat shims or re-exports unless external consumers exist.

## 2. Review in this order

Check earlier items first; they outrank later ones when cutting to the cap.

1. **Correctness** — wrong result, crash, missed edge case, caller broken by the change, fix in one caller while the shared function stays broken, inverted conditions, off-by-one, null dereference, missing `await`, falsy-zero treated as missing, swallowed errors, removed guards.
2. **Normal security (surface only)** — hardcoded secrets in the diff, unparameterized queries, unescaped user input rendered to HTML, user-controlled file paths, missing auth check on a touched route, secrets or PII in logs or error responses, PII in telemetry/metric labels, model/LLM output passed into queries/DOM/shell without validation, overly permissive CORS or missing security headers introduced by the diff. Anything needing OWASP-depth, business-logic chains, privilege escalation paths, dependency CVEs, or timing attacks is one finding: recommend the user invoke `@security-audit`, do not attempt the audit here.
3. **Performance and scale** — check-then-write races, same work done by every process, memory that only grows, query per item (N+1), O(n^2) on big input, unbounded queries or collections, blocking work added to startup or hot paths. Small diffs: big slowdown = problem, small = suggestion.
4. **Tests** — risky logic (branch, loop, parser, money, auth, data writes, concurrency) without a test; tests asserting nothing or only "didn't throw"; expected values computed with the code under test; weakened or deleted tests. Review tests first: if the test would pass on broken code, say so.
5. **Architecture and clean-code** — apply `clean-code` judgments only with a concrete cost: shallow pass-through modules (deletion test), single-responsibility violations, domain importing infrastructure, circular dependencies, narrowest-type and dependency-injection violations, error idiom mismatches, illegal states left representable. Never split by line count alone.
6. **Lean** — dead code, helper the repo already has, stdlib or platform feature instead of custom code or a new dependency, abstraction with one implementation, near-copies to merge, function doing several unrelated jobs to split. Propose the smallest fix, prefer deleting code, never add layers.

Never cut from review scope: trust-boundary validation, data-loss error handling, security, accessibility, anything the user asked for. Never report: formatting or lint CI already enforces, generated files or lockfiles, subjective style, or pre-existing issues outside the diff unless critical and newly re-exposed (label those `pre-existing`).

## 3. Verify before reporting

Every finding needs a concrete case; re-read the lines to confirm it.

- Cite the exact `file:lines`. Vague locations are dropped.
- Describe the concrete failure mode: input, state, and bad outcome. If the trigger cannot be named, it is pattern-matching, not a finding — drop it.
- Check surrounding context: callers, imports, types, framework defaults. Many apparent issues are handled one frame up.
- Confidence gate: report only issues with confidence at or above 80%. Downgrade or drop the rest. `blocking` and `important` require the snippet, the failure scenario, and why existing guards do not catch it.
- Consolidate duplicates (same defect, same reason: one finding). Cap at 10 findings and at most 5 nits; mention the rest as a count in the summary.
- It is acceptable and expected to return zero findings.

## 4. Report

Use very simple English and explain technical terms. Findings first; summaries do not dilute the signal.

Start with `What this change does:` in 2-3 sentences (or `What this repo does:` for folder/repo reviews) plus the load assumed.

Then numbered findings grouped `blocking / important / nit`. Each finding:

- Bold title with `file:lines`.
- Four bullets, 1-2 short sentences each: `What this is`, `Problem`, `Fix`, `If we skip it`.
- Severity rule: `blocking` = fix before merge (will break, lose data, or open an obvious hole). `important` = should fix (real cost, missing test, slow path, concrete clean-code harm). `nit` = minor or preference with a practical benefit. Severity inflation erodes trust: a missing comment is never `blocking`.

End with:

- `Verdict:` one of `Approve` (no blocking or important), `Request changes` (important only), `Block` (any blocking).
- `Lean: -N lines possible.` when lean findings exist (plus `-M dependencies` for folder/repo).
- `Not checked:` anything material that could not be checked.
- Nothing found: `Looks good. Ship.`
