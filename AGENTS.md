# AGENTS.md — skills library

Central source of truth for reusable skills. Edits happen here; projects only consume. Pushed changes propagate via `git pull` — never edit copies inside other projects.

## Layout (directory form only)

```text
<skill-id>/SKILL.md
<skill-id>/scripts/...
<skill-id>/references/...
setup/                     # setup references for /setup (plain .md, never SKILL.md, never discovered as skills)
setup/bootstrap.md         # project AGENTS.md scaffold (plain reference, run as /setup Phase 0)
commands/setup.md          # single setup wizard command (installed by scripts/install.sh)
global-AGENTS.md              # universal guidance; installed as ~/.config/opencode/AGENTS.md
templates/AGENTS.template.md  # thin per-project template (used by /setup Phase 0)
scripts/install.sh            # one-shot new-machine setup (idempotent)
scripts/lint-skills.py        # repo tooling, not a skill
```

- ID = directory name. Lowercase kebab-case, 1–64 chars: `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Frontmatter `name` must equal the directory ID (OpenCode treats it as display-only, but VSCode/Claude tooling requires the match); the path-derived ID is what the `skill` tool loads (case-sensitive).
- `description` in frontmatter is required — without it the skill is never advertised to the model.
- Invocation mode is one of two: advertised (default) or user-only via `metadata.opencode/autoinvoke: false`. There are no native always/once-per-session flags — those rules go in `global-AGENTS.md`, and the linter rejects such keys in skill frontmatter.
- Paths inside a skill are relative to its own directory, or relative to the skills checkout resolved at runtime (`$SKILLS_DIR`, never a hardcoded clone location). Canonical `~/.config/` references are allowed; machine-specific absolute paths (`/home/…`, `/Users/…`) and hardcoded checkout paths (`~/code/skills`) are not.
- Flat `<id>.md` files and nested `teams/<id>/SKILL.md` are not used here; keep every skill top-level.

## New-machine setup (agent task)

Fresh machines run `scripts/install.sh` from the checkout (clone location does not matter). The script is idempotent — re-run it after `git pull`:

1. Ensure the global `~/.config/opencode/opencode.jsonc` `skills` array contains the checkout's absolute path (create the file if missing, preserve other keys). Never commit a personal checkout path into any project's `opencode.jsonc`.
2. Install universal guidance as `~/.config/opencode/AGENTS.md` by merging, never by blind overwrite (the script copies only when the target is missing; otherwise the agent merges):
   - If it doesn't exist → copy `global-AGENTS.md` verbatim.
   - If it exists → read both files, then add what's missing from the repo, update from the repo where they conflict (repo wins), and preserve local-only content untouched.
   - Present the final merged result to the user and write it only after explicit confirmation. Surface local-only rules as upstream candidates; never move them into the repo unasked.
3. Install the setup wizard as `~/.config/opencode/commands/setup.md` by copying `commands/setup.md` verbatim (create the directory if missing). It resolves `setup/` relative to the checkout at runtime.
4. Verify with `opencode` skill list / `@<skill-id>` load, and confirm `/setup` appears in the command list.

Do not symlink individual skills — one array entry covers the whole repo.

## Add / update / remove

- Add: create `<skill-id>/SKILL.md` with `name` + `description`, supporting files beside it. Pick advertised (default) or user-only (`metadata.opencode/autoinvoke: false`). Run lint before committing. Setup docs are not skills — add to `setup/<topic>.md` + route via `setup/_index.md`, exposed through `commands/setup.md`.
- Update: edit here, push; consumers `git pull` + re-run `scripts/install.sh` if wiring changed. No re-copying needed for globally-referenced installs.
- Remove: delete the directory. Before deleting, grep consuming projects for per-project copies under `.opencode/skills/<id>`.
- Per-project copy (`<project>/.opencode/skills/<id>/`) is opt-in only, when a skill must ship with that repo for team/CI. Default is global reference. Avoid duplicate IDs: explicit `skills` config entries outrank `.opencode/skills` on the same ID in V2, so a pinned copy with the same ID is hidden — use a different ID (e.g. `<id>-pinned`) when pinning.
- Consumer projects: run `/setup` from the project directory. Phase 0 scaffolds `AGENTS.md` from `templates/AGENTS.template.md`. Universal text stays in the global file; never inline it into project files.

## Verify

```sh
python3 scripts/lint-skills.py
```

Zero dependencies, stdlib only. Fails on: bad ID/dirname, missing `SKILL.md` or `description`, stray root-level skill files, machine-specific absolute paths, hardcoded checkout paths, non-native invocation keys (`always`, `once-per-session`, etc. — those belong in `global-AGENTS.md`). Warns (non-failing) on `autoinvoke: false` / `disable-model-invocation: true` since those hide the skill.
