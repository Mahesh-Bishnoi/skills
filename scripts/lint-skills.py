#!/usr/bin/env python3
"""Lint skills in this repo. Stdlib only. Exit 1 on errors, 0 otherwise."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ID_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
RESERVED_TOP = {"scripts", "templates", "setup", "commands", ".git", ".opencode", ".claude", ".agents"}
ALLOWED_ROOT_MD = {"README.md", "AGENTS.md", "CLAUDE.md", "global-AGENTS.md"}
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*(?:\n|$)", re.DOTALL)
# No native always/once-per-session skill flags exist in V2; those rules live
# in global-AGENTS.md. Reject lookalike keys so authors don't assume otherwise.
NON_NATIVE_KEYS = {
    "always",
    "always-load",
    "once-per-session",
    "once_per_session",
    "invocation",
    "auto-invoke",
    "autoload",
}
# Skills intentionally hidden from model discovery; they stop producing the
# hidden-skill warning but still count as hidden for handoff checks.
ALLOWED_HIDDEN_SKILLS = {"grill", "project-bootstrap"}
# Skills installed via /setup (not in this repo) — valid @refs after install.
ALLOWED_EXTERNAL_SKILLS = {
    "archify", "drawio-skill", "ui-ux-pro-max", "design-taste-frontend",
    "design-taste-frontend-v1", "graphify", "agent-browser", "browser-harness",
    "openwiki",
}
# Use-trigger wording required in descriptions (warn-only).
USE_TRIGGER_RE = re.compile(
    r"\b(use\s+(only\s+)?when|use\s+on\b|use\s+for\b|load\s+before\b)",
    re.IGNORECASE,
)
MAX_DESCRIPTION_CHARS = 300
# Reference-doc patterns checked like skill bodies (warn-only for new dirs).
ABS_PATH_PATTERNS = ("/home/", "/Users/", "](/)", "](/", "%HOME%")
AT_REF_RE = re.compile(r"(?<![\w/])@([a-z0-9]+(?:-[a-z0-9]+)*)(?!/)")
THE_SKILL_RE = re.compile(r"the `([A-Za-z0-9][A-Za-z0-9-]*)` skill")
FENCED_BLOCK_RE = re.compile(r"```.*?```", re.DOTALL)

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def parse_frontmatter(text: str) -> dict[str, str]:
    """Minimal frontmatter parse: top-level `key: value` lines only."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if not line.strip() or line.startswith((" ", "\t")) or ":" not in line:
            continue
        k, v = line.split(":", 1)
        out[k.strip()] = v.strip().strip("\"'")
    return out


def main() -> int:
    # 1. Stray root-level markdown (flat skill form not used here).
    for md in sorted(ROOT.glob("*.md")):
        if md.name not in ALLOWED_ROOT_MD:
            err(f"{md.name}: flat *.md skills not used here; use <skill-id>/SKILL.md/")

    # 2. Nested SKILL.md files (keep skills top-level so ID == dirname).
    nested = sorted(
        p for p in ROOT.rglob("SKILL.md") if p.parent.parent != ROOT and p.parent != ROOT
    )
    # rglob from ROOT includes <id>/SKILL.md (parent == ROOT/<id>, parent.parent == ROOT) — exclude those.
    for p in nested:
        rel = p.relative_to(ROOT)
        if ".git" in rel.parts:
            continue
        err(f"{rel}: nested SKILL.md not allowed; move to top-level <skill-id>/SKILL.md")

    # 3. SKILL.md directly under tooling dirs would still be discovered as a
    # skill (SKILL.md matches at any depth) while the skill loop below skips them.
    for reserved in sorted(RESERVED_TOP - {".git", ".opencode", ".claude", ".agents"}):
        if (ROOT / reserved / "SKILL.md").is_file():
            err(f"{reserved}/SKILL.md: tooling dir must not contain a skill; move to top-level <skill-id>/SKILL.md")

    # 3b. Setup wizard files (not skills, never advertised).
    if not (ROOT / "commands" / "setup.md").is_file():
        err("commands/setup.md: missing; the single /setup wizard command must exist")
    if not (ROOT / "setup" / "_index.md").is_file():
        err("setup/_index.md: missing; the /setup router index must exist")
    for p in sorted((ROOT / "setup").glob("*.md")) if (ROOT / "setup").is_dir() else []:
        if p.name == "SKILL.md":
            err(f"{p.relative_to(ROOT)}: setup/ must not contain SKILL.md (would advertise as a skill)")
    for p in sorted((ROOT / "commands").rglob("SKILL.md")) if (ROOT / "commands").is_dir() else []:
        err(f"{p.relative_to(ROOT)}: commands/ must not contain SKILL.md (would advertise as a skill)")

    skill_dirs = sorted(
        d
        for d in ROOT.iterdir()
        if d.is_dir() and d.name not in RESERVED_TOP and not d.name.startswith(".")
    )
    skill_ids = {d.name for d in skill_dirs if (d / "SKILL.md").is_file()}

    def _is_hidden(d: Path) -> bool:
        try:
            t = (d / "SKILL.md").read_text(encoding="utf-8")
        except OSError:
            return False
        return "opencode/autoinvoke: false" in t or "disable-model-invocation: true" in t

    hidden_ids = {d.name for d in skill_dirs if (d / "SKILL.md").is_file() and _is_hidden(d)}

    found_skill = False
    for d in skill_dirs:
        skill_file = d / "SKILL.md"
        if not skill_file.is_file():
            continue  # not a skill dir (e.g. tooling); ignore
        found_skill = True
        sid = d.name

        if len(sid) > 64:
            err(f"{sid}/SKILL.md: id longer than 64 chars")
        if not ID_RE.match(sid):
            err(f"{sid}/SKILL.md: id must match ^[a-z0-9]+(-[a-z0-9]+)*$ (got {sid!r})")

        try:
            text = skill_file.read_text(encoding="utf-8")
        except OSError as e:
            err(f"{sid}/SKILL.md: unreadable: {e}")
            continue

        fm = parse_frontmatter(text)
        if not fm:
            err(f"{sid}/SKILL.md: missing or unparsable frontmatter (need name + description)")
            continue
        if not fm.get("description", "").strip():
            err(f"{sid}/SKILL.md: missing non-empty `description` (skill won't be advertised)")
        if not fm.get("name", "").strip():
            err(f"{sid}/SKILL.md: missing `name`")
        elif fm["name"].strip() != sid:
            # OpenCode runtime treats `name` as display-only, but stricter
            # tooling (VSCode extension, Claude) requires name == directory.
            err(f"{sid}/SKILL.md: `name` must equal directory id {sid!r} (got {fm['name'].strip()!r})")
        for key in fm:
            if key.lower() in NON_NATIVE_KEYS:
                err(
                    f"{sid}/SKILL.md: non-native frontmatter key {key!r}; "
                    "V2 has no such flag — put always/once-per-session rules in global-AGENTS.md"
                )
        if "disable-model-invocation" in fm and fm["disable-model-invocation"] not in ("true", "false"):
            err(f"{sid}/SKILL.md: `disable-model-invocation` must be true or false")

        body = FRONTMATTER_RE.sub("", text, count=1)
        if "opencode/autoinvoke: false" in text or "disable-model-invocation: true" in text:
            if sid not in ALLOWED_HIDDEN_SKILLS:
                warn(f"{sid}/SKILL.md: skill is hidden from model discovery (autoinvoke disabled)")
        desc = fm.get("description", "").strip()
        if desc:
            if not USE_TRIGGER_RE.search(desc):
                warn(f"{sid}/SKILL.md: description lacks use-trigger wording (e.g. 'Use when ...')")
            if len(desc) > MAX_DESCRIPTION_CHARS:
                warn(f"{sid}/SKILL.md: description is {len(desc)} chars (keep under ~{MAX_DESCRIPTION_CHARS})")
        if "mcpServers" in text:
            err(f"{sid}/SKILL.md: `mcpServers` is Claude format; V2 uses `mcp.servers`")
        # Cross-skill references must resolve (warn-only). Strip fenced blocks
        # so code samples (JSDoc tags, npm scopes, payloads) don't false-positive.
        prose = FENCED_BLOCK_RE.sub("", body)
        for ref in sorted(set(AT_REF_RE.findall(prose))):
            if ref not in skill_ids and ref not in ALLOWED_EXTERNAL_SKILLS:
                warn(f"{sid}/SKILL.md: dangling @{ref} reference (no such skill dir)")
        for ref in sorted(set(THE_SKILL_RE.findall(body))):
            if ref not in skill_ids and ref not in ALLOWED_EXTERNAL_SKILLS:
                warn(f"{sid}/SKILL.md: dangling 'the {ref} skill' reference (no such skill dir)")
        for hid in sorted(hidden_ids):
            if re.search(rf"(?<![\w/])@{re.escape(hid)}\b", body) and not re.search(
                rf"ask the user to invoke\s+[`@]*{re.escape(hid)}", body, re.IGNORECASE
            ):
                warn(f"{sid}/SKILL.md: hands off to hidden skill @{hid} without asking the user to invoke it")
        # Canonical portable references (~/code/skills, ~/.config/) are allowed;
        # machine-specific absolute paths are not.
        for pat in ("/home/", "/Users/", "](/)", "](/", "%HOME%"):
            if pat in body:
                err(f"{sid}/SKILL.md: absolute/personal path reference {pat!r}; use paths relative to skill dir")
                break
        # Check relative markdown links resolve.
        for m in re.finditer(r"\[[^\]]*\]\(([^)#\s]+)\)", body):
            target = m.group(1).strip()
            if not target or target.startswith(("http://", "https://", "#", "mailto:")):
                continue
            if (d / target).exists():
                continue
            err(f"{sid}/SKILL.md: broken relative link {target!r}")

    if not found_skill:
        warn("no skills found yet (no <skill-id>/SKILL.md directories)")

    # Reference and wizard docs are not skills, but they get the same
    # portability checks as skill bodies (warn-only for these dirs).
    extra_docs: list[Path] = []
    for tooling in ("setup", "commands"):
        tooling_dir = ROOT / tooling
        if tooling_dir.is_dir():
            extra_docs.extend(sorted(tooling_dir.rglob("*.md")))
    for d in skill_dirs:
        ref_dir = d / "references"
        if ref_dir.is_dir():
            extra_docs.extend(sorted(ref_dir.rglob("*.md")))
    for p in extra_docs:
        if ".git" in p.parts:
            continue
        rel = p.relative_to(ROOT)
        try:
            doc = p.read_text(encoding="utf-8")
        except OSError:
            continue
        for pat in ABS_PATH_PATTERNS:
            if pat in doc:
                warn(f"{rel}: absolute/personal path reference {pat!r}; use paths relative to the doc")
                break
        if "mcpServers" in doc:
            err(f"{rel}: `mcpServers` is Claude format; V2 uses `mcp.servers`")
        for m in re.finditer(r"\[[^\]]*\]\(([^)#\s]+)\)", doc):
            target = m.group(1).strip()
            if not target or target.startswith(("http://", "https://", "#", "mailto:")):
                continue
            if (p.parent / target).exists():
                continue
            warn(f"{rel}: broken relative link {target!r}")

    for w in warnings:
        print(f"WARN: {w}")
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    print(f"{'FAIL' if errors else 'OK'}: {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
