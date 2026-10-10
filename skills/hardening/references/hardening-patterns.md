# Hardening Patterns

Concrete implementations of the controls in `SKILL.md`. Pick the section you need; each is self-contained. Examples show Python and TypeScript — apply the same invariant in any stack.

Category IDs follow OWASP Top 10:2025: A01 Broken Access Control (now includes SSRF, ex-A10:2021), A02 Security Misconfiguration (ex-A05:2021), A03 Software Supply Chain Failures (expands ex-A06:2021 Vulnerable and Outdated Components), A04 Cryptographic Failures (ex-A02:2021), A05 Injection incl. XSS (ex-A03:2021), A06 Insecure Design (ex-A04:2021), A07 Authentication Failures (ex-A07:2021 Identification and Authentication Failures), A08 Software or Data Integrity Failures (unchanged), A09 Security Logging and Alerting Failures (ex-Monitoring), A10 Mishandling of Exceptional Conditions (new).

## Injection

A05:2025 (ex-A03:2021).

Parameterized queries only. Never interpolate input into query or command strings.

```python
# BAD
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# GOOD
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

```typescript
// BAD
await db.query(`SELECT * FROM users WHERE email = '${email}'`);

// GOOD
await db.query('SELECT * FROM users WHERE email = $1', [email]);
```

Shell: prefer arg arrays over string commands.

```python
# BAD
os.system(f"convert {user_path} out.png")

# GOOD
subprocess.run(["convert", user_path, "out.png"], shell=False, check=True)
```

```typescript
// BAD
import { execSync } from 'child_process';
execSync('convert ' + userPath + ' out.png');

// GOOD
import { execFileSync } from 'child_process';
execFileSync('convert', [userPath, 'out.png']);
```

NoSQL, LDAP, and template languages need the same treatment: use the driver's parameterized / escaped builder, never string concatenation.

## Cross-Site Scripting (XSS)

Part of A05:2025 Injection.

Rely on framework auto-escaping; never bypass it for user or LLM-produced data.

```typescript
// BAD (React)
<div dangerouslySetInnerHTML={{ __html: comment }} />

// GOOD
<div>{comment}</div>
// Raw HTML unavoidable? Sanitize with an allowlist sanitizer first.
import sanitizeHtml from 'sanitize-html';
const clean = sanitizeHtml(comment, { allowedTags: ['b', 'i', 'code'] });
```

Python templates (Jinja2) keep autoescaping on; Go `html/template` over `text/template` for HTML. Encode for the sink: HTML body, attribute, JS string, URL, and CSV each need their own encoder.

## Broken Access Control

A01:2025 (unchanged at #1; now also covers SSRF, ex-A10:2021).

Check ownership or permission on the specific resource on every request. Authentication alone is not enough (IDOR).

```python
# BAD: any authenticated user can read any order
order = db.get_order(order_id)
return order

# GOOD: bind resource to principal, fail closed
order = db.get_order(order_id)
if order.owner_id != current_user.id and not current_user.is_admin:
    raise Forbidden("order not found")
return order
```

Deny by default; allowlist actions per role; log authorization failures without leaking which IDs exist.

## Broken Authentication

A07:2025 Authentication Failures (ex-A07:2021 Identification and Authentication Failures).

```python
import bcrypt
# Store
pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
# Verify (constant-time compare inside checkpw). Explicit raise:
# `assert` is dropped under `python -O` and must never enforce security checks.
if not bcrypt.checkpw(password.encode(), pw_hash):
    raise ValueError("invalid credentials")
```

Session cookies (Express example):

```typescript
app.use(session({
  secret: process.env.SESSION_SECRET!, // env, never code
  cookie: { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 30 * 60 * 1000 },
}));
```

Enforce strict rate limits and lockout on login; never enumerate users ("invalid credentials" for both bad name and bad password); rotate session IDs after login.

## Security Misconfiguration

A02:2025 (ex-A05:2021).

Apply framework security headers on every HTTP response:

```typescript
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: { directives: { defaultSrc: ["'self'"] } },
  hsts: { maxAge: 31536000, includeSubDomains: true },
}));
```

CORS: explicit origin list from configuration; never `*` with credentials.

```typescript
import cors from 'cors';
app.use(cors({ origin: config.allowedOrigins, credentials: true }));
```

Disable debug endpoints, directory listings, and verbose banners in production. Daemons/CLI equivalents: restrictive umask (`027`), socket modes (`0700` dirs, `0600` secrets), no debug flags by default.

## Sensitive Data Exposure

Under A04:2025 Cryptographic Failures (ex-A02:2021).

Strip sensitive fields before any response — HTTP, CLI `--json`, logs, or error payloads:

```typescript
// BAD
res.json(user);

// GOOD
const { passwordHash, resetToken, ...safe } = user;
res.json(safe);
```

TLS everywhere; verify certificates; encrypt sensitive data at rest with a managed key (KMS / secret store), not a hardcoded key. Error bodies are generic (`"request failed"`); details go to server logs with a correlation ID.

## Schema Validation at Boundaries

Parse, don't validate: convert untrusted input into a typed value once at the boundary; inner code trusts the type.

```python
from pydantic import BaseModel, Field

class CreateTask(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    priority: str = Field(pattern="^(low|med|high)$")

task = CreateTask.model_validate(raw_json)  # raises 422-style error
```

```typescript
import { z } from 'zod';
const CreateTask = z.object({
  title: z.string().min(1).max(200),
  priority: z.enum(['low', 'med', 'high']),
});
const task = CreateTask.parse(rawJson); // throws on bad input
```

Cap sizes, depths, array lengths, pagination (`max 100/page`), and body limits at the same layer. CLI equivalents: required/optional flags with choices, `--max-rows`, stdin size caps.

## File Upload Safety

```python
ALLOWED = {"image/png", "image/jpeg"}
MAX_BYTES = 5 * 1024 * 1024

if content_type not in ALLOWED:
    raise Rejected("unsupported type")
if len(blob) > MAX_BYTES:
    raise Rejected("too large")
if magic_bytes(blob) not in ALLOWED:  # extension proves nothing
    raise Rejected("content mismatch")
store(blob, random_filename())  # never the user-supplied name
```

Serve uploads from a separate origin/path with `Content-Disposition: attachment` for active content; never execute uploaded files; sandbox archive extraction (zip-slip: resolve each entry under the destination root first).

## Server-Side Request Forgery (SSRF)

Covered by A01:2025 Broken Access Control (ex-A10:2021).

```python
import ipaddress, socket
from urllib.parse import urlparse

def check_safe_fetch(url: str, allow_hosts: set[str]) -> str:
    u = urlparse(url)
    if u.scheme not in ("https",):
        raise ValueError("scheme not allowed")
    if u.hostname not in allow_hosts:
        raise ValueError("host not allowlisted")
    infos = socket.getaddrinfo(u.hostname, u.port or 443, type=socket.SOCK_STREAM)
    for info in infos:  # check ALL records, v4 and v6
        ip = ipaddress.ip_address(info[4][0])
        if (ip.is_private or ip.is_loopback or ip.is_link_local
                or ip.is_reserved or ip.is_multicast):
            raise ValueError(f"blocked address {ip}")
    assert_no_redirect_policy(url)  # forbid redirects or re-check each hop
    return url
```

Notes: `169.254.169.254` (cloud metadata) is link-local and must be rejected. DNS-rebinding leaves a TOCTOU gap between check and fetch — for high-risk surfaces pin the validated IP (connect to it with SNI/host header preserved) or route through a filtering egress proxy.

## Destructive Operations on Derived Paths

```python
from pathlib import Path
import shutil

def safe_delete(root: Path, claimed: str, ownership_marker: str) -> None:
    # Explicit raises throughout: `assert` is dropped under `python -O`.
    root_r = root.resolve()  # resolve once; the allowlisted root
    raw = root_r / claimed
    if raw.is_symlink():
        # Checked on the UNRESOLVED path. After resolve() below the link is
        # gone, so testing target.is_symlink() there would be dead code.
        raise ValueError("symlink path not allowed")
    target = raw.resolve()  # resolve symlinks first
    if not target.is_relative_to(root_r):
        raise ValueError("outside allowlisted root")
    if len(target.relative_to(root_r).parts) < 1:
        raise ValueError("must be at least one level below allowlisted root")
    marker = (target / ".owner").read_text()  # ownership evidence, read pre-op
    if marker.strip() != ownership_marker:
        raise PermissionError("ownership not proven")
    if not target.is_dir() or target.is_symlink():
        raise ValueError("not a real directory")
    shutil.rmtree(target)
```

On refusal, log the rejected target and stop. Never fall back to a broader default path (e.g. deleting the root when the subpath check fails).

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';

app.use('/api/', rateLimit({ windowMs: 60_000, max: 100, store: new RedisStore(client) }));
app.use('/api/login', rateLimit({ windowMs: 15 * 60_000, max: 10, store: new RedisStore(client) }));
```

In-memory counters are only correct for a single process. Past one instance or on serverless, back the limiter with a shared store (Redis or equivalent). Also cap pagination, batch sizes, retry counts, queue depth, and upstream timeouts.

## Secrets Management

```bash
# .env.example (committed, placeholders only)
DATABASE_URL=postgres://user:pass@localhost:5432/app
SESSION_SECRET=change-me

# Real .env, *.pem, *.key (gitignored, never committed)
```

```gitignore
.env
.env.*
*.pem
*.key
```

Before every commit: `git diff --cached --name-only` plus one pattern per command — `git diff --cached -S 'sk-' -- .` and separately `git diff --cached -S 'AKIA' -- .` (git keeps only the last `-S`, so combining them silently drops all but one). Extend with your secret prefixes. **A secret that reaches a remote is compromised: rotate it first, then purge history** (`git filter-repo` / provider revocation), never the reverse.

## Dependency Audit Triage

A03:2025 Software Supply Chain Failures (expands ex-A06:2021 Vulnerable and Outdated Components).

1. `npm audit` (all workspaces — never `--omit=dev`, which hides build/test dependency problems) / `pip-audit` / `cargo audit` / `govulncheck` against the **committed lockfile**, before every release.
2. Triage critical/high by reachability: is the vulnerable function on your runtime, build, test, or deploy path? Reachable findings fix first regardless of path; unreachable ones are still recorded.
3. Fix by minimal safe upgrade; read the changelog; test. Never `--force` across declared ranges automatically.
4. Document deferrals: finding ID, why unreachable or why delayed, review date.

New-package review (audits miss fresh malice): check ownership, maintenance cadence, release age, provenance/signatures (`npm audit signatures` where supported), and lockfile diff scope. Inspect pending install scripts before approval (`npm view <pkg> scripts dist.tarball` on the candidate about to install — `npm pkg get` only reads the local workspace's `package.json`, so it cannot vet a package you have not installed — plus `packageManager` pinning, `onlyBuiltDependencies` / `neverBuiltDependencies` policy committed).

## Data Classification

| Class | Examples | Handling |
|---|---|---|
| Non-personal | Aggregated counts, feature flags | Standard controls |
| PII | Name, email, IP, device ID | Minimized, access-logged, TTL set, deletable |
| Sensitive | Passwords, health, financial, precise location | Encrypted, narrowest access, shortest TTL, DPA-gated sharing |

Keep PII out of logs, metrics labels, error payloads, and analytics events. Deletion must cover primary store, backups, caches, search indexes, and analytics copies — test the full path, not just the row delete.

## LLM Output Handling

```python
# BAD: model output straight into a sink
cursor.execute(f"SELECT * FROM docs WHERE title = '{model_text}'")
render(f"<div>{model_text}</div>")

# GOOD: parse defensively, validate, encode
data = ReviewOutput.model_validate_json(model_text)  # schema first
cursor.execute("SELECT * FROM docs WHERE title = %s", (data.title,))
render("<div>{{ text }}</div>", text=data.title)  # auto-escaped
```

Scope tool permissions per call; validate every tool argument against a schema; require explicit user confirmation for destructive, outbound, or money-moving tool calls; cap tokens, request rate, recursion/delegation depth; partition RAG embeddings and retrieval per tenant; validate and quarantine documents before indexing.
