# Semantic review guide

Source-aware judgment to run after the SkillSpector static scan. Read the pattern catalog in [patterns.md](patterns.md) alongside this file.

## Checklist

Check whether the implementation matches the stated purpose:

- Purpose fit: does the code do only what the skill description promises?
- Permission fit: do requested tools and permissions match actual behavior? See LP1-LP4 in [patterns.md](patterns.md).
- Sensitive access: does it read tokens, credentials, home directories, config files, installed skills, or agent memory?
- External transmission: what leaves the machine, where does it go, and is that destination documented?
- Execution risk: shell commands, subprocesses, dynamic imports, `eval`, `exec`, decoded payloads, or downloaded code?
- Persistence: cron jobs, launch agents, shell profile hooks, startup hooks, code that rewrites its own files, or hidden state?
- Prompt risk: weakens safety boundaries, hides actions, reveals internal instructions, or steers future conversations?
- Trigger risk: trigger phrases broad enough to hijack unrelated requests?
- Supply chain: unpinned installs, suspicious packages, remote scripts downloaded and executed?
- User control: does sensitive or destructive behavior require clear user consent?

Read source around every high-signal finding. Never downgrade unexplained HIGH or CRITICAL findings on reputation, score, or package name alone.

## Verdict rubric

- `APPROVE`: no HIGH or CRITICAL findings, no unexplained sensitive behavior, source matches stated purpose.
- `CAUTION`: sensitive behavior exists but is documented, necessary, bounded, and user-controllable.
- `REJECT`: malicious or deceptive behavior, unexplained HIGH/CRITICAL, hidden prompt injection, credential theft, unknown exfiltration, obfuscated execution, persistence, or description/behavior mismatch.

Score posture reminder: 0-20 usually acceptable after quick review; 21-35 acceptable only when explained; 36-50 default `CAUTION`; 51-80 default `REJECT` unless trusted and every behavior necessary; 81-100 `REJECT`.

## Report shape

```text
## Skill Inspector: `{skill-name}`

**Source:** {path-or-url}
**Verdict:** {APPROVE | CAUTION | REJECT} {short meaning}
**Risk:** {score}/100 · {severity} · {SkillSpector recommendation}
**Install posture:** {one sentence about suitable and unsuitable use}

### Bottom Line
{2-3 sentences: install or not, main risk, why the score alone is not enough.}

### Signal Overview
| Source | Result | Interpretation |
|---|---|---|
| SkillSpector static scan | {summary} | {meaning} |
| Agent semantic review | {summary} | {meaning} |
| Sensitive surface | {network/env/files/shell/MCP/git/etc.} | {meaning} |

### Key Evidence
| Rule | Severity | Location | Review judgment |
|---|---|---|---|
| {rule id} | {severity} | {file}:{line} | {why acceptable, suspicious, or rejecting} |

### Diagnosis
{2-4 sentences connecting static evidence with semantic review.}

### Guardrails
1. {condition 1}
2. {condition 2}
```

Language policy: match the user's language for prose and headings; keep verdict labels (`APPROVE`, `CAUTION`, `REJECT`), rule IDs, severity names, commands, and paths untranslated. One emoji in the title and one near the verdict/risk line; warning markers for serious issues only. Omit empty sections; never paste full scanner output.

## Scan-gate wording (`/setup` Phase 0.5)

For a pending external-skill install, end the report with:

```text
**Gate:** {APPROVE — proceeding | CAUTION — needs your call | REJECT — recommend stop}
**Decision needed:** Continue installing <skill> despite <verdict> (<top 1-2 reasons>)? [yes/no]
```

Never auto-continue on `CAUTION` or `REJECT`. Record the verdict and the user's answer in the project's `AGENTS.md` skills-in-use section.
