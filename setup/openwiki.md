# OpenWiki setup

Bootstraps the upstream OpenWiki CLI + OpenCode integration, then gets out of the way. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- `openwiki`: CLI that writes and maintains a linked Markdown wiki for a codebase (`openwiki/` in the repo) plus an OpenWiki-managed block in `AGENTS.md`. Installed via `npm install -g openwiki` (needs Node.js 22.22.0 or newer). Docs at https://github.com/langchain-ai/openwiki
- OpenCode integration: `openwiki integrations install opencode --project` (project-local) or without `--project` (global opt-in). Provides the `@openwiki` skill and the `openwiki_search` / `openwiki_read` / `openwiki_list_workspaces` / `openwiki_list_wikis` MCP tools. Default path uses the host agent's authenticated model session, so no separate provider key is needed.

Project `AGENTS.md` and existing codebase conventions override this file.

Out of scope (never set up here unless the user explicitly asks): standalone CLI provider onboarding (`openwiki --init` / `--update` with fourteen providers and keys in `~/.openwiki/.env`), `personal` mode and connectors (Notion, Gmail, Slack, X, web search, Hacker News, LangSmith), `openwiki link` workspaces, `openwiki visualize` publishing, scheduled CI update workflows, telemetry changes. Those need accounts, keys, or background jobs.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v node; node --version 2>/dev/null || true
command -v npm; npm --version 2>/dev/null || true
command -v openwiki; openwiki --version 2>/dev/null || true
openwiki integrations list 2>/dev/null || true
ls openwiki 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .claude/skills 2>/dev/null || true
```

Installed means:

- `openwiki` CLI present (`openwiki --version` prints a version).
- OpenCode integration present: an `openwiki` directory under one of the skills dirs above (`.claude/skills` counts as a project compatibility source) containing `SKILL.md`, or `openwiki integrations list` showing the opencode integration.
- Note whether the integration is project-local (under `.opencode/skills` in the current repo) or global (`~/.config/opencode/skills`). If a stale global copy exists and scope is project-local, offer to remove the global copy so it stops advertising in every session.
- Note whether an `openwiki/` wiki already exists in the repo (does not block install; it only affects the handoff prompt: initialize vs update).

If CLI + integration are present at the wanted scope, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local runs the integration install from the project root with `--project` and lands under `.opencode/skills` (commit for team/CI). Global omits `--project` and advertises everywhere — opt-in only. `npm install -g openwiki` is always per-user global; scope only controls integration placement.
2. `Standalone provider keys instead of the agent-managed default [no]?` Default-off. Default path stays in the coding agent (no keys). Saying yes switches to `openwiki --init` provider onboarding with keys in `~/.openwiki/.env` — ask which provider before proceeding.
3. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

Base (agent-managed, no provider keys), project-local (default) — run from the project root:

```sh
npm install -g openwiki
openwiki integrations install opencode --project
```

Restart the coding agent after install so the `@openwiki` skill and MCP tools load.

Global opt-in variant (only if Step 2.1 was global): drop `--project` from the second command.

Standalone variant (only if Step 2.2 was yes): after the base install, run `openwiki --init` and follow its provider/credentials/model onboarding. Prefer the agent-managed default unless the user needs scheduled or unattended runs.

Verify after install:

```sh
openwiki --version
openwiki integrations list
```

Confirm the `openwiki` directory landed under `.opencode/skills` or `.agents/skills` (universal, also discovered by OpenCode) — check both.

Re-run the install commands later to upgrade. If a command fails, report the output verbatim and stop. Common causes: missing `node`/`npm` (user installs Node 22.22.0+ from nodejs.org or OS package manager — agent must ask, never install), no network for npm, or a stale global integration shadowing the project-local one.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `@openwiki` skill plus `openwiki_search` (ranked lookup) and `openwiki_read` (full sections) MCP tools. Retrieval is for concrete questions, not a routine step at the start of every task.
- Wiki prompts (placeholders — the user runs these next, not this file): new wiki with `Initialize this repository's OpenWiki from the current source and tests.` Existing wiki with `Update this repository's OpenWiki for changes since its last successful run.`
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No wiki initialization, updates, searches, or codebase analysis in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] Agent-managed default honored; standalone keys only on explicit opt-in
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed entry points and stopped without wiki work
