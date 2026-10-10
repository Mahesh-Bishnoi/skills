# Drawio setup

Bootstraps the upstream drawio-skill, then gets out of the way. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- `drawio-skill`: natural language, code, Terraform/K8s, SQL, OpenAPI, AsyncAPI, Protobuf, and GraphQL sources into editable `.drawio` diagrams, plus sync, views, test, review, query, what-if, story, and HTML/PPTX/Mermaid exports. Installed via `npx skills add Agents365-ai/drawio-skill` (project-local) or with `-g` (global opt-in). Docs at https://github.com/Agents365-ai/drawio-skill
- Core workflows are stdlib-only offline on `python3`. Native export needs the draw.io desktop CLI (v30+ recommended for Mermaid conversion and ELK layout). Graphviz `dot` is optional for autolayout. Upstream CLI install docs live in the upstream repo (`docs/INSTALL_CLI.md`) — this file points there, it never installs the CLI itself.
- Optional local stdio MCP: `scripts/diagramctl_mcp.py` inside the installed skill (stdlib-only, no extra package). Docs in `skills/drawio-skill/references/mcp.md` in https://github.com/Agents365-ai/drawio-skill.

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v python3; python3 --version 2>/dev/null || true
command -v npx; npx --version 2>/dev/null || true
command -v drawio 2>/dev/null || true
drawio --version 2>/dev/null || true
command -v dot; dot -V 2>&1 || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
```

Installed means:

- `drawio-skill`: a `drawio-skill` directory under any of the above skills dirs, containing `SKILL.md` and `scripts/diagramctl.py`.
- Note whether the copy is project-local or global. If a stale global copy exists and scope is project-local, offer to remove it so it stops advertising in every session.

If present at the wanted scope, skip to Step 4. Optionally verify with `python3 <installed-path>/scripts/diagramctl.py doctor` using the actual path found above. Report `drawio --version` and `dot -V` separately as export/layout readiness, not as skill presence.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local runs the install from the project root without `-g` and lands under `.opencode/skills` (commit for team/CI). Global uses `-g` — opt-in only.
2. `Include local stdio MCP server [no]?` Default-off. Opt-in wires the installed `scripts/diagramctl_mcp.py` (stdlib-only, no `mcp` package) to the host config with `python3` plus the absolute path to the installed script. Native PNG export stays CLI-only; the MCP server deliberately does not expose it.
3. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

Project-local (default) — run from the project root:

```sh
npx skills add Agents365-ai/drawio-skill
```

Confirm the `drawio-skill` directory landed under `.opencode/skills` (or `.agents/skills`).

Global opt-in variant (only if Step 2.1 was global):

```sh
npx skills add Agents365-ai/drawio-skill -g
```

Verify after install:

```sh
python3 <installed-path>/scripts/diagramctl.py doctor
```

Draw.io desktop CLI (point to upstream, do not install here): follow the upstream `docs/INSTALL_CLI.md` recipe in https://github.com/Agents365-ai/drawio-skill for the user's platform, then verify with `drawio --version` (v30+ recommended). Graphviz is optional for autolayout (`dot -V`).

Optional MCP extra (only if Step 2.2 was yes): add an MCP entry pointing at the installed script path (adjust the path to the actual install location found above):

```json
{
  "mcpServers": {
    "drawio-skill": {
      "command": "python3",
      "args": ["<installed-path>/scripts/diagramctl_mcp.py"]
    }
  }
}
```

Claude Code alternative: `claude mcp add drawio-skill -- python3 <installed-path>/scripts/diagramctl_mcp.py` with the same path.

Re-run the install command later to refresh to the latest stable; for manual `git clone` installs, `git pull` from the install directory instead. If a command fails, report the output verbatim and stop. Common causes: missing `python3` (user installs from python.org or OS package manager — agent must ask, never install), missing `node`/`npx` (user installs Node LTS from nodejs.org or OS package manager — agent must ask, never install), or no network for npx.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed skill ID to invoke next: `@drawio-skill` for diagram generation.
- Diagram example: `Use drawio-skill to diagram a web request: Browser calls the API, the API checks Redis, and a cache miss queries PostgreSQL and fills the cache.`
- If MCP was installed, name the `drawio-skill` MCP server and its `doctor` / `build` / `query` tools.
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No diagram generation in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] MCP left out unless user explicitly opted in (default-off)
- [ ] No draw.io CLI install performed here; upstream docs referenced only
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed skill ID and stopped without diagram generation
