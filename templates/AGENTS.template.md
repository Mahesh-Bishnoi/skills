# <project-name>

> Template: copy of `templates/AGENTS.template.md` from the skills repo checkout
> (resolved at `/setup` runtime — never a hardcoded path).
> Universal workflow guidance (skills, code, testing, tools) comes from the global `~/.config/opencode/AGENTS.md` — don't duplicate it here.
> Keep only portable essentials in this file so teammates get them without your global setup.
> Fill every `<PLACEHOLDER>`, then delete this notice.

## Architecture

- Stack: `<language, framework, package manager>`
- Entrypoints: `<real entry files, e.g. src/main.ts, not guesses>`
- Layout: `<one line per major directory and what owns it>`

## Commands

```sh
<setup: e.g. bun install>
<dev server: e.g. bun run dev>
<verify: e.g. bun run lint && bun run typecheck && bun run test>
```

- Focused checks: `<single test / single package command, e.g. bun test path/to/file>`
- Order matters: `<e.g. lint -> typecheck -> test, or "any order">`

## Testing quirks

- `<fixtures, required services, integration-test prerequisites, flaky/expensive suites — or "none">`

## Skills in use

- Wired project-locally via `/setup`: this project's `.opencode/opencode.jsonc` `skills` entry points at the skills checkout's `skills/` subdirectory (`<checkout>/skills`, not the checkout root), so library skills advertise only here. Each teammate runs `/setup` once for their own checkout path; never commit a personal checkout path.
- Optional tooling via `/setup` (diagrams, browser automation, design taste, code graph): installed project-local into `.opencode/skills/` so it advertises only here. Record chosen tools + scope below.
- Pinned copies (only if some skill must ship with this repo): `<none | .opencode/skills/<id>-pinned/ + why — use a different ID, explicit skills entries outrank .opencode/skills on duplicates>`
- Always-load rules for this project: `<none | e.g. always load <id> when touching <area>>`
