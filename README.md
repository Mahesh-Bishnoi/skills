# Skills

Reusable OpenCode skills. Each skill is a `skills/<skill-id>/SKILL.md` directory (flat `*.md` skills and nested skills are not used here). Wiring always points at `skills/`, never the checkout root — the root holds `README.md`, `AGENTS.md`, `global-AGENTS.md`, which OpenCode would otherwise advertise as bogus skills.

## Index

One line per skill (first sentence of its description):

- `accessibility` — Audits and fixes web accessibility against WCAG 2.2 (alt text, contrast, keyboard, focus, forms, ARIA).
- `adr-skill` — Records decisions and documentation.
- `clean-code` — Language-agnostic architecture and clean-code rules for writing, modifying, refactoring, or reviewing code — deep modules, seams, SOLID, dependency injection, TDD, testing, error handling, and anti-slop discipline.
- `code-review` — Review PRs, commits, diffs, modules, folders, or whole repos for correctness, normal security, performance, tests, and clean-code lean.
- `debug` — Step-by-step debugging procedure for bugs, errors, crashes, failing or flaky tests, wrong output, and performance regressions.
- `git-worktrees` — Isolated feature work via git worktrees - create, list, remove, prune, repair when tree is dirty, parallel branches, or urgent fix needed.
- `grill` — Relentless one-question-at-a-time interview that extracts what the user actually wants and sharpens plans or designs.
- `hardening` — Hardens code against vulnerabilities while building.
- `modern-web-guidance` — Searches Chrome's Modern Web Guidance for focused, Baseline-aware recommendations.
- `observability` — Instruments code so production behavior is visible and diagnosable.
- `parallel-dispatch` — Fan out two or more independent tasks to background subagents, then collect and synthesize results.
- `performance` — Optimizes measured performance bottlenecks across frontend, backend, queries, and databases.
- `security-audit` — Security guidance and vulnerability review for codebases, APIs, services, CLI tools, libraries, and daemons.
- `skill-inspector` — Reviews third-party agent skills before install (SkillSpector static evidence plus semantic review); gates `/setup` external-skill installs.
- `seo` — Optimizes web pages for search crawlability, metadata, headings, and structured data.
- `tech-skills` — Router to bundled technology guides (Java, Spring Boot, Python, Pydantic).
- `web-quality-audit` — Runs an evidence-led web quality audit across performance, accessibility, SEO, and best practices.

## Entry points

- [setup/](setup/) — `/setup` wizard source topics (routed by [setup/_index.md](setup/_index.md)): bootstrap, APM-managed skills, skillspector guardrail, archify, drawio, ui-ux, graphify, agent-browser, browser-harness, openwiki.
- [commands/setup.md](commands/setup.md) — the single `/setup` wizard command (Phase 0 bootstrap + Phase 1 optional tooling).
- [templates/](templates/) — per-project `AGENTS.md` template (used by `/setup` Phase 0).
- [scripts/install.sh](scripts/install.sh) — one-shot new-machine setup (idempotent).
- [scripts/lint-skills.py](scripts/lint-skills.py) — repo linter (stdlib only; `python3 scripts/lint-skills.py`).

## Setup

One-time per machine:

```sh
git clone https://github.com/Mahesh-Bishnoi/skills
cd skills && ./scripts/install.sh
```

(If `./scripts/install.sh` refuses to run, use `bash scripts/install.sh` —
same effect. `git` preserves the script's executable bit on checkout.)

The script writes the pointer file (`~/.config/opencode/skills-repo.path`
locating this checkout for `/setup`), installs global `AGENTS.md` on fresh
machines and the `/setup` command — and adds no global `skills` entry, so
library skills stay invisible until a project is wired. Flags: `--global` opts
into the legacy global `skills` entry (advertises everywhere);
`--remove-global` removes it to migrate to per-project wiring. The script is
safe to re-run after `git pull`. On machines where global `AGENTS.md` already
exists it is never overwritten — the agent merges `global-AGENTS.md` with
explicit confirmation instead. `/setup` stays visible in every project; restart
the agent and confirm with the command list.

Per project — run from the project directory:

```text
/setup
```

Phase 0 wires the project to the library (project-local `skills` entry in
`.opencode/opencode.jsonc` pointing at this checkout's `skills/` subdirectory, so library skills
advertise only here — each teammate runs `/setup` once and never commits a
personal checkout path) and scaffolds or refreshes `AGENTS.md` from [templates/AGENTS.template.md](templates/AGENTS.template.md)
(stack, entrypoints, commands, skills-in-use; verified content preserved).
Phase 1 asks which optional tooling you need
(diagrams, browser automation, design taste, code graph, wiki) and installs it
project-local into `.opencode/skills/` so it advertises only in that project.
`skills-in-use` in the project's `AGENTS.md` records the choice.

Keep this checkout updated with `git pull` — no re-copying needed for project-local `skills` entries pointing at its `skills/` subdirectory. If a project still points at the bare checkout root (legacy layout that advertised README/AGENTS as skills), replace it with `<checkout>/skills`. When skills must ship with a project repo (team/CI), use APM-managed mode below instead of manual copies.

## Team / CI sharing via APM

[APM](https://github.com/microsoft/apm) (Agent Package Manager) turns this library into a pinned, lockfile-backed dependency. The project commits `apm.yml` + `apm.lock.yaml` + the deployed `.agents/skills/` tree; teammates and CI reproduce it byte-for-byte — no personal checkout paths, no silent drift.

```sh
# in the project repo (APM CLI; installs from GitHub, pinned to a release tag)
apm install Mahesh-Bishnoi/skills#v0.1.0 --skill clean-code --skill debug --target opencode
```

- `--skill` cherry-picks from the collection (repeatable); the selection is persisted in the project's `apm.yml` and lockfile, so a bare `apm install` is deterministic afterwards. Omit `--skill` to install all skills.
- Skills deploy to `.agents/skills/` — discovered by OpenCode and other `.agents`-aware harnesses (Claude Code, Copilot, Cursor, Codex, ...). Commit `apm.yml`, `apm.lock.yaml`, and `.agents/skills/`; `apm_modules/` is cache and is auto-gitignored.
- Composite skills carry their dependencies: `apm install Mahesh-Bishnoi/skills/skills/web-quality-audit#v0.1.0` also installs `performance`, `accessibility`, and `seo`.
- CI: `apm install --frozen` (fails on manifest/lockfile drift) plus `apm audit` (per-file content hashes; detects hand-edits and hidden-Unicode tampering).
- Updates: `apm outdated`, then `apm update` — or bump the tag in `apm.yml` and re-install. Re-scan updated skills with `skill-inspector` before use.
- One mode per project per skill ID: don't mix checkout wiring and APM-deployed copies of the same skill (duplicate-ID shadowing — explicit `skills` config entries outrank discovered copies).

`/setup` offers this as the APM-managed wiring mode ([setup/apm.md](setup/apm.md)). Checkout wiring stays the author's live-edit mode (edit here → `git pull` propagates); APM is the distribution mode. Manual pinned copies (`<project>/.opencode/skills/<id>-pinned/`, different ID) remain the fallback for environments without APM.

Releases: the root `apm.yml` version and the git tag (`vX.Y.Z`) are bumped together; composite-skill manifests pin their siblings to the same tag.

See [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES) for upstream MIT sources adapted or referenced by these skills.
