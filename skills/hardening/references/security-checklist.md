# Security Checklist

Sign-off checklist for the `hardening` skill. Walk the sections relevant to the change; every box must hold before merging security-relevant code.

## Authentication & Sessions

- [ ] Passwords hashed with argon2, bcrypt (≥12), or scrypt; no plaintext or fast hashes
- [ ] Session secret from environment/secret store, never code
- [ ] Cookies `httpOnly`, `secure`, `sameSite lax/strict`, bounded `maxAge`; non-browser tokens in OS keychain or `0600` files
- [ ] Login rate-limited with lockout; generic "invalid credentials" (no user enumeration); session ID rotated after login

## Authorization

- [ ] Every protected path checks ownership/permission on the specific resource (no IDOR); fail closed
- [ ] Deny by default; roles allowlisted per action; auth failures logged without leaking ID existence

## Input & Output

- [ ] All external input (HTTP, argv, env, config, IPC, queues) validated at the boundary via schema; inner code uses parsed types only
- [ ] Queries/commands parameterized; no string-built SQL/NoSQL/LDAP/shell; `shell=False` / arg arrays
- [ ] Output encoded for its sink; no `eval` / `innerHTML` with user or LLM data (or allowlist-sanitized first)
- [ ] Sizes capped: body, arrays, JSON depth, pagination, CSV rows, archive entries, timeouts

## Data Protection & Privacy

- [ ] Sensitive fields stripped before responses, logs, and error payloads; generic caller-facing errors
- [ ] TLS everywhere with verification; sensitive data encrypted at rest with managed keys
- [ ] No secrets/PII in logs, metric labels, or telemetry; allowlisted fields only
- [ ] Personal data classified, purpose-stated, minimized; retention TTL set; export/correct/delete works end-to-end incl. backups/caches/indexes
- [ ] Third-party PII sharing consent-gated with a data-processing agreement

## Headers, CORS & Modes (HTTP Services)

- [ ] `helmet` or equivalent on every response; CSP from `default-src 'self'`, tightened not loosened; HSTS enabled
- [ ] CORS explicit origin list from config; never `*` with credentials; no arbitrary Origin reflection
- [ ] Debug endpoints, listings, and banners disabled in production

## Non-Web Modes (CLI / Daemon / Library)

- [ ] CLI: argv parsed via library; env/config/`$PATH`/cwd treated as untrusted; destructive ops need explicit `--force` + derived-path checks
- [ ] Daemon: privileges dropped after bind; restrictive socket/file modes; connection/timeout caps
- [ ] Library: no hidden I/O; credentials/endpoints from caller; fail closed on ambiguous policy; caller obligations documented

## Files, Fetches & Destructive Ops

- [ ] Uploads: MIME allowlist + size cap + magic-byte verification; random storage names; no execution; zip-slip guarded
- [ ] Server fetches: scheme/host allowlist; all DNS records checked; private/reserved rejected; redirects forbidden or re-checked
- [ ] Delete/move/overwrite: resolved target under allowlisted root, below root depth, ownership evidence pre-read; refusals logged, no broad fallback

## Dependencies & Supply Chain

- [ ] Single installation boundary; lockfile, `packageManager` pin, and CI agree; no competing lockfiles
- [ ] Install scripts blocked by default; pending scripts inspected; minimum approved and policy committed; clean frozen install verified
- [ ] Native audit clean of reachable critical/high or deferrals documented with reason + review date; no forced cross-range fixes
- [ ] New packages reviewed (ownership, maintenance, age, provenance, transitive graph); signatures verified where supported

## AI / LLM (If Present)

- [ ] Model output validated against schema and encoded before any sink (query, DOM, shell, file path)
- [ ] System prompt not treated as a boundary; permissions enforced in code; tool args validated; destructive/outbound calls user-confirmed
- [ ] Secrets, other tenants' data, and full system prompt kept out of context; RAG partitioned per tenant; docs validated before indexing
- [ ] Token, rate, and recursion/depth caps set

## Error Handling & Logging

- [ ] Caller-facing errors generic with correlation ID; stack traces and internals server-side only
- [ ] Security events logged (auth failures, authz denials, validation rejections, destructive-op refusals) without sensitive values

## OWASP Quick Reference

| OWASP (Web Top 10, 2021) | Covered By |
|---|---|
| A01 Broken Access Control | Authorization per resource, fail closed |
| A02 Cryptographic Failures | TLS, managed encryption, password hashing, no secret logging |
| A03 Injection | Parameterization, encoding, schema validation, no `eval` |
| A04 Insecure Design | Threat model first, abuse cases, STRIDE |
| A05 Misconfiguration | Headers, CORS, no debug in prod, restrictive modes |
| A06 Vulnerable Components | Lockfile audit, script gate, new-package review |
| A07 Auth Failures | Hashing, sessions, lockout, generic errors |
| A08 Data/Software Integrity | Provenance/signatures, frozen installs, no unreviewed scripts |
| A09 Logging Failures | Security-event logging with redaction + correlation IDs |
| A10 SSRF | Fetch allowlist, private-address rejection, no open redirects |

LLM features additionally map to the OWASP Top 10 for LLM Applications (2025): prompt injection (LLM01), data leakage (LLM02/07), tool permissions (LLM06), output handling (LLM05), RAG isolation (LLM08), resource caps (LLM10).
