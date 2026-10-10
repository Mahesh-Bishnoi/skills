# Skills

Reusable OpenCode skills. Each skill is a top-level `<skill-id>/SKILL.md` directory (flat `*.md` skills and nested skills are not used here).

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
- `project-bootstrap` — Scaffold or refresh a consumer project's AGENTS.md from the team template.
- `security-audit` — Security guidance and vulnerability review for codebases, APIs, services, CLI tools, libraries, and daemons.
- `seo` — Optimizes web pages for search crawlability, metadata, headings, and structured data.
- `tech-skills` — Router to bundled technology guides (Java, Spring Boot, Python, Pydantic).
- `web-quality-audit` — Runs an evidence-led web quality audit across performance, accessibility, SEO, and best practices.

## Entry points

- [setup/](setup/) — `/setup` wizard source topics (routed by [setup/_index.md](setup/_index.md)).
- [commands/setup.md](commands/setup.md) — the single `/setup` wizard command.
- [templates/](templates/) — per-project `AGENTS.md` template.
- [scripts/lint-skills.py](scripts/lint-skills.py) — repo linter (stdlib only; `python3 scripts/lint-skills.py`).

See [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES) for upstream MIT sources adapted or referenced by these skills.
