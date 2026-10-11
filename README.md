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
- `observability` — Instruments code so production behavior is visible and diagnosable.
- `parallel-dispatch` — Fan out two or more independent tasks to background subagents, then collect and synthesize results.
- `performance` — Optimizes measured performance bottlenecks across frontend, backend, queries, and databases.
- `security-audit` — Security guidance and vulnerability review for codebases, APIs, services, CLI tools, libraries, and daemons.
- `skill-inspector` — Reviews third-party agent skills before install (SkillSpector static evidence plus semantic review); gates `/setup` external-skill installs.
- `seo` — Optimizes web pages for search crawlability, metadata, headings, and structured data.
- `tech-skills` — Router to bundled technology guides (Java, Spring Boot, Python, Pydantic).
- `web-quality-audit` — Runs an evidence-led web quality audit across performance, accessibility, SEO, and best practices.

## Entry points

- [setup/](setup/) — `/setup` wizard source topics (routed by [setup/_index.md](setup/_index.md)): bootstrap, skillspector guardrail, archify, drawio, ui-ux, graphify, agent-browser, browser-harness, openwiki.
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

Keep this checkout updated with `git pull` — no re-copying needed for project-local `skills` entries pointing at its `skills/` subdirectory. If a project still points at the bare checkout root (legacy layout that advertised README/AGENTS as skills), replace it with `<checkout>/skills`. Copy a skill into `<project>/.opencode/skills/<id>-pinned/` only when it must ship with that repo (team/CI); use a different ID since explicit `skills` entries outrank `.opencode/skills` on duplicates.

See [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES) for upstream MIT sources adapted or referenced by these skills.
