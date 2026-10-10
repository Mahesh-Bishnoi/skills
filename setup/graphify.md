# Graphify setup

Bootstraps the free open-source self-contained parts of Graphify, then gets out of the way. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- `graphifyy` (two y's) on PyPI, command is `graphify`. Docs at https://docs.graphify.com/quickstart and https://docs.graphify.com/installation
- Local skill registration via `graphify install --platform opencode`. Local stdio MCP via `graphifyy[mcp]` extra (`graphify-mcp` reading local `graphify-out/graph.json`).

Project `AGENTS.md` and existing codebase conventions override this file.

Out of scope (never set up here): Graphify Cloud (Wiki, reviews, verification, Learning, memory), hosted MCP at `https://api.graphify.com/mcp` (VS Code, JetBrains, Vercel, OpenClaw-cloud, ChatGPT plugin), docs-search MCP, shared-http server, `[ollama]` semantic backend, PR commands contacting GitHub. Those need accounts, network exposure, or model backends.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v python3; python3 --version 2>/dev/null || true
command -v uv; uv --version 2>/dev/null || true
command -v pipx; pipx --version 2>/dev/null || true
command -v graphify; graphify --version 2>/dev/null || true
command -v graphify-mcp 2>/dev/null || true
ls graphify-out/graph.json 2>/dev/null || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
ls .claude/skills 2>/dev/null || true
```

Installed means:

- `graphify` CLI present (`graphify --version` prints a version).
- Local skill: installer output for `--platform opencode` present (check the paths above for a graphify entry — `.claude/skills` counts as a project compatibility source — or re-run install to confirm).
- Local MCP (optional): `graphify-mcp` on PATH.

If CLI + skill are present at the wanted scope and the user declined MCP, skip to Step 4. If MCP was requested and `graphify-mcp` is also present, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local with --project or global (personal) [project-local]?` Project-local commits the registration with the repo for team/CI — read the installer's file list before committing. Global registers the skill for the user only (advertises everywhere — opt-in). `uv tool install` / `pipx install` are always per-user global; only `graphify install --platform opencode --project` (and the MCP target file) honor scope.
2. `Include local stdio MCP server [no]?` Default-off. Opt-in installs the `mcp` extra and wires `graphify-mcp` to the repo's absolute `graphify-out/graph.json` path. GUI clients need the absolute path since their cwd differs from the terminal.
3. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

Base (code-only, fully offline, no account/key), project-local (default):

```sh
uv tool install graphifyy
graphify install --platform opencode --project
```

Review the files it writes before committing.

Global opt-in variant (only if Step 2.1 was global): drop `--project` from the second command.

Alternative installer if `uv` is unavailable:

```sh
pipx install graphifyy
```

Optional MCP extra (only if Step 2.2 was yes):

```sh
uv tool install "graphifyy[mcp]"
```

If uv reports an existing installation without the extra, use:

```sh
uv tool install --reinstall "graphifyy[mcp]"
```

Then configure the OpenCode MCP entry with the repo's absolute graph path (adjust the path to the actual repo root). Target file is the project `opencode.jsonc` (add `--global` for the global opt-in). Prefer the CLI:

```sh
opencode mcp add graphify -- graphify-mcp <repo-root>/graphify-out/graph.json
```

Manual config shape (V2):

```jsonc
{
  "mcp": {
    "servers": {
      "graphify": {
        "type": "local",
        "command": ["graphify-mcp", "<repo-root>/graphify-out/graph.json"]
      }
    }
  }
}
```

If the client cannot find the executable, replace `graphify-mcp` with its absolute tool-env path. Virtual-env alternative: run `python -m graphify.serve <repo-root>/graphify-out/graph.json` with the interpreter that has the `mcp` extra.

Build the first graph (code-only):

```sh
graphify extract . --code-only
```

Verify after install:

```sh
graphify --version
ls graphify-out/
```

Expected: `graph.json`, `graph.html`, `GRAPH_REPORT.md`. For MCP, ask the client to call `graph_stats` first, then `query_graph` with a question about the repo.

Re-run the install commands later to upgrade; re-run registration (`graphify install --platform opencode --project`) after upgrading so skill files match. If a command fails, report the output verbatim and stop. Common causes: Python < 3.10 (user installs from python.org or OS package manager — agent must ask, never install), missing `uv`/`pipx`, or no network for PyPI.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `graphify query "..."`, `graphify path "<A>" "<B>"`, `graphify explain "<Name>"` (placeholders — use real node names from their graph), plus the `@graphify` skill for mapping (`/graphify .` is an assistant instruction, not a shell command).
- If MCP was installed, name the `graphify` MCP server and its `graph_stats` / `query_graph` tools.
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No codebase analysis in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] MCP left out unless user explicitly opted in (default-off)
- [ ] No Cloud, hosted MCP, ollama, or PR workflows installed or mentioned as defaults
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed entry points and stopped without analysis
