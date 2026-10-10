---
name: security-audit
description: Security guidance and vulnerability review for codebases, APIs, services, CLI, libraries, and daemons. Use on explicit request for security guidance, review, audit, or pen test. Full workflow only for explicit full audit or requested report artifacts.
---

# Security Audit

Find vulnerabilities that violate a real trust boundary, then give owners the source evidence, safe reproduction, priority, and smallest effective fix. This is a defensive, source-first workflow. A candidate without a concrete affected principal, resource, or security outcome is not a confirmed finding.

## Operating modes

This skill is guidance by default. Loading it does not authorize the complete audit workflow or file creation.

- **Guidance mode**: For security questions, focused reviews, methodology, triage, or investigation of specific findings, use only the relevant parts of this skill. Do not automatically run all six phases, create an output directory, or write audit artifacts. You may launch focused agents when useful; they return results to the current task.
- **Full audit mode**: Use the complete workflow when the user explicitly asks to audit or pen-test a codebase, asks for a full, comprehensive, or end-to-end security review, or requests report artifacts. Run all six phases and write the files defined below.

If the request could mean either mode, ask one focused question before creating files or starting the complete workflow.

## File map

Companion guides and validators stay at the skill root (layout move deferred). See [references/FILEMAP.md](references/FILEMAP.md) for one line per file.

## Platform terminology

This skill is agent-neutral:

- **Parent** is the agent that coordinates the run and owns shared state.
- **Task tool** is the platform's delegation or sub-agent mechanism.
- **`explore` agent** is OpenCode's read-only delegated agent for focused source exploration and factual verification.
- **`general` agent** is a delegated agent for broad investigation and bounded local execution.
- **`subagent_type:`** in a heading names which of these two delegated agent roles runs that work.

Use equivalent platform capabilities while preserving role, write-isolation, prompt, and independence boundaries. On OpenCode, Task tool = `subagent` (`agent: explore` for read-only exploration, `general` for broad investigation and bounded execution); fan out background agents per the `parallel-dispatch` skill (independent tasks only, ≤3–4 concurrent workers, self-contained prompts). All parallel fan-out — reconnaissance, hunters, verifiers — stays within that ≤3–4 cap: "one verifier per finding, in parallel" means queue verifiers in batches, not unbounded fan-out.

## Universal execution safety

These rules apply in both operating modes. Source inspection is read-only. Run target-controlled builds, tests, processes, browsers, emulators, fuzzers, and fixture processing only inside an OS-enforced sandbox that provides all of these controls:

- no external network; use only an isolated loopback namespace when the check needs local client/server traffic;
- an empty environment populated from an explicit allowlist with safe values, with scratch-local `HOME`, temporary directories, and caches;
- a read-only target and toolchain, with the target-controlled process able to write only inside its assigned `scratch/` directory; and
- explicit low CPU, memory, process, file-size, disk, and wall-clock limits.

The agent, outside the target-controlled process, may make a disposable source copy in an assigned `scratch/` directory when a build must write beside source. In guidance mode, do not retain target-controlled files. In full audit mode, only trusted parent-side code may promote the minimum non-secret result to retained `artifacts/` using the procedure under Write isolation. Never expose a retained output directory (other than the agent's own assigned `scratch/`), another agent's directory, the host home directory, credentials, sockets, or shared services to target code. Do not install dependencies or let builds fetch them. Use only tools and dependencies already available locally. If every control cannot be enforced, do not execute target code: report the missing sandbox capability as a needs-validation blocker and give a safe validation plan.

Use dummy principals, fixtures, and secrets. Do not probe deployed endpoints, external services, shared infrastructure, production identities, other users' data, or live control planes. Do not test availability against a live or shared process, publish artifacts, alter releases, spend paid API quota, or continue beyond the minimum local effect needed to establish a defect. If the decisive fact is outside source or the sandboxed fixture, report it as needing validation.

## Full audit setup

Full-audit mode resolves skill dir, target, repo name, output dir, and source ref, then enforces parent-only writes with sandboxed promotion.
It seeds a deterministic coverage ledger, applies prior-run rules, and picks a `quick` / `standard` / `deep` (or scoped) profile under a strict agent budget.
Verifier fan-out is queued in ≤3–4-worker batches within that budget; unvalidated candidates stay ledger-only under an `incomplete` status.
Guidance mode does not need this file. Full detail: [references/full-audit-setup.md](references/full-audit-setup.md).


## Core principles

### Require a boundary and result

For every candidate, name the lower-trust principal, accepted input or action, intended control, crossed boundary, affected principal or resource, and concrete observed or owner-observable result. Do not elevate a missing best practice, guessed deployment behavior, generic parser crash, or self-impact into a security finding.

### Use bounded local evidence

Static analysis establishes the source path. Sandboxed local tests resolve behavior when all execution controls are available: a minimal function harness, existing unit test, small parser fixture, dummy-tenant integration test, locally rendered configuration, or bounded isolated-loopback client. Stop at a wrong return value, unauthorized dummy record, sanitizer finding, policy difference, or other minimum effect. Do not extend the local check beyond the minimum boundary result or produce persistence, post-fault, or concealment material.

### Respect source visibility

Deployment controls, proxy behavior, provider settings, browser headers, identity policy, broker ACLs, packaging, and topology are real controls. If they are required and absent from the repository, do not assume either presence or absence. Use `needs_validation` with the exact missing fact and a safe owner-observed or local plan.

### Separate priority from certainty

Only `confirmed` records receive severity. Likelihood and impact must reflect the demonstrated conditions and result; overall severity cannot exceed demonstrated impact. `needs_validation` means a specific source-grounded boundary hypothesis is blocked, not a low-confidence confirmed vulnerability, and it has no severity.

Calibrate overall severity with these anchors:

- **critical** — an unauthenticated actor gains code execution, full data-store access, or takeover of arbitrary accounts.
- **high** — an actor fully defeats an explicit security control with real consequences: authentication bypass, cross-tenant read or write, stored script execution affecting other users, authenticated code execution, or an unauthenticated remote stop of a shared service.
- **medium** — a real boundary violation with limited blast radius, uncommon preconditions, or consequences confined to a narrow resource set.
- **low** — disclosure of non-secret internals, or an effect requiring sustained effort for minimal gain.
- **informational** — a confirmed but minimal-impact observation, useful mainly as a prerequisite inside a larger finding.

The high/medium discriminator: does the demonstrated result fully defeat an explicit control for an action with real consequences, or only weaken it? If you cannot state the concrete damage, the severity is lower than it feels.

### Recommend the smallest effective source fix

For each confirmed finding, identify the invariant the code must enforce and the narrowest source change that enforces it at the last trusted decision point. Prefer specific repository-relative changes and regression tests over generic hardening advice. The audit describes fixes; it does not modify target source.

## Full audit workflow

In full audit mode, follow all six phases in order:

1. **Reconnaissance** — map the source, trust boundaries, local build paths, companion selections, prior evidence, and initial deterministic coverage ledger with [RECONNAISSANCE.md](RECONNAISSANCE.md).
2. **Coverage-led hunting waves** — assign isolated hunters from the ledger and collect structured candidate results with [HUNTING.md](HUNTING.md), [ATTACK-CLASSES.md](ATTACK-CLASSES.md), and the selected domain companions.
3. **Candidate validation** — consolidate fingerprints and give every candidate to a fresh source verifier (queued in ≤3–4-worker batches) as defined in [VALIDATION-AND-REPORTING.md](VALIDATION-AND-REPORTING.md).
4. **Structured output** — write all final `confirmed`, `needs_validation`, and `rejected` records to `findings.json`; validate it with `report-schema.json` and `validate-findings.cjs`, and validate the coverage claim with `validate-coverage-ledger.cjs`.
5. **Independent record verification** — use fresh agents (queued in ≤3–4-worker batches) to verify final source claims and reconcile corrections or state changes.
6. **Target-neutral report** — derive `REPORT.md`, `FINDINGS-DETAIL.md`, and `NEEDS-VALIDATION.md` from the final records, with no live-probe instructions.

Do not end the run before one of exactly two terminal states: (a) all Phase 6 artifacts are written and both validators pass, or (b) `run_status: "incomplete"` is recorded with its exact reason and the gap is disclosed in the report. Never stop mid-phase.

## Anti-patterns

1. Checklist deviations presented as vulnerabilities.
2. Defense-in-depth advice with no reachable boundary violation.
3. Live or shared-environment testing where bounded local evidence is insufficient.
4. Guessing provider, proxy, browser, identity, or deployment behavior not present in source.
5. Treating intended same-principal authority or self-impact as a cross-boundary result.
6. Reporting a parser or runtime effect stronger than the observed effect.
7. Emitting prose-only hunter results that cannot be deduplicated or verified.
8. Re-reporting carried same-source prior confirmed records or using them as exemplars that anchor the hunt.
9. Assigning severity to `needs_validation` records.
10. Writing the report before independent verification or letting prose and JSON disagree.
