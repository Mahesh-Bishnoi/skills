# Global instructions

Source of truth: `global-AGENTS.md` in the skills repo (installed by `scripts/install.sh`). Installing means merging (repo wins on conflict, local-only content preserved) with user confirmation — never blind overwrite. See setup step 2 in the repo `AGENTS.md`. Project-specific guidance lives in each repo's own `AGENTS.md`; when the two conflict, the project file wins for that repo.

## Skills

- Skills live in the skills-repo checkout under `skills/`, wired per project by `/setup` via that project's `.opencode/opencode.jsonc` `skills` entry pointing at `<checkout>/skills` — library skills advertise only in projects where `/setup` ran. Never wire the bare checkout root: OpenCode advertises root-level `*.md` (README/AGENTS/global-AGENTS) as bogus skills. Each skill's frontmatter `description` is the source of truth for *when* to invoke it. `/setup` itself is a global command and stays visible everywhere; the pointer file at `~/.config/opencode/skills-repo.path` only locates the checkout and advertises nothing.
- Before starting a task, scan the advertised skill list. When a description matches the task, load it with the `skill` tool (or honor the user's `@<skill-id>` mention) and follow it.
- Do not guess a skill's content from its name — load the body first.
- User-only skills (`opencode/autoinvoke: false`) are never loaded uninvited; load them only on explicit user request.
- Project setup runs via the `/setup` slash command, not via skills. Phase 0 scaffolds/refreshes the project's `AGENTS.md`; Phase 1 installs optional tooling (diagrams, browser automation, design taste, code graph). Setup docs live in `setup/` inside the checkout as plain references and are never advertised. Installed tooling defaults to project-local (`.opencode/skills`, OpenCode-only) so it advertises only in the project that uses it; global installs are opt-in only. `.agents/skills` is the universal target (also discovered by OpenCode) for users working across agents; `/setup` asks which target to use.
- `security-audit` full-audit mode is the only workflow with sandbox + coverage-ledger + critic ceremony; no other skill requires it.
- Load `skill-inspector` before installing or keeping third-party agent skills.
- Prefer the project-wired library skill over copying it into a project. Copy into `<project>/.opencode/skills/` only when the skill must ship with that repo (team/CI); use a different ID for the copy (e.g. `<id>-pinned`) because explicit `skills` config entries outrank `.opencode/skills` on duplicate IDs in V2. Pinned copies are the team-sharing mechanism; the project-local `skills` entry pointing at the checkout's `skills/` dir is machine-local and never committed — each teammate runs `/setup` once. This is the default for anything `/setup` installs.

## Code

- Load the `clean-code` skill before any non-trivial code change (new feature, refactor, bug fix spanning more than a few lines, or code review).
- Load the `hardening` skill when the change touches auth, sessions, user input, secrets, file uploads, server-side fetches, dependencies, personal data, or LLM output.
- Read the project's `AGENTS.md` for stack, entrypoints, and conventions before writing code. If it names a formatter/linter, run it after edits.
- Edit existing files over creating new ones. Match surrounding style. No speculative abstractions.
- Never commit secrets. Use `{env:VAR}`-style references in config, never literal keys.

## Testing

- Run the project's documented verification step (see its `AGENTS.md`) after behavior changes. No documented step means: run the narrowest test/build that covers the change, and say what you ran.
- Verify your own work by execution wherever reasonable — reproduce first for bugs, confirm output after.
- Load debug for any bug, error, or failing test.

## Tools

- Prefer dedicated file tools over shell redirection for reads/edits. Reserve shell for actual commands.
- Don't run network-wide or destructive commands (`rm -rf`, mass rewrites) without explicit approval.
- Report what you did concisely: files changed, checks run, outcome.
