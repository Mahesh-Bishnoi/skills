# SkillSpector setup

Installs the SkillSpector scanner CLI so `@skill-inspector` can gate third-party skill installs. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- SkillSpector security scanner for AI agent skills (Apache-2.0). Docs at https://docs.nvidia.com/skills/scanning-agent-skills
- Install via `uv tool install git+https://github.com/NVIDIA/skillspector.git` (add the `[mcp]` extra for the MCP server). Docker image builds locally from the upstream Dockerfile.
- OpenCode extension ships upstream as `.opencode/` (a `skillspector_scan` tool plus a `/skillspector` command wrapping the CLI).

Project `AGENTS.md` and existing codebase conventions override this file.

Out of scope (never set up here): hosted scanning services, API keys for other users, global credential storage, CI SARIF uploads. Those need accounts or shared secrets.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v python3; python3 --version 2>/dev/null || true
command -v uv; uv --version 2>/dev/null || true
command -v skillspector; skillspector --version 2>/dev/null || true
echo "SKILLSPECTOR_PROVIDER=${SKILLSPECTOR_PROVIDER:-<unset>}"
command -v opencode; opencode --version 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
```

Installed means:

- `skillspector` CLI present (`skillspector --version` prints a version).
- Provider configured: `SKILLSPECTOR_PROVIDER=opencode_cli` (preferred — reuses the user's OpenCode auth, no key) or another provider's credential env for non-interactive use.
- Library skill: `@skill-inspector` advertises via the Phase 0 project-local `skills` entry (no copy needed).

If CLI + provider are ready and the user only wants the scan gate, skip to Step 4. If MCP or the OpenCode command was requested and is also present, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Install the skillspector CLI (per-user via uv) [yes]?` Required for any scanning. Python 3.12+ needed.
2. `LLM provider: opencode_cli (your OpenCode subscription, no key) or another provider [opencode_cli]?` Static scans (`--no-llm`) are the default; LLM is explicit opt-in per scan since skill content leaves the host. Other providers (hosted keys, local Ollama, gateways) suit CI or machines without OpenCode auth.
3. `Also install the OpenCode /skillspector command (copies upstream .opencode tool + command) [no]?` Default-off; project-local copy only on opt-in.
4. `Include the MCP server [no]?` Default-off. Opt-in installs the `[mcp]` extra and registers the server.
5. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

Base CLI (per-user global by nature):

```sh
uv tool install git+https://github.com/NVIDIA/skillspector.git
skillspector --version
```

Configure the subscription-backed LLM path (shell session; never commit credentials — this provider needs none):

```sh
export SKILLSPECTOR_PROVIDER=opencode_cli
```

Alternative providers (only if Step 2.2 chose one; each needs its own credential env — present the exact exports and get a yes before writing anything persistent):

```sh
export SKILLSPECTOR_PROVIDER=nv_build
export NVIDIA_INFERENCE_KEY=nvapi-...
```

```sh
export SKILLSPECTOR_PROVIDER=ollama
export SKILLSPECTOR_MODEL=llama3.1:8b
```

Static scan check:

```sh
skillspector scan ./skills/skill-inspector --no-llm
```

LLM-backed check (only on explicit per-scan yes; spends subscription quota or provider budget):

```sh
skillspector scan ./skills/skill-inspector --format json --output /tmp/skillspector-check.json
```

Optional OpenCode command (only if Step 2.3 was yes) — copy the upstream extension into the project and point it at the binary:

```sh
cp -r /path/to/SkillSpector/.opencode/tools/skillspector_scan.* .opencode/tools/
cp -r /path/to/SkillSpector/.opencode/commands/skillspector.md .opencode/commands/
export SKILLSPECTOR_BIN="$(command -v skillspector)"
```

Then reload OpenCode; `/skillspector <target>` is auto-discovered. Static scans cap at ~120s, LLM scans at ~630s per upstream.

Optional MCP server (only if Step 2.4 was yes):

```sh
uv tool install --force 'skillspector[mcp] @ git+https://github.com/NVIDIA/skillspector.git'
skillspector mcp
```

The server exposes one tool: `scan_skill(target, use_llm, output_format)` returning `risk_score`, `severity`, `recommendation`, `safe_to_install`, `findings`, plus `llm_used` / `scan_mode`. Register with a local agent via:

```sh
claude mcp add skillspector -- skillspector mcp
```

Trust model: stdio for local agents. The HTTP transport (`skillspector mcp --transport http --host 127.0.0.1 --port 8000`) ships without authentication — bind loopback only, never expose it; it rejects local paths and accepts only credential-free `https://` targets. For private repos use stdio or the CLI.

Docker alternative (no Python on host):

```sh
docker build -t skillspector /path/to/SkillSpector
docker run --rm -v "$PWD:/scan" skillspector scan ./my-skill/ --no-llm
```

Baseline / false-positive suppression (per scanned skill, committed beside it):

```sh
skillspector baseline ./my-skill/ -o .skillspector-baseline.yaml
skillspector scan ./my-skill/ --baseline .skillspector-baseline.yaml
```

If a command fails, report the output verbatim and stop. Common causes: Python < 3.12, missing `uv`, no network for the git install, or `opencode` CLI not authenticated for `opencode_cli`.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `skillspector scan <target> --no-llm`, `@skill-inspector` for verdicts (`APPROVE` / `CAUTION` / `REJECT`), plus `/skillspector` or the `scan_skill` MCP tool only if those extras were installed.
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No skill reviews in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] CLI installed per-user; no credentials written to files
- [ ] `opencode_cli` preferred for interactive LLM scans; alternatives only on explicit choice
- [ ] OpenCode command and MCP left out unless explicitly opted in (default-off)
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed entry points and stopped without analysis
