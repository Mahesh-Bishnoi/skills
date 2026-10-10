# Project bootstrap (run as `/setup` Phase 1)

Scaffold or refresh the current project's `AGENTS.md` from the team template.
Template source is `templates/AGENTS.template.md` in the skills checkout —
resolve the checkout from this file's own path (never a hardcoded location);
`$SKILLS_DIR` overrides if set. This file is a plain reference, never a skill.

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

- Read global `~/.config/opencode/opencode.jsonc`; check the `skills` array
  includes the checkout path. If missing, report it as the likely reason only
  project-local installs are visible and offer to add it (create the file if
  missing, preserve other keys such as `plugins`, explicit yes before writing).
  Without this entry the library skills never advertise.
- Check whether the project has `AGENTS.md` and whether every template
  placeholder is filled. If verified content already exists, preserve it —
  only fill gaps or reconcile drift.
- Check the global `~/.config/opencode/AGENTS.md` exists (sourced from
  `global-AGENTS.md` in the checkout). If missing, offer to install it; never
  inline universal guidance into the project file.

## Step 2 — Ask (only what is missing)

- If the global wiring is missing: `Add the checkout to global skills and re-verify [yes]?`
- Only on explicit yes do any writes happen.

## Step 3 — Write (on explicit yes where required)

1. Inspect the target project just enough to fill every placeholder: root
   manifests, entrypoints, test/lint/typecheck commands, major directories.
   Prefer executable sources (configs, scripts, CI) over prose.
2. Write the project's `AGENTS.md`: architecture, commands (including the
   focused single-test/package command and any required order), testing
   quirks, and the skills-in-use section. Keep it short — every line must
   answer "would an agent likely miss this without help?"
3. Do not copy universal guidance (skill policy, code/testing discipline) into
   the project file — that lives in the global file.
4. Tell the user what was filled, what was guessed vs. verified, and anything
   the repo couldn't answer.

## Verification

- [ ] Global wiring checked before any write
- [ ] Existing verified `AGENTS.md` content preserved, gaps only
- [ ] No universal guidance duplicated into the project file
