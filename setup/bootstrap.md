# Project bootstrap (run as `/setup` Phase 0)

Scaffold or refresh the current project's `AGENTS.md` from the team template,
and wire this project to the skills library project-locally so library skills
advertise only here. Template source is `templates/AGENTS.template.md` in the
skills checkout — resolve the checkout via `$SKILLS_DIR`, then the pointer file
at `~/.config/opencode/skills-repo.path`, then a legacy global `skills` entry
(never a hardcoded location). This file is a plain reference, never a skill.

Project `AGENTS.md` and existing codebase conventions override this file.

## Step 1 — Detect (read-only, no installs)

- Resolve and validate the checkout: `$SKILLS_DIR` first, then the pointer file
  at `~/.config/opencode/skills-repo.path`. If the pointer file is missing or
  points at a path that does not exist, report it as stale and offer to rewrite
  it (explicit yes before writing). A legacy global `skills` entry pointing at
  the checkout still resolves, but report it as legacy.
- Read the project's `.opencode/opencode.jsonc`; check its `skills` array
  includes the checkout path. If missing, report it as the likely reason
  library skills do not advertise in this project. Without this project-local
  entry the library skills never advertise here (by design — other projects
  stay clean). If a legacy global `skills` entry points at the checkout, report
  that the library currently advertises in every project and offer to remove
  the global entry (e.g. via `scripts/install.sh --remove-global`, explicit yes
  before writing).
- Check whether the project has `AGENTS.md` and whether every template
  placeholder is filled. If verified content already exists, preserve it —
  only fill gaps or reconcile drift.
- Check the global `~/.config/opencode/AGENTS.md` exists (sourced from
  `global-AGENTS.md` in the checkout). If missing, offer to install it; never
  inline universal guidance into the project file.

## Step 2 — Ask (only what is missing)

- If the pointer file is missing or stale: `Rewrite the pointer file with this checkout path [yes]?`
- If this project is not wired: `Add the checkout to this project's .opencode/opencode.jsonc skills and re-verify [yes]?`
- If a legacy global entry exists: `Remove the checkout from the global skills array so it stops advertising everywhere [yes]?`
- Only on explicit yes do any writes happen.

## Step 3 — Write (on explicit yes where required)

1. Fix the pointer file first if approved (single absolute checkout path).
2. Wire the project: create `<project>/.opencode/opencode.jsonc` if missing,
   preserve other keys, and add the checkout's absolute path to its `skills`
   array (no duplicates). This entry is machine-local: never commit a personal
   checkout path — each teammate runs `/setup` once to wire their own checkout.
   Team-shared skills still ship as pinned copies under `.opencode/skills/`,
   not via this entry.
3. Inspect the target project just enough to fill every placeholder: root
   manifests, entrypoints, test/lint/typecheck commands, major directories.
   Prefer executable sources (configs, scripts, CI) over prose.
4. Write the project's `AGENTS.md`: architecture, commands (including the
   focused single-test/package command and any required order), testing
   quirks, and the skills-in-use section. Keep it short — every line must
   answer "would an agent likely miss this without help?"
5. Do not copy universal guidance (skill policy, code/testing discipline) into
   the project file — that lives in the global file.
6. Tell the user what was filled, what was guessed vs. verified, and anything
   the repo couldn't answer.

## Verification

- [ ] Checkout resolved via `$SKILLS_DIR` / pointer file (staleness checked)
- [ ] Project-local `skills` entry checked before any write
- [ ] Legacy global entry reported / removed only on explicit yes
- [ ] Existing verified `AGENTS.md` content preserved, gaps only
- [ ] No universal guidance duplicated into the project file
