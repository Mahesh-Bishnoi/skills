# Agent browser setup

Bootstraps the upstream agent-browser stack, then gets out of the way. Vendors nothing — upstream moves fast and the CLI serves version-matched skill content at runtime, so this file only detects, asks, and guides install.

Upstream:

- `agent-browser`: fast native Rust browser-automation CLI (Chrome/Chromium via CDP, snapshot refs, sessions, auth vault, recording). Installed via `npm install -g agent-browser`, then `agent-browser install` downloads Chrome from Chrome for Testing. Docs at https://github.com/vercel-labs/agent-browser and https://agent-browser.dev
- Discovery skill: thin stable stub installed via `npx -y skills add vercel-labs/agent-browser -a opencode --copy -y` (project-local) or with `-g` (global opt-in). Runtime content served by the CLI via `agent-browser skills get <name>` so instructions never go stale. Skills reference at https://agent-browser.dev/skills

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

Run these checks and report the result before asking anything:

```sh
command -v agent-browser; agent-browser --version 2>/dev/null || true
agent-browser skills list 2>/dev/null || true
agent-browser doctor --offline --quick 2>/dev/null || true
command -v npm; npm --version 2>/dev/null || true
command -v npx; npx --version 2>/dev/null || true
ls ~/.config/opencode/skills 2>/dev/null || true
ls .opencode/skills 2>/dev/null || true
ls ~/.agents/skills 2>/dev/null || true
ls .agents/skills 2>/dev/null || true
ls .claude/skills 2>/dev/null || true
```

Installed means:

- `agent-browser` CLI present (`agent-browser --version` prints a version) and Chrome provisioned (`doctor` passes the Chrome check, or `agent-browser install` has been run).
- Discovery skill: an `agent-browser` directory under any of the above skills dirs (`.claude/skills` counts as a project compatibility source), containing `SKILL.md`.
- Note whether the skill copy is project-local or global. If a stale global copy exists and scope is project-local, offer to remove it so it stops advertising in every session.

If CLI + skill are present at the wanted scope and the user declined MCP, skip to Step 4. If MCP was requested and the OpenCode MCP entry for `agent-browser` already exists, skip to Step 4.

## Step 2 — Ask (one question at a time)

Ask only what is missing. Defaults in brackets. Wait for each answer.

1. `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local runs the install from the project root without `-g` and lands under `.opencode/skills` (commit for team/CI). Global uses `-g` — opt-in only. Scope only controls the skill stub placement (and MCP target file); `npm install -g agent-browser` below is always per-user global.
2. `Include MCP server entry [no]?` Default-off. Opt-in wires `agent-browser mcp` into OpenCode so MCP clients can drive the same browser. Default profile is `core`; use `all` only for full CLI parity.
3. `Confirm install?` The agent must never install software silently. Present the exact commands and get an explicit yes. The human runs them if the agent lacks permission.

## Step 3 — Install (on explicit yes only)

CLI (per-user tool install):

```sh
npm install -g agent-browser
agent-browser install
```

`npm install -g agent-browser` is per-user global (not project-local) — the Scope question only controls the skill stub below, not the CLI.

Linux variant (also installs OS browser libraries; exits nonzero if the package manager cannot satisfy them):

```sh
agent-browser install --with-deps
```

Discovery skill, project-local (default) — run from the project root:

```sh
npx -y skills add vercel-labs/agent-browser -a opencode --copy -y
```

Confirm the `agent-browser` directory landed under `.opencode/skills` or `.agents/skills` (universal, also discovered by OpenCode) — check both.

Global opt-in variant (only if Step 2.1 was global): add `-g` to the `npx -y skills add vercel-labs/agent-browser -a opencode --copy -y` command.

Optional MCP entry (only if Step 2.2 was yes). Default `core` profile keeps context small. Target file is the project `opencode.jsonc` (add `--global` for the global opt-in). Prefer the CLI:

```sh
opencode mcp add agent-browser -- agent-browser mcp
```

Manual config shape (V2):

```jsonc
{
  "mcp": {
    "servers": {
      "agent-browser": {
        "type": "local",
        "command": ["agent-browser", "mcp"]
      }
    }
  }
}
```

Full-parity variant (large context, only on request):

```sh
opencode mcp add agent-browser -- agent-browser mcp --tools all
```

Other useful profiles: `core,network`, `core,state`, `core,tabs`, `core,react`, `core,mobile`, `core,debug`. Combine with commas per task.

Verify after install:

```sh
agent-browser --version
agent-browser skills list
agent-browser doctor --offline --quick
```

Expected: version prints, `skills list` shows `core` plus `electron`, `slack`, `dogfood`, `derive-client`, `vercel-sandbox`, `protected-vercel-deployments`, `agentcore`, and `doctor` passes offline checks. Re-run `agent-browser upgrade` later to update the CLI, then re-run the `npx -y skills add vercel-labs/agent-browser -a opencode --copy -y` command (same flags, add `-g` for global) to refresh the discovery stub.

If a command fails, report the output verbatim and stop. Common causes: missing `npm`/`npx` (user installs Node LTS from nodejs.org or OS package manager — agent must ask, never install), no network for npm/npx, or missing Chrome (re-run `agent-browser install`).

## Step 4 — Hand off (no duplicate work)

Once installed (or already installed), stop setup and hand off:

- Tell the user the installed entry points: `@agent-browser` discovery skill, then runtime content via `agent-browser skills get core --full` (start here — workflows, patterns, troubleshooting), `agent-browser skills get <name> --full` for specialties.
- Specialties: `electron` (VS Code, Slack, Discord, Figma desktop apps), `slack` (workspace automation), `dogfood` (exploratory testing / QA / bug hunts), `derive-client` (HAR to API client), `vercel-sandbox` (microVMs), `protected-vercel-deployments` (auth-walled Vercel deploys), `agentcore` (AWS Bedrock cloud browsers).
- If MCP was installed, name the `agent-browser` MCP server and its default `core` profile (`agent_browser_open`, `agent_browser_snapshot`, `agent_browser_click`, `agent_browser_fill`, and friends).
- Record the choice in the project's `AGENTS.md` skills-in-use section (the `/setup` wizard does this at the end — do not edit `AGENTS.md` here).
- Stop. No browser automation in this file.

## Verification

- [ ] Detection ran before any question
- [ ] Questions asked one at a time, defaults stated, no batching
- [ ] Project-local default honored; global only on explicit opt-in
- [ ] MCP left out unless user explicitly opted in (default-off)
- [ ] No install command ran without explicit user yes
- [ ] No upstream files vendored into this repo
- [ ] Hand-off named the installed entry points and stopped without browser automation
