# APM-managed library skills (team/CI distribution)

Alternative wiring mode for projects that must ship library skills with the repo:
declare them in the project's `apm.yml` pinned to a release tag, deploy to
`.agents/skills/`, lock with `apm.lock.yaml`. Teammates and CI reproduce the exact
tree with `apm install --frozen` — no manual copies, no personal checkout paths,
and `apm audit` detects hand-edits via per-file content hashes. This file is a
plain reference, never a skill.

Mode choice: checkout wiring (`bootstrap.md`) is the author's live-edit mode (edit
in the checkout → `git pull` propagates). APM is the distribution mode for
team/shared projects. **One mode per project per skill ID** — never both for the
same skill: explicit `skills` config entries outrank discovered copies on
duplicate IDs, so mixing reintroduces shadowing.

APM CLI: <https://github.com/microsoft/apm> (OpenCode is a first-class target;
skills land in `.agents/skills/`, which OpenCode discovers natively — no
`opencode.jsonc` `skills` entry is needed for APM-deployed skills).

## Step 1 — Detect (read-only, no installs)

- `command -v apm`. If missing, report it and offer the install command from the
  APM README (explicit yes before running anything).
- Read the project's `apm.yml` if present: look for `Mahesh-Bishnoi/skills`
  entries under `dependencies.apm` (string form `Mahesh-Bishnoi/skills#<tag>` or
  object form with a `skills:` subset). If found, the project is already
  APM-managed — verify instead of re-wire: `apm install --frozen` (restores the
  locked tree) and `apm audit` (drift check), each on explicit yes.
- Check `.agents/skills/` and `apm.lock.yaml` exist and are committed
  (`git ls-files .agents/skills apm.lock.yaml apm.yml`); check the project's
  `.gitignore` does not exclude `.agents/` (consumer projects commit the
  deployed tree; only `apm_modules/` cache is ignored).
- Conflict check: if `.opencode/opencode.jsonc` has a checkout `skills` entry
  covering the same skill IDs the project ships via APM, report the duplicate-ID
  shadowing risk and offer to remove the checkout entry for those IDs (explicit
  yes; keep the entry if it still serves other, non-APM skills).

## Step 2 — Ask (only what is missing)

- `Which library skills should this project ship?` — list candidates from the
  checkout's README index (or `ls <checkout>/skills`). Note composites:
  `web-quality-audit` orchestrates `performance`, `accessibility`, `seo` — in
  collection mode select all four; installing the single subpath
  `Mahesh-Bishnoi/skills/skills/web-quality-audit#<tag>` pulls the three
  siblings automatically.
- `Pin to which release tag [latest]?` — list tags with
  `git ls-remote --tags https://github.com/Mahesh-Bishnoi/skills`. Never install
  unpinned HEAD for team/CI use.
- `Confirm install?` — present the exact commands and get an explicit yes.

## Step 3 — Install (on explicit yes)

1. Preview: `apm install Mahesh-Bishnoi/skills#<tag> --skill <a> --skill <b> --target opencode --dry-run`
   (omit `--skill` for the whole library). Show the routing plan.
2. Install: same command without `--dry-run`. APM downloads to `apm_modules/`
   (auto-gitignored), runs its hidden-Unicode content scan, deploys whole skill
   folders to `.agents/skills/`, and writes/updates `apm.yml` (the `--skill`
   subset is persisted) + `apm.lock.yaml` (resolved commit + per-file hashes).
3. Scan gate before first use: deployed files are not active until an agent
   loads them, so immediately run `@skill-inspector` per `skillspector.md` on
   each deployed `.agents/skills/<id>/`. On `CAUTION`/`REJECT` show exact reasons
   and let the user decide; on rejection remove the skill (`apm uninstall` or
   delete its directory + lockfile entry via reinstall) and report. Record
   verdicts in `AGENTS.md` skills-in-use.
4. Integrity: `apm audit` — must be clean (no drift, no content findings).
5. Commit `apm.yml`, `apm.lock.yaml`, and `.agents/skills/` together.
6. Record in the project's `AGENTS.md` skills-in-use: mode `apm`, package
   `Mahesh-Bishnoi/skills`, tag, skill subset. The wizard does this at the end —
   do not edit `AGENTS.md` here.

## Teammates and CI

- Teammates: `apm install --frozen` in the project root — no `/setup` needed for
  library skills (still needed for project `AGENTS.md` scaffolding and optional
  tooling).
- CI: `apm install --frozen && apm audit` — frozen fails on any manifest/lockfile
  drift; audit fails on hand-edited deployed files.

## Updates

- `apm outdated` to see newer tags, then `apm update` (consent prompt), or bump
  the tag in `apm.yml` and re-run `apm install`. Commit the refreshed lockfile +
  deployed tree together.
- Re-run the scan gate on updated skills before use, and `apm audit` after.

## Verification

- [ ] `apm` CLI present (install only on explicit yes)
- [ ] Release tag pinned; `--skill` subset persisted in `apm.yml`
- [ ] Scan-gate verdicts recorded; nothing rejected left deployed
- [ ] `apm audit` clean
- [ ] `apm.yml` + `apm.lock.yaml` + `.agents/skills/` committed; `apm_modules/` ignored; `.agents/` not gitignored
- [ ] No checkout `skills` entry shadowing the same skill IDs
- [ ] `AGENTS.md` skills-in-use records mode/tag/subset
