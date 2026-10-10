# Archify setup

Bootstraps the upstream Archify skill, then gets out of the way. Vendors nothing — upstream moves fast, so this file only detects, asks, and guides install.

Upstream:

- `archify`: validated architecture, workflow, sequence, dataflow, and lifecycle diagrams as standalone HTML. Installed via `npx skills add tt-a1i/archify` (project-local) or with `-g` (global opt-in). Docs at https://github.com/tt-a1i/archify and https://archify.si

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v node; node --version 2>/dev/null || true
command -v npx; npx --version 2>/dev/null || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
```

Installed means:

- `archify`: an `archify` directory under any of the above skills dirs, containing `SKILL.md` and `bin/archify.mjs`.
- Note whether the copy is project-local (`.opencode/skills`) or global (`~/.config/opencode/skills`). If a stale global copy exists and scope is project-local, offer to remove the global copy so it stops advertising in every session.

If present at the wanted scope, skip to Step 4. Optionally verify with `node <installed-path>/bin/archify.mjs doctor` using the actual path found above.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local runs the install from the project root without `-g` and lands under `.opencode/skills` (commit for team/CI). Global uses `-g` and advertises everywhere — opt-in only.
2. `Confirm install?` The agent must never install software silently. Present the exact command and get an explicit yes. The human runs it if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

Project-local (default) — run from the project root:

```sh
npx skills add tt-a1i/archify
```

Confirm the `archify` directory landed under `.opencode/skills` (or `.agents/skills`).

Global opt-in variant (only if Step 2.1 was global):

```sh
npx skills add tt-a1i/archify -g
```

Verify after install:

```sh
node <installed-path>/bin/archify.mjs doctor
```

Re-run the install command later to refresh to the latest stable. If a command fails, report the output verbatim and stop. Common causes: missing `node`/`npx` (user installs Node LTS from nodejs.org or OS package manager — agent must ask, never install), or no network for npx.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed skill ID to invoke next: `@archify` for diagram generation.
- Diagram example: `Use Archify to diagram a web request: Browser calls the API, the API checks Redis, and a cache miss queries PostgreSQL and fills the cache.`
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No diagram generation in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed skill ID and stopped without diagram generation
