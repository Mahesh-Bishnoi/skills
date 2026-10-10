# security-audit file map

One line per root file. Companion guides stay at root (layout move deferred); full-audit setup lives in `references/`.

- `SKILL.md` — operating modes, safety boundary, workflow overview; entry point (this file).
- `ATTACK-CLASSES.md` — ordinary attack-class menu (injection, access control, crypto, business logic, etc.).
- `RECONNAISSANCE.md` — Phase 1 source mapping, companion selection, deterministic coverage ledger.
- `HUNTING.md` — Phase 2 coverage-led hunter waves, hunter prompt contract, coverage-critic loop.
- `VALIDATION-AND-REPORTING.md` — Phases 3–6 candidate validation, findings output, verification, reports.
- `AI-AND-LLM.md` — companion: prompt/context/memory/tool/MCP/output attack classes.
- `WEB-PROTOCOL-AND-AUTH.md` — companion: HTTP framing/cache, sessions, federated identity, API keys/mTLS.
- `CLIENT-SIDE.md` — companion: DOM, messaging, service-worker/storage, XS-leaks, UI-redress classes.
- `CLOUD-AND-DEPLOYMENT.md` — companion: IAM, ingress, containers, config/secrets, storage/event/edge classes.
- `DATA-ISOLATION-AND-LIFECYCLE.md` — companion: tenant isolation, derived data, export/backup/migration/deletion classes.
- `DESKTOP-MOBILE-AND-LOCAL-IPC.md` — companion: deep-link, webview bridge, local IPC, privileged helper classes.
- `MEMORY-SAFETY-AND-BINARY.md` — companion: bounds/integer, lifetime/concurrency, FFI/ABI, loader, kernel classes.
- `PROTOCOLS-RPC-AND-MESSAGING.md` — companion: framing/schema, RPC auth, broker isolation, replay/ordering classes.
- `RESOURCE-EXHAUSTION-AND-AVAILABILITY.md` — companion: amplification, accumulation, quota/scheduling, recovery classes.
- `SUPPLY-CHAIN-AND-RELEASE.md` — companion: dependencies, CI/automation, release/update classes.
- `report-schema.json` — JSON Schema contract for `findings.json` (`confirmed`/`needs_validation`/`rejected`).
- `validate-findings.cjs` — dependency-free validator for `findings.json` against `report-schema.json`.
- `validate-findings.test.cjs` — tests for the findings validator (`node --test`).
- `validate-coverage-ledger.cjs` — validator for `coverage-ledger.json` IDs, states, evidence ownership.
- `validate-coverage-ledger.test.cjs` — tests for the ledger validator (`node --test`).
- `validate-run-metadata.cjs` — validator for `run-metadata.json` setup facts (see `references/full-audit-setup.md`).
- `LICENSE` — license for this skill directory.
- `references/full-audit-setup.md` — full-audit setup, write isolation, planning, profiles, budget (full-audit mode only).
- `references/FILEMAP.md` — this file.
