# Setup index

Read this file first when `/setup` runs. It routes to one file per stack in this directory. These files are plain references — they are never discovered as skills, never advertised, and cost zero context until `/setup` reads them.

Checkout location is `~/code/skills` by default — ask the user if it isn't there. All paths below are relative to this directory unless stated otherwise.

## Files

- `archify.md` — validated architecture/workflow/sequence/dataflow/lifecycle diagrams as standalone HTML (`@archify` after install).
- `drawio.md` — editable `.drawio` diagrams from language/code/IaC/SQL/API sources (`@drawio-skill` after install).
- `ui-ux.md` — design-system generator + frontend taste (`@ui-ux-pro-max`, `@design-taste-frontend` after install).
- `graphify.md` — local code-graph CLI + skill, optional stdio MCP (`graphify` CLI + `@graphify` after install).
- `agent-browser.md` — Vercel agent-browser automation, isolated test browser (`@agent-browser` discovery skill after install).
- `browser-harness.md` — browser-harness real-Chrome automation, logged-in user Chrome (`@browser-harness` runtime skill after install).
- `openwiki.md` — living Markdown wiki for the repo, agent-managed via host model session (`@openwiki` + `openwiki_search` / `openwiki_read` after install).

## How to choose (tell the user)

- Diagrams: Archify = validated standalone HTML diagrams. drawio-skill = editable `.drawio` files plus sync/views/test/review/query/exports. Install one or both.
- Browser: agent-browser = fast isolated test browser (CI-friendly, sessions, auth vault). browser-harness = drives the user's real logged-in Chrome via CDP. Install one or both.
- Design: ui-ux-pro-max = design-system generator; taste (`design-taste-frontend`) = anti-slop taste enforcement. Usually installed together.
- Code graph: Graphify = local codebase querying for large/unfamiliar repos.
- Knowledge: OpenWiki = linked Markdown wiki the agent searches/reads for concrete architecture questions; Graphify = exhaustive local code graph. Install one or both.

## Rules for `/setup`

- Default scope is project-local (`.opencode/skills` in the current repo, committed for team/CI). Global (`-g` / `~/.config/opencode/skills`) only on explicit opt-in — global installs advertise the installed skill in every session.
- CLI installs via `npm install -g` / `uv tool install` are per-user global by nature; Scope only controls skill file placement and `uipro init` / `graphify install --project` / `openwiki integrations install --project` / MCP target file (project `opencode.jsonc` vs global with `--global`).
- Default-off everywhere: MCP entries, Cloud auth, recordings. Ask once, never enable silently.
- Never run an install without an explicit yes. Present exact commands first; the human runs them if the agent lacks permission.
- On failure report output verbatim and stop.
- After install, offer to record choices in the project's `AGENTS.md` skills-in-use section. Do not edit `AGENTS.md` inside stack files — the wizard does it at the end.
