# AGENTS.md — skills library

Central source of truth for reusable skills. Edits happen here; projects only consume. Pushed changes propagate via `git pull` — never edit copies inside other projects.

## Layout (directory form only)

```text
apm.yml                    # APM package manifest (skill-collection form; name/version/metadata)
skills/<skill-id>/SKILL.md
skills/<skill-id>/scripts/...
skills/<skill-id>/references/...
skills/<skill-id>/apm.yml  # optional per-skill bundle manifest (composite skills declare sibling deps, e.g. web-quality-audit)
setup/                     # setup references for /setup (plain .md, never SKILL.md, never discovered as skills)
setup/bootstrap.md         # project AGENTS.md scaffold + per-project library wiring (plain reference, run as /setup Phase 0)
setup/apm.md               # APM-managed library skills for team/CI (plain reference, offered in /setup Phase 0)
commands/setup.md          # single setup wizard command (installed by scripts/install.sh)
global-AGENTS.md              # universal guidance; installed as ~/.config/opencode/AGENTS.md
templates/AGENTS.template.md  # thin per-project template (used by /setup Phase 0)
scripts/install.sh            # one-shot new-machine setup (idempotent; `--global` / `--remove-global` for the legacy global entry)
scripts/lint-skills.py        # repo tooling, not a skill
```

- Library skills live under `skills/` and wiring points at `skills/`, never the checkout root. The root holds `README.md`, `AGENTS.md`, `global-AGENTS.md` — OpenCode treats every root-level `*.md` as a flat-file skill, so a checkout-root `skills` entry would advertise those docs as bogus `README`/`AGENTS`/`global-AGENTS` skills.

- ID = directory name. Lowercase kebab-case, 1–64 chars: `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Frontmatter `name` must equal the directory ID (OpenCode treats it as display-only, but VSCode/Claude tooling requires the match); the path-derived ID is what the `skill` tool loads (case-sensitive).
- `description` in frontmatter is required — without it the skill is never advertised to the model. Frontmatter values must be ASCII-only (APM skill-collection validation) — use `-` instead of em-dashes.
- Invocation mode is one of two: advertised (default) or user-only via `metadata.opencode/autoinvoke: false`. There are no native always/once-per-session flags — those rules go in `global-AGENTS.md`, and the linter rejects such keys in skill frontmatter.
- Paths inside a skill are relative to its own directory, or relative to the skills checkout resolved at runtime (`$SKILLS_DIR`, never a hardcoded clone location). Canonical `~/.config/` references are allowed; machine-specific absolute paths (`/home/…`, `/Users/…`) and hardcoded checkout paths (`~/code/skills`) are not.
- Flat `*.md` skills and nested `teams/<id>/SKILL.md` are not used here; keep every skill top-level under `skills/` as `skills/<skill-id>/SKILL.md`.

## New-machine setup (agent task)

Fresh machines run `scripts/install.sh` from the checkout (clone location does not matter). The script is idempotent — re-run it after `git pull`:

1. Write the pointer file `~/.config/opencode/skills-repo.path` with this checkout's absolute path (locates the checkout for `/setup`; advertises nothing). Default installs add no global `skills` entry, so library skills stay invisible until a project is wired. Opt-in only: `--global` adds the checkout's `skills/` subdirectory to the global `skills` array (advertises everywhere); `--remove-global` removes both the `skills/` entry and any legacy checkout-root entry (migrate to per-project wiring). Never commit a personal checkout path into any project's `opencode.jsonc`.
2. Install universal guidance as `~/.config/opencode/AGENTS.md` by merging, never by blind overwrite (the script copies only when the target is missing; otherwise the agent merges):
   - If it doesn't exist → copy `global-AGENTS.md` verbatim.
   - If it exists → read both files, then add what's missing from the repo, update from the repo where they conflict (repo wins), and preserve local-only content untouched.
   - Present the final merged result to the user and write it only after explicit confirmation. Surface local-only rules as upstream candidates; never move them into the repo unasked.
3. Install the setup wizard as `~/.config/opencode/commands/setup.md` by copying `commands/setup.md` verbatim (create the directory if missing). It resolves the checkout via `$SKILLS_DIR`, then the pointer file, then a legacy global `skills` entry.
4. Verify: `/setup` appears in the command list everywhere; library skills advertise only in projects where `/setup` wired them (check from a wired project).

## Add / update / remove

- Add: create `skills/<skill-id>/SKILL.md` with `name` + `description`, supporting files beside it. Pick advertised (default) or user-only (`metadata.opencode/autoinvoke: false`). Run lint before committing. Setup docs are not skills — add to `setup/<topic>.md` + route via `setup/_index.md`, exposed through `commands/setup.md`.
- Update: edit here, push; checkout-wired consumers `git pull` + re-run `scripts/install.sh` if wiring changed. No re-copying needed for project-local `skills` entries pointing at the checkout's `skills/` dir. APM consumers bump the tag in their `apm.yml` + `apm install` (or `apm update`) and commit the refreshed lockfile + deployed tree.
- Release: bump the root `apm.yml` `version` and tag `vX.Y.Z` together (commit, then tag, then push both). Composite-skill manifests (`skills/web-quality-audit/apm.yml`) pin sibling deps to the same tag — update them in the same release commit.
- Remove: delete the `skills/<skill-id>/` directory. Before deleting, grep consuming projects for APM deps (`apm.yml` / `apm.lock.yaml`) and per-project copies under `.opencode/skills/<id>`.
- Team/CI sharing defaults to APM-managed mode (`setup/apm.md`): the consumer project commits `apm.yml` + `apm.lock.yaml` + `.agents/skills/` pinned to a release tag (`apm install Mahesh-Bishnoi/skills#<tag> --skill <id> ... --target opencode`); teammates/CI run `apm install --frozen`, `apm audit` detects drift. Manual per-project copies (`<project>/.opencode/skills/<id>-pinned/`) are the no-APM fallback — use a different ID, since explicit `skills` config entries outrank `.opencode/skills` on the same ID in V2. One mode per project per skill ID. Checkout wiring (project-local `skills` entry, machine-local, never committed, each teammate runs `/setup` once) remains the author's live-edit mode.
- Consumer projects: run `/setup` from the project directory. Phase 0 wires the project to the library (project-local `skills` entry, or APM-managed mode for team/CI) and scaffolds `AGENTS.md` from `templates/AGENTS.template.md`. Universal text stays in the global file; never inline it into project files.

## Verify

```sh
python3 scripts/lint-skills.py
```

Zero dependencies, stdlib only. Fails on: bad ID/dirname, missing `SKILL.md` or `description`, stray root-level skill files, machine-specific absolute paths, hardcoded checkout paths, non-native invocation keys (`always`, `once-per-session`, etc. — those belong in `global-AGENTS.md`). Warns (non-failing) on `autoinvoke: false` / `disable-model-invocation: true` since those hide the skill.
