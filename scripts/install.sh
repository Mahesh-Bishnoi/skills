#!/usr/bin/env bash
# New-machine setup for the skills library. Clone anywhere, run this, done.
# Idempotent: safe to re-run after `git pull`.
set -euo pipefail

CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
JSONC="$CONFIG_DIR/opencode.jsonc"
AGENTS_DST="$CONFIG_DIR/AGENTS.md"
SETUP_DST="$CONFIG_DIR/commands/setup.md"

mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/commands"

# 1. Global `skills` entry pointing at this checkout (preserves other keys).
SKILLS_DIR="$CHECKOUT" JSONC_PATH="$JSONC" python3 - <<'EOF'
import json, os, sys

path = os.environ["JSONC_PATH"]
checkout = os.environ["SKILLS_DIR"]
os.makedirs(os.path.dirname(path), exist_ok=True)

raw = ""
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        raw = f.read()

data = {}
if raw.strip():
    # Strip // and /* */ comments so stdlib json can parse JSONC.
    # String-aware: comment markers inside "..." are data, not comments.
    def strip_jsonc(text):
        out = []
        i, n = 0, len(text)
        in_str = False
        esc = False
        while i < n:
            c = text[i]
            nxt = text[i + 1] if i + 1 < n else ""
            if in_str:
                out.append(c)
                if esc:
                    esc = False
                elif c == "\\":
                    esc = True
                elif c == '"':
                    in_str = False
                i += 1
            elif c == '"':
                in_str = True
                out.append(c)
                i += 1
            elif c == "/" and nxt == "/":
                while i < n and text[i] != "\n":
                    i += 1
            elif c == "/" and nxt == "*":
                i += 2
                while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                    i += 1
                i += 2
            else:
                out.append(c)
                i += 1
        return "".join(out)
    try:
        data = json.loads(strip_jsonc(raw))
    except json.JSONDecodeError as e:
        print(f"ERROR: {path} is not parseable JSON/JSONC: {e}", file=sys.stderr)
        print("Fix or move it aside, then re-run this script.", file=sys.stderr)
        sys.exit(1)

skills = data.get("skills", [])
if not isinstance(skills, list):
    print(f"ERROR: {path} has a non-list `skills` key; fix it manually.", file=sys.stderr)
    sys.exit(1)

def normalize(entry):
    # Match existing entries that point here in another spelling:
    # ~/..., $HOME/..., or relative paths resolve against $HOME.
    if not isinstance(entry, str):
        return entry
    expanded = os.path.expanduser(os.path.expandvars(entry))
    if not os.path.isabs(expanded):
        expanded = os.path.normpath(os.path.join(os.path.expanduser("~"), expanded))
    return os.path.normpath(expanded)

if normalize(checkout) not in [normalize(e) for e in skills]:
    skills.append(checkout)
    data["skills"] = skills
    changed = True
else:
    changed = False

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(("updated " if changed else "ok ") + path)
EOF

# 2. Global AGENTS.md: copy on fresh machines; never blind-overwrite.
if [ ! -f "$AGENTS_DST" ]; then
  cp "$CHECKOUT/global-AGENTS.md" "$AGENTS_DST"
  echo "installed $AGENTS_DST"
else
  echo "kept $AGENTS_DST (exists) — ask the agent to merge global-AGENTS.md (repo wins on conflict, local-only content preserved)"
fi

# 3. /setup wizard command.
if ! cmp -s "$CHECKOUT/commands/setup.md" "$SETUP_DST" 2>/dev/null; then
  cp "$CHECKOUT/commands/setup.md" "$SETUP_DST"
  echo "installed $SETUP_DST"
else
  echo "ok $SETUP_DST"
fi

# 4. Verify.
echo "checkout: $CHECKOUT"
echo "skills: $(ls -d "$CHECKOUT"/*/SKILL.md 2>/dev/null | wc -l) skills"
command -v python3 >/dev/null && python3 "$CHECKOUT/scripts/lint-skills.py" | tail -1
echo "Done. Restart the agent and confirm with the skill list; per project, cd there and run /setup."
