# Browser harness setup

Bootstraps the upstream browser-harness stack, then gets out of the way. Vendors nothing — upstream moves fast and the CLI serves version-matched skill content at runtime via `browser-harness skill`, so this file only detects, asks, and guides install.

Upstream:

- `browser-harness`: open-source harness letting coding agents drive the user's real Chrome via CDP (tabs, logins, clicks, typing, downloads). Installed via `uv tool install --python 3.12 --upgrade --force browser-harness`. Engine behind the Browser Use CLI. Docs at https://github.com/browser-use/browser-harness and https://browser-use.com/browser-harness
- Runtime skill: body served by `browser-harness skill`. Install target is a `browser-harness` directory containing `SKILL.md` under a skills dir.
- Interaction skills: per-mechanic references at https://github.com/browser-use/browser-harness/tree/main/interaction-skills

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v browser-harness; browser-harness --version 2>/dev/null || true
browser-harness --doctor 2>/dev/null || true
browser-harness recordings 2>/dev/null || true
browser-harness auth status 2>/dev/null || true
command -v uv; uv --version 2>/dev/null || true
command -v uvx; uvx --version 2>/dev/null || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
```

Installed means:

- `browser-harness` CLI present (`browser-harness --version` prints a version, or `--doctor` runs).
- Runtime skill: a `browser-harness` directory under any of the above skills dirs, containing `SKILL.md`.
- Note whether the skill copy is project-local or global. If a stale global copy exists and scope is project-local, offer to remove it so it stops advertising in every session.

If CLI + skill are present at the wanted scope and the user previously declined MCP/Cloud, skip to Step 4. If MCP was requested and the OpenCode MCP entry for `browser-harness` already exists, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local writes to `.opencode/skills` in the current repo (commit for team/CI). Global writes to the shared skills dir — opt-in only.
2. `Enable local browser recordings [no]?` Fresh installs do not record. Preserve an existing `(config)` preference on upgrades instead of asking again.
3. `Include MCP server entry [no]?` Default-off. Opt-in wires `browser-harness-mcp` into OpenCode over stdio.
4. `Authenticate Browser Use Cloud [no]?` Default-off. Only needed for parallel/isolated/headless cloud browsers; local Chrome needs no API key.
5. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

CLI (per-user tool install):

```sh
uv tool install --python 3.12 --upgrade --force browser-harness
```

`--python 3.12` prevents uv from selecting old releases supporting older Pythons. `--upgrade --force` replaces a previous tool install with the latest stable release.

Runtime skill, project-local (default) — run from the project root:

```sh
mkdir -p .opencode/skills/browser-harness
browser-harness skill > .opencode/skills/browser-harness/SKILL.md
```

Confirm the `browser-harness` directory landed under `.opencode/skills`.

Global opt-in variant (only if Step 2.1 was global):

```sh
mkdir -p ~/.config/opencode/skills/browser-harness
browser-harness skill > ~/.config/opencode/skills/browser-harness/SKILL.md
```

Recording consent (only if Step 2.2 was unset and `browser-harness recordings` reports `(default)`). Ask once:

> Enable local browser recordings? This saves screenshots and action traces on this machine, which may include sensitive page content, so you can later ask "show me what you did" or request a video. Videos are never generated automatically. [y/N]

Default to no. Run `browser-harness recordings enable` only after yes; otherwise run `browser-harness recordings disable`.

Chrome permission (first local connection only):

1. Open `chrome://inspect/#remote-debugging` in Chrome.
2. Tick "Allow remote debugging for this browser instance".
3. Retry the verify command below.

On macOS, if Chrome shows a per-connection Allow sheet, keep the original command running and call `browser-harness mac-approve` in a second shell call with the same `BU_NAME` (omit `BU_NAME` for the default daemon). On Linux/Windows, ask the user to click Allow; their click completes the handshake.

Optional MCP entry (only if Step 2.3 was yes):

```json
{
  "mcpServers": {
    "browser-harness": {
      "command": "uvx",
      "args": ["--from", "browser-harness[mcp]", "browser-harness-mcp"]
    }
  }
}
```

Optional Cloud auth (only if Step 2.4 was yes):

```sh
browser-harness auth login
browser-harness auth status
```

Verify after install:

```sh
browser-harness --doctor
browser-harness recordings
browser-harness <<'PY'
print(page_info())
PY
```

Expected: `doctor` passes, `recordings` shows the chosen preference, and `page_info()` prints the current page. Re-run `browser-harness --update -y` later to upgrade, then re-run the `browser-harness skill > ...` command to refresh the runtime skill.

If a command fails, report the output verbatim and stop. Common causes: missing `uv`/`uvx` (user installs uv from its official installer — agent must ask, never install), no network, Chrome closed, or remote-debugging checkbox unticked (see Chrome permission above). Follow https://github.com/browser-use/browser-harness/blob/main/install.md if setup or connection fails.

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `@browser-harness` runtime skill, then in-task usage via `browser-harness <<'PY'` heredocs (`new_tab(url)` for first navigation, `page_info()`, `click_at_xy`, `js(...)`, `wait_for_load()`). Raw CDP via `cdp("Domain.method", ...)`.
- Interaction skills: `connection, cookies, cross-origin-iframes, dialogs, downloads, drag-and-drop, dropdowns, iframes, make-video, network-requests, print-as-pdf, profile-sync, screenshots, scrolling, shadow-dom, tabs, uploads, viewport` at the upstream `interaction-skills` URL above.
- If MCP was installed, name the `browser-harness` MCP server (`browser_new_tab`, `browser_page_info`, `browser_click`, `browser_type`, and friends).
- If Cloud was authenticated, name the remote flow (`start_remote_daemon("name")`, `BU_NAME=name browser-harness <<'PY'`, `stop_remote_daemon(name)` when done — cloud browsers bill until stopped).
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No browser automation in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] MCP and Cloud left out unless user explicitly opted in (default-off)
- [ ] Recordings default to no and existing preference preserved on upgrades
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed entry points and stopped without browser automation
