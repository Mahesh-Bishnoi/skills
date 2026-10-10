# UI/UX setup

Bootstraps two upstream design skills, then gets out of the way. Vendors nothing — upstream repos move fast, so this file only detects, asks, and guides install.

Upstreams:

- `ui-ux-pro-max`: design-system generator (192 rules, styles, palettes, fonts). Installer CLI is `uipro` from npm package `ui-ux-pro-max-cli` (stale `uipro-cli` must not be used). Docs at https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- `taste`: anti-slop frontend taste. Default variant is `design-taste-frontend` (v2 experimental). Installed via `npx skills add https://github.com/Leonxlnx/taste-skill`. Docs at https://github.com/Leonxlnx/taste-skill

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v uipro; uipro versions 2>/dev/null || true
command -v python3; python3 --version
command -v npx; npx --version
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
```

Installed means:

- `ui-ux-pro-max`: a `ui-ux-pro-max` directory under any of the above skills dirs, or `uipro` CLI present.
- `taste`: a `design-taste-frontend*` entry (SKILL.md with install name `design-taste-frontend`) under any of the above skills dirs.
- Note whether copies are project-local or global. If stale global copies exist and scope is project-local, offer to remove them so they stop advertising in every session.

If both are present at the wanted scope, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local writes to `.opencode/skills` in the current repo (commit for team/CI). Global writes to `~/.config/opencode/skills` (via `uipro init --ai opencode --global`) — opt-in only, advertises everywhere.
2. `uipro target [opencode]?` Options: `opencode`, `universal` (`.agents/skills`, also discovered by OpenCode), `all`. Recommend `opencode` for OpenCode-only, `universal` when the user also uses other agents.
3. `taste variant [design-taste-frontend]?` Default is the v2 rewrite. Mention alternatives only if asked: `design-taste-frontend-v1` (pinned old behavior), `gpt-taste`, `redesign-existing-projects`, `minimalist-ui`, `high-end-visual-design`, `industrial-brutalist-ui`, imagegen variants. Install single skill by default, not the whole repo.
4. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

ui-ux-pro-max, project-local (default) — run from the project root:

```sh
npm install -g ui-ux-pro-max-cli
uipro init --ai opencode
```

Global opt-in variant (only if Step 2.1 was global): add `--global` to the `uipro init` command. Replace `opencode` with `universal` or `all` per Step 2.2. Refresh later with `uipro update` (add `--global` to match scope). Preview without writing via `uipro init --ai opencode --dry-run`.

taste (default variant), project-local — run from the project root:

```sh
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

Confirm the taste directory landed under `.opencode/skills`. (The taste installer writes project-local when run from the project root; add `-g` only for the global opt-in.)

Omit `--skill` to install all taste variants. Re-run the same command to upgrade v1 to v2. Pin v1 only on request with `--skill "design-taste-frontend-v1"`.

If a command fails, report the output verbatim and stop. Common causes: missing `python3` (user installs from python.org or OS package manager — agent must ask, never install), stale `uipro-cli` package shadowing `uipro`, or no network for npm/npx.

## Step 4 — Hand off (no duplicate work)

Once both are installed (or were already installed), stop setup and hand off:

- Tell the user the installed skill IDs to invoke next: `@ui-ux-pro-max` for design-system generation, `@design-taste-frontend` for taste enforcement.
- Design-system example (adjust path to where `uipro` installed it): `python3 .opencode/skills/ui-ux-pro-max/scripts/search.py "saas landing" --design-system -p "MyApp"`.
- Record choices in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No UI codegen in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed skill IDs and stopped without codegen
