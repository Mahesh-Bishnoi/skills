# Hardening Patterns

Concrete implementations of the controls in `SKILL.md`. Pick the section you need; each is self-contained. Examples show Python and TypeScript — apply the same invariant in any stack.

## Injection

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

```python
import bcrypt
# Store
pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
# Verify (constant-time compare inside checkpw)
assert bcrypt.checkpw(password.encode(), pw_hash)
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

```python
import ipaddress, socket
from urllib.parse import urlparse

def assert_safe_fetch(url: str, allow_hosts: set[str]) -> str:
    u = urlparse(url)
    assert u.scheme in ("https",), "scheme not allowed"
    assert u.hostname in allow_hosts, "host not allowlisted"
    infos = socket.getaddrinfo(u.hostname, u.port or 443, type=socket.SOCK_STREAM)
    for info in infos:  # check ALL records, v4 and v6
        ip = ipaddress.ip_address(info[4][0])
        assert not (ip.is_private or ip.is_loopback or ip.is_link_local
                    or ip.is_reserved or ip.is_multicast), f"blocked address {ip}"
    assert_no_redirect_policy(url)  # forbid redirects or re-check each hop
    return url
```

Notes: `169.254.169.254` (cloud metadata) is link-local and must be rejected. DNS-rebinding leaves a TOCTOU gap between check and fetch — for high-risk surfaces pin the validated IP (connect to it with SNI/host header preserved) or route through a filtering egress proxy.

## Destructive Operations on Derived Paths

```python
from pathlib import Path

def safe_delete(root: Path, claimed: str, ownership_marker: str) -> None:
    target = (root / claimed).resolve()  # resolve symlinks first
    assert target.is_relative_to(root.resolve()), "outside allowlisted root"
    assert len(target.relative_to(root.resolve()).parts) >= 1 + 1, "must be below root"
    marker = (target / ".owner").read_text()  # ownership evidence, read pre-op
    assert marker.strip() == ownership_marker, "ownership not proven"
    assert target.is_dir() and not target.is_symlink()
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

Before every commit: `git diff --cached --name-only` plus `git diff --cached -S 'sk-' -S 'AKIA' -- .` (extend with your secret prefixes). **A secret that reaches a remote is compromised: rotate it first, then purge history** (`git filter-repo` / provider revocation), never the reverse.

## Dependency Audit Triage

1. `npm audit --omit=dev` / `pip-audit` / `cargo audit` / `govulncheck` against the **committed lockfile**, before every release.
2. Triage critical/high by reachability: is the vulnerable function on your runtime, build, test, or deploy path? Unreachable dev-only findings are lower priority but still recorded.
3. Fix by minimal safe upgrade; read the changelog; test. Never `--force` across declared ranges automatically.
4. Document deferrals: finding ID, why unreachable or why delayed, review date.

New-package review (audits miss fresh malice): check ownership, maintenance cadence, release age, provenance/signatures (`npm audit signatures` where supported), and lockfile diff scope. Inspect pending install scripts before approval (`npm pkg get scripts` on the candidate, `packageManager` pinning, `onlyBuiltDependencies` / `neverBuiltDependencies` policy committed).

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
