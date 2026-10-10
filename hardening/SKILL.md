---
name: hardening
description: Hardens code against vulnerabilities while building. Use when handling user input, auth, sessions, secrets, uploads, external APIs, server-side fetches, dependencies, personal data, or LLM output. Use for OWASP safety, supply-chain triage, and privacy minimization.
---

# Hardening

Build secure by default. Treat every external input as hostile, every secret as sacred, and every authorization check as mandatory. Security is a constraint on every line that touches user data, trust boundaries, or external systems — not a phase at the end.

Source: inspired by `addyosmani/agent-skills` (`security-and-hardening`, MIT). Rewritten here as original, language-agnostic guidance for web, API, CLI, library, and daemon targets.

## When to Use

- Building anything that accepts untrusted data (HTTP, CLI args, env vars, config files, stdin, IPC, queues, webhooks, LLM output)
- Implementing authentication, authorization, or session handling
- Storing or transmitting secrets, credentials, PII, or payment data
- Calling external APIs or fetching user-influenced URLs
- Adding file uploads, import-from-URL, webhooks, or callbacks
- Adding dependencies or changing install / build behavior
- Handling personal data subject to GDPR, CCPA, or similar

**NOT for:**

- Deep audit of an existing codebase — ask the user to invoke `@security-audit` (this skill builds controls in; that skill finds missing ones)
- Diagnosing an active bug or exploit — use `debug` (this skill prevents the next one)
- Telemetry design beyond redaction — see `observability` (this skill covers only: no secrets/PII in logs)

## Process: Threat Model First

Controls without a threat model are guesses. Spend five minutes thinking like an attacker before writing code:

1. **Map the trust boundaries.** Where does untrusted data enter? HTTP requests, form fields, CLI argv, environment variables, config files, filenames, stdin, file uploads, webhooks, third-party APIs, queue messages, IPC, and **LLM output**. Trust follows who *wrote* a value, not which channel delivered it. Another process's command line or a path in a job payload is as attacker-controlled as a form field.
2. **Name the assets.** What is worth stealing or breaking? Credentials, PII, payment data, admin actions, money movement, compute, reputation.
3. **Run STRIDE over each boundary** — a quick lens, not a ceremony:

| Threat | Ask | Typical mitigation |
|---|---|---|
| **S**poofing | Can someone impersonate a user/service? | Authentication, signature verification |
| **T**ampering | Can data be altered in transit or at rest? | Integrity checks, parameterized queries, TLS |
| **R**epudiation | Can an action be denied later? | Audit logging of security events |
| **I**nformation disclosure | Can data leak? | Encryption, field allowlists, generic errors |
| **D**enial of service | Can it be overwhelmed? | Rate limits, size caps, timeouts |
| **E**levation of privilege | Can a user gain rights they shouldn't? | Authorization checks, least privilege |

4. **Write abuse cases next to use cases.** For each feature ask "how would I misuse this?" — then make that your first test.

If you cannot name the trust boundaries, you are not ready to secure the feature. That is OWASP **A06:2025 Insecure Design** (ex-A04:2021) — most breaches begin in design, not code.

## The Three-Tier Boundary System

### Always Do (No Exceptions)

- **Validate all external input** at the system boundary (API routes, CLI parsers, env/config loaders, IPC handlers)
- **Parameterize all queries and commands** — never concatenate input into SQL, NoSQL, LDAP, or shell strings
- **Encode output** for its sink (HTML auto-escaping, shell quoting, CSV escaping) — never bypass it for user data
- **Use TLS/HTTPS** for all network communication; verify certificates
- **Hash passwords** with argon2, bcrypt (≥12 rounds), or scrypt — never plaintext or fast hashes
- **Set security headers** on HTTP responses (CSP, HSTS, X-Frame-Options, X-Content-Type-Options) or the framework equivalent
- **Use httpOnly, secure, sameSite cookies** for browser sessions
- **Apply least privilege** — drop daemon privileges, restrict file/socket permissions, scope tokens and tool permissions
- **Run the package manager native audit** against the committed lockfile before every release
- **Return generic errors** to callers; internals go to server logs only

### Ask First (Requires Human Approval)

- Adding or changing authentication flows, session handling, or password-reset logic
- Storing new categories of sensitive data (PII, payment info, health data)
- Adding external service integrations or sharing PII with vendors
- Changing CORS, CSP, or cookie security attributes
- Adding file upload, import-from-URL, webhook, or callback handlers
- Changing rate limits, throttling, or resource caps
- Granting elevated permissions, roles, or admin actions
- Adding dependencies with install scripts or broad postinstall behavior

### Never Do

- **Never commit secrets** to version control (API keys, passwords, tokens, private keys)
- **Never log sensitive data** (passwords, tokens, full card numbers, unredacted PII)
- **Never trust client-side validation** as a security boundary
- **Never build queries or shell commands** by string interpolation of input
- **Never use `eval()` or `innerHTML`** (or equivalent) with user-provided or LLM-produced data
- **Never store auth tokens** in client-accessible storage (localStorage) — use httpOnly cookies or OS keychains
- **Never expose stack traces** or internal error details to users
- **Never use CORS `*` with credentials** or reflect arbitrary Origin headers
- **Never fetch user-influenced URLs** without allowlist + private-address rejection (SSRF)
- **Never run shell with user input** via `shell=True`, `execSync(cmd + input)`, or equivalent

## Hardening Controls

Summaries below; concrete snippets live in [references/hardening-patterns.md](references/hardening-patterns.md). Open the section you need when you reach that code, not before.

### Injection, XSS, and access control

- Parameterize every query. Never build SQL, NoSQL, LDAP, or shell commands from input strings. For shells, prefer `execFile` / arg arrays over string commands.
- Encode output through the framework's auto-escaping. If raw HTML is unavoidable, sanitize with an allowlist sanitizer first.
- Check **authorization on every request**, not just authentication: the caller must own, or be permitted on, the specific resource (A01:2025, IDOR). Fail closed.

Patterns: [Injection](references/hardening-patterns.md#injection), [XSS](references/hardening-patterns.md#cross-site-scripting-xss), [Access control](references/hardening-patterns.md#broken-access-control).

### Authentication and sessions

- Hash with argon2/bcrypt/scrypt. Session secrets come from the environment, never from code. Enforce lockout or strict rate limits on login.
- Browser sessions: `httpOnly`, `secure`, `sameSite: 'lax'` or `'strict'`, bounded `maxAge`. Non-browser clients (CLI/daemon): prefer OS keychain / token files with `0600` over env-var persistence.

Pattern: [Authentication](references/hardening-patterns.md#broken-authentication).

### Headers, CORS, and responses

- Security headers on every HTTP response; CSP starts from `default-src 'self'` and tightens. CORS restricted to an explicit origin list from configuration.
- Strip sensitive fields (`passwordHash`, reset tokens, internal IDs) before any response — including CLI `--json` output and error payloads.

Patterns: [Misconfiguration](references/hardening-patterns.md#security-misconfiguration), [Sensitive data exposure](references/hardening-patterns.md#sensitive-data-exposure).

### Input validation and uploads

- Validate at the boundary with a schema: allowlisted shape, lengths, enums, formats. Reject with 422 (or CLI usage error) and structured details; inner code uses only the parsed, typed value. Cap sizes, depths, and counts everywhere (body, CSV rows, JSON depth, archive entries).
- Uploads: allowlist MIME types, cap size, verify content (magic bytes) when it matters. Extension proves nothing. Scan or sandbox processing of archives and documents.

Patterns: [Schema validation](references/hardening-patterns.md#schema-validation-at-boundaries), [File upload](references/hardening-patterns.md#file-upload-safety).

### Server-side fetches (SSRF)

Any URL the user influences — webhooks, import-from-URL, image proxies, link previews — can be aimed at internal services. Allowlist scheme and host, resolve **all** DNS records and reject private/reserved addresses (loopback, link-local `169.254.169.254`, RFC 1918, unique-local, for IPv4 and IPv6), and forbid redirects. DNS-rebinding leaves a TOCTOU gap: for high-risk surfaces pin the resolved IP or put a filtering egress proxy in front.

Pattern: [SSRF](references/hardening-patterns.md#server-side-request-forgery-ssrf).

### Destructive operations on derived paths

A delete, move, or overwrite is only as safe as the value naming its target. A shape check proves well-formedness, not authorization. Before the call require all three: the resolved target (symlinks resolved) sits under an **allowlisted root**; it is at least one level **below** that root; and it carries **ownership evidence read before the operation**. On refusal, log the rejected target and stop; never fall back to a broader default path.

Pattern: [Destructive paths](references/hardening-patterns.md#destructive-operations-on-derived-paths).

### Rate limiting and resource caps

Limit APIs generally and auth endpoints strictly (e.g. ~10 attempts per 15 minutes). Cap request size, pagination, queue depth, retry counts, and timeouts. Past one process, in-memory counters become `max × instances` or never fire on serverless: back the limiter with a shared store.

Pattern: [Rate limiting](references/hardening-patterns.md#rate-limiting).

### Secrets

Secrets come from the environment or a secret store. Commit `.env.example` with placeholders; gitignore real `.env*` and key material; grep the staged diff before committing. **A secret that reaches a remote is compromised the moment it lands: rotate first, then purge history.**

Pattern: [Secrets management](references/hardening-patterns.md#secrets-management).

### Dependencies and supply chain

1. **Find the installation boundary and manager.** Use the workspace root owning the lockfile. Corroborate `packageManager` (when present), lockfile, and CI; stop on disagreement or competing lockfiles. Pin the manager version.
2. **Block dependency scripts before first execution.** Bootstrap with scripts disabled or a documented fail-closed policy, inspect pending script source, approve only the minimum, commit the policy, then verify with a clean frozen/immutable install. Never blanket-approve.
3. **Run the native audit against the committed lockfile before every release.** Triage critical/high by **reachability** (runtime, build, test, deploy paths) and fix availability. Never auto-apply forced remediation across declared ranges; preview, read changelogs, test each upgrade. Document every deferral with reason and review date.
4. **Audits only match known advisories.** They do not catch newly malicious or typosquatted packages. Review new dependencies and lockfile diffs together: ownership, maintenance, release age, provenance, transitive graph.

Pattern: [Dependency audit triage](references/hardening-patterns.md#dependency-audit-triage).

### Personal data and privacy

Hardening asks "can an attacker read it?" Privacy asks "should *we* hold it at all, and for how long?" Data never collected needs no protection, breach notice, or deletion path.

- **Classify fields as you add them** (non-personal, PII, sensitive) and handle each class accordingly.
- **Collect only against a stated purpose.** "Might be useful later" is latent breach scope. Keep PII out of telemetry.
- **Set retention up front, then actually delete** — including backups, caches, search indexes, and analytics copies.
- **Support data-subject rights** your jurisdiction requires (export, correct, delete). Design the schema so a user's data is findable and erasable.
- **Consent gates collection and third-party sharing**, and is auditable. Sending PII to analytics/ad/LLM vendors is sharing; the vendor needs a data-processing agreement.

Pattern: [Data classification](references/hardening-patterns.md#data-classification).

### AI / LLM features

Calling an LLM — chatbots, summarizers, agents, RAG — adds a new attack surface:

- **Model output is untrusted input.** Never into `eval`, SQL, shell, `innerHTML`, or file paths; parse defensively, validate against a schema, then encode.
- **Prompts can be hijacked.** Untrusted text in context can carry instructions. The system prompt is not a security boundary; enforce permissions in code.
- **Keep secrets, other tenants' data, and the full system prompt out of the context window**; scope tool permissions, validate every tool argument, confirm destructive actions; cap tokens, request rate, and recursion depth; partition RAG embeddings per tenant and validate documents before indexing.

Pattern: [LLM output handling](references/hardening-patterns.md#llm-output-handling).

## Non-Web Targets

- **CLI tools:** parse argv with a library, never `eval` args; treat env vars, config files, `$PATH`, and cwd as untrusted; quote paths; require explicit `--force` for destructive targets plus the derived-path checks above.
- **Daemons/services:** drop privileges after bind, set restrictive socket/file modes, enforce timeouts and max connections, never trust peer-supplied filenames without the derived-path checks.
- **Libraries/SDKs:** do no hidden I/O; take credentials and endpoints from the caller, never hardcoded defaults; fail closed on ambiguous policy; document the security obligations the caller inherits.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Internal tool, security doesn't matter" | Internal tools get compromised. Attackers target the weakest link. |
| "We'll add security later" | Retrofitting is 10x harder than building it in. Add it now. |
| "No one would exploit this" | Automated scanners will find it. Obscurity is not security. |
| "The framework handles it" | Frameworks provide tools, not guarantees. You must use them correctly. |
| "It's just a prototype" | Prototypes become production. Secure habits from day one. |
| "Threat modeling is overkill" | Five minutes of "how would I attack this?" prevents design flaws no control patches later. |
| "It's just LLM output, only text" | That text can be SQL, a script tag, or a shell command. Treat it as untrusted input. |
| "Audit passed, dependency is safe" | Audits match known advisories. They miss newly malicious packages and unreviewed install scripts. |
| "Collect it now, might need it later" | Data not held cannot be breached or subpoenaed. "Might need" is breach scope, not purpose. |
| "Deletion requests handled manually" | Manual erasure misses backups and caches. Design the schema for findable, erasable data. |

## Red Flags

- Input passed directly to queries, shell commands, or HTML rendering
- Delete/move/overwrite whose target comes from a payload, config, or argv, guarded only by a shape check
- Secrets in source or commit history
- Endpoints without authentication or authorization checks
- Missing CORS config or wildcard origins with credentials
- No rate limiting on auth, or in-memory limiter with multiple instances
- Stack traces or internal errors exposed to callers
- Dependencies with reachable critical vulns, competing lockfiles, non-reproducible installs, blanket-approved scripts
- Server fetches user-supplied URLs without an allowlist (SSRF)
- LLM output passed into queries, DOM, shell, or `eval`
- Secrets, PII, or full system prompt in LLM context
- Personal data with no purpose, retention limit, or deletion path
- PII sent to vendors with no consent or processing agreement
- "Delete my account" that flips a flag while data lingers in stores and backups

## Verification

After implementing security-relevant code, walk [references/security-checklist.md](references/security-checklist.md):

- [ ] Native audit has no unmitigated reachable critical/high findings; CI preserves the lockfile and blocks unreviewed scripts
- [ ] No secrets in source or history; staged diff grepped
- [ ] All external input validated at boundaries; inner code uses only parsed types
- [ ] Destructive filesystem ops verify allowlisted root, minimum depth, and ownership
- [ ] Auth and authorization checked on every protected path
- [ ] Security headers present (HTTP) or restrictive file/socket modes set (daemon/CLI)
- [ ] Error responses generic; internals only in server logs
- [ ] Rate limiting active on auth, backed by shared store when scaled
- [ ] Server-side URL fetches allowlisted (no SSRF)
- [ ] LLM output validated and encoded before use (if AI features present)
- [ ] Personal data classified, minimized, retention-limited; export/delete works end-to-end
