---
name: project-bootstrap
description: Scaffold or refresh a consumer project's AGENTS.md from the team template
metadata:
  opencode/autoinvoke: false
---

Create or refresh the project's `AGENTS.md` from the team template. Template source is `templates/AGENTS.template.md` in the skills checkout (default location `~/code/skills` — ask the user if it isn't there).

## Workflow

1. Read the template file. It marks which sections are portable (keep) vs. personal (lives in the global file, don't duplicate).
2. Inspect the target project just enough to fill every placeholder: root manifests, entrypoints, test/lint/typecheck commands, major directories. Prefer executable sources (configs, scripts, CI) over prose. If the template already exists at the project with verified content, preserve it and only fill gaps or reconcile drift.
3. Write the project's `AGENTS.md`: architecture, commands (including the focused single-test/package command and any required order), testing quirks, and the skills-in-use section. Keep it short — every line must answer "would an agent likely miss this without help?"
4. Do not copy universal guidance (skill policy, code/testing discipline) into the project file — that lives in the global `~/.config/opencode/AGENTS.md`, sourced from `global-AGENTS.md` in the skills checkout. If the global file is missing, offer to install it; don't inline its content.
5. Ensure the `/setup` wizard command is installed: check `~/.config/opencode/commands/setup.md` exists and matches `commands/setup.md` in the checkout; if missing or stale, offer to copy it verbatim (create the directory if missing). Then, if the project needs optional tooling (diagrams, browser automation, design taste, code graph), offer `/setup` (single setup wizard; installs project-local into `.opencode/skills` so installed skills advertise only in this project). Run only on explicit yes; on completion record the chosen scope/variant in the AGENTS.md skills-in-use section.
6. Tell the user what was filled, what was guessed vs. verified, and anything the repo couldn't answer.
