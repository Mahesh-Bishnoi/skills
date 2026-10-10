# AGENTS.md — skills library

Central source of truth for reusable skills. Edits happen here; projects only consume. Pushed changes propagate via `git pull` — never edit copies inside other projects.

## Layout (directory form only)

```text
<skill-id>/SKILL.md
<skill-id>/scripts/...
<skill-id>/references/...
setup/                     # setup references for /setup (plain .md, never SKILL.md, never discovered as skills)
commands/setup.md          # single setup wizard command (distributed to ~/.config/opencode/commands/)
global-AGENTS.md              # universal guidance; installed as ~/.config/opencode/AGENTS.md
templates/AGENTS.template.md  # thin per-project template (not a skill)
scripts/lint-skills.py        # repo tooling, not a skill
```

- ID = directory name. Lowercase kebab-case, 1–64 chars: `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Frontmatter `name` must equal the directory ID (OpenCode treats it as display-only, but VSCode/Claude tooling requires the match); the path-derived ID is what the `skill` tool loads (case-sensitive).
- `description` in frontmatter is required — without it the skill is never advertised to the model.
- Invocation mode is one of two: advertised (default) or user-only via `metadata.opencode/autoinvoke: false`. There are no native always/once-per-session flags — those rules go in `global-AGENTS.md`, and the linter rejects such keys in skill frontmatter.
- Paths inside a skill are relative to its own directory. Canonical `~/code/skills` and `~/.config/` references are allowed; machine-specific absolute paths (`/home/…`, `/Users/…`) are not.
- Flat `<id>.md` files and nested `teams/<id>/SKILL.md` are not used here; keep every skill top-level.

## New-machine setup (agent task)

1. `git clone <this-repo-url> ~/code/skills`
2. Add one entry to global `~/.config/opencode/opencode.jsonc` (create file if missing, preserve other keys):
   ```jsonc
   { "$schema": "https://opencode.ai/config.json", "skills": ["~/code/skills"] }
   ```
   `setup/` and `commands/` contain no `SKILL.md` files, so they add zero skill advertisements.
3. Install universal guidance as `~/.config/opencode/AGENTS.md` by merging, never by blind overwrite:
   - If it doesn't exist → copy `global-AGENTS.md` verbatim.
   - If it exists → read both files, then add what's missing from the repo, update from the repo where they conflict (repo wins), and preserve local-only content untouched.
   - Present the final merged result to the user and write it only after explicit confirmation. Surface local-only rules as upstream candidates; never move them into the repo unasked.
4. Install the setup wizard as `~/.config/opencode/commands/setup.md` by copying `commands/setup.md` verbatim (create the directory if missing). It reads `setup/` from the checkout at runtime.
5. Verify with `opencode` skill list / `@<skill-id>` load, and confirm `/setup` appears in the command list.

Do not commit personal checkout paths into any project's `opencode.jsonc`. Do not symlink individual skills — one array entry covers the whole repo.

## Add / update / remove

- Add: create `<skill-id>/SKILL.md` with `name` + `description`, supporting files beside it. Pick advertised (default) or user-only (`metadata.opencode/autoinvoke: false`). Run lint before committing. Setup docs are not skills — add to `setup/<topic>.md` + route via `setup/_index.md`, exposed through `commands/setup.md`.
- Update: edit here, push; consumers `git pull`. No re-copying needed for globally-referenced installs.
- Remove: delete the directory. Before deleting, grep consuming projects for per-project copies under `.opencode/skills/<id>`.
- Per-project copy (`<project>/.opencode/skills/<id>/`) is opt-in only, when a skill must ship with that repo for team/CI. Default is global reference. Avoid duplicate IDs: explicit `skills` config entries (e.g. `~/code/skills`) outrank `.opencode/skills` on the same ID in V2, so a pinned copy with the same ID is hidden — use a different ID (e.g. `<id>-pinned`) when pinning.
- Consumer projects: scaffold their `AGENTS.md` via `@project-bootstrap` from `templates/AGENTS.template.md`. Universal text stays in the global file; never inline it into project files.

## Verify

```sh
python3 scripts/lint-skills.py
```

Zero dependencies, stdlib only. Fails on: bad ID/dirname, missing `SKILL.md` or `description`, stray root-level skill files, machine-specific absolute paths, non-native invocation keys (`always`, `once-per-session`, etc. — those belong in `global-AGENTS.md`). Warns (non-failing) on `autoinvoke: false` / `disable-model-invocation: true` since those hide the skill.
