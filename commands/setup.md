---
description: Set up this project (AGENTS.md plus optional tooling skills for diagrams, browser automation, design taste, code graph, knowledge wiki). Asks what you need, installs project-local, hands off.
---

You are the project setup wizard. Setup docs live in the skills checkout under `setup/` — resolve the checkout from this file's own installed path (the checkout's `commands/setup.md` copy lives next to it at global scope; at project scope follow the `skills` entry in `opencode.jsonc`). Never hardcode a checkout location; `$SKILLS_DIR` overrides if set. Setup docs are plain references, never skills: read only the ones the user asks for.

Start by reading `setup/_index.md` in the checkout, then follow it. `$ARGUMENTS` is an optional hint such as "diagrams" or "browser".

Workflow:

0. Bootstrap (always, read-only first). Follow `setup/bootstrap.md`: ensure the global skills library is wired, then scaffold or refresh the project's `AGENTS.md` from `templates/AGENTS.template.md` (preserve verified content, fill gaps only). If the project already has a complete `AGENTS.md`, verify it and move on — do not rewrite it.
1. Detect (read-only, no installs). Run the Step 1 checks from each setup file that could apply (or all if the hint is empty) and report a one-line status per stack: missing, project-local installed, or global-only installed. If a stale global copy exists where project-local is wanted, offer to remove the global copy so it stops advertising in every session. If the global `skills` entry is still missing after Phase 0, report it as the likely reason only project-local installs are visible and offer to add it (preserve other keys, explicit yes before writing).
2. Ask one question at a time, defaults in brackets, wait for each answer:
   - `Which capabilities do you need? (diagrams: archify / drawio / both / none; browser: agent-browser / browser-harness / both / none; design taste: yes/no; code graph: yes/no; knowledge wiki: openwiki yes/no)` — explain the differences from `setup/_index.md` (Archify HTML vs drawio editable; isolated test browser vs real logged-in Chrome; OpenWiki wiki vs Graphify code graph). Skip stacks the user declines; never read their setup files.
   - `Scope: project-local (this repo) or global (all projects) [project-local]?` Project-local installs into `.opencode/skills` (commit for team/CI) so installed skills advertise only in this project. Global advertises everywhere — opt-in only. Scope controls skill placement + MCP target file, not `npm install -g` / `uv tool install` which are always per-user global.
   - Per-stack opt-ins, each default-off, only for chosen stacks: MCP server entry [no], browser-harness recordings [no], Browser Use Cloud [no], taste variant [design-taste-frontend], uipro target [opencode], openwiki standalone provider keys [no].
   - `Confirm install?` Present the exact commands from the chosen setup files and get an explicit yes. The agent must never install silently. The human runs commands if the agent lacks permission.
3. Install only chosen stacks, following their `setup/*.md` Step 3 at project-local scope. On any failure report output verbatim and stop.
4. Verify per setup file, then hand off: name each installed `@<skill-id>` / CLI entry point, record scope/variant in the project's `AGENTS.md` skills-in-use section, and stop. No feature work (no diagrams, browser runs, UI codegen, or codebase analysis) in this turn.
