---
name: tech-skills
description: Router to bundled technology guides (Java, Spring Boot, Python, Pydantic). Load before any stack-specific implementation to detect the project stack from manifests and read only the applicable guides.
---

# Tech Skills Router

You have loaded the router, not the guides. The guides live in `skills/` beside this file. They are NOT standalone skills and are NOT advertised — read only the ones that apply. Exception: FastAPI has no bundled guide; it always comes from the vendor skill (see table).

## Mandatory workflow

Follow in order. Do not skip.

### 1. Fast path: read project `AGENTS.md`

Read the consumer project's `AGENTS.md` `Stack:` line if present. This is a hint, not truth.

### 2. Verify against manifests (max ~5 reads)

Check only what exists at the project root. Stop as soon as the stack is identified:

| Signal | Read guide |
|---|---|
| `pom.xml` with `spring-boot-starter-*`, or `build.gradle[.kts]` with `org.springframework.boot` | [skills/spring-boot.md](skills/spring-boot.md) + [skills/java.md](skills/java.md) |
| `pom.xml` / `build.gradle[.kts]` without Spring Boot | [skills/java.md](skills/java.md) |
| `pyproject.toml` / `requirements*.txt` containing `fastapi` | vendor FastAPI skill (see below) + [skills/python.md](skills/python.md) + [skills/pydantic.md](skills/pydantic.md) |
| `pyproject.toml` / `requirements*.txt` containing `pydantic` without `fastapi` | [skills/pydantic.md](skills/pydantic.md) + [skills/python.md](skills/python.md) |
| `*.py` project with none of the above | [skills/python.md](skills/python.md) |

Future guides (databases, frameworks, tools) follow the same rule: match by manifest/dependency signal, read only on match.

### 2b. FastAPI vendor skill (no bundled guide)

There is no `skills/fastapi.md` — do not create one. FastAPI guidance always comes from the vendor so it stays matched to the installed FastAPI version:

1. Docs: https://fastapi.tiangolo.com/tutorial/#ai-agent-skills
2. If the project already has FastAPI installed, check `.venv/lib/python*/site-packages/fastapi/.agents/skills/fastapi/SKILL.md` (version-matched, preferred for offline use).
3. Otherwise run `uvx library-skills` in the consumer project to install the official skill (compatible with OpenCode, Claude Code, Cursor, Copilot, Gemini CLI, Pi).
4. Load that vendor skill alongside the bundled `skills/python.md` + `skills/pydantic.md` above. Never write FastAPI conventions from memory when the vendor skill is available.

### 3. Drift rule (rescan wins)

If `AGENTS.md` disagrees with manifests, manifests win. Proceed on what manifests prove, then flag the drift to the user (e.g. "`AGENTS.md` says X but `pom.xml` shows Y"). Ask the user to run `/setup` to refresh. Never silently rewrite `AGENTS.md`.

### 4. Load narrowly

- Read at most 2–3 matching guides plus the FastAPI vendor skill when applicable. NEVER sweep the whole `skills/` directory.
- Multi-stack projects (e.g. Java backend + Python tooling): read one guide set per detected stack.
- No match: proceed without a guide and say so. Do not invent conventions.

### 5. Apply and report

Follow the loaded guide(s) for idioms, layout, and pitfalls. End with one line stating which guide(s) were loaded (e.g. "Loaded tech-skills: python + pydantic + vendor fastapi skill").

## Adding a new technology

Copy [skills/_TEMPLATE.md](skills/_TEMPLATE.md) to `skills/<tech-id>.md`, fill every section, add one row to the table above. Keep guide IDs kebab-case (`^[a-z0-9]+(-[a-z0-9]+)*$`). If the technology ships a version-matched vendor skill (like FastAPI), do not create a bundled guide — point the table row at the vendor install instead.

## Self-check before finishing

- [ ] Stack detected from manifests, not assumed from `AGENTS.md` alone.
- [ ] Only applicable `skills/*.md` files read; irrelevant ones untouched (plus vendor skill when the table calls for it).
- [ ] Drift between `AGENTS.md` and manifests flagged if found.
- [ ] Loaded guides named in the final report.
