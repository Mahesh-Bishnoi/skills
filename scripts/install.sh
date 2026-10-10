#!/usr/bin/env bash
# New-machine setup for the skills library. Clone anywhere, run this, done.
# Idempotent: safe to re-run after `git pull`.
set -euo pipefail

CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SOURCE="$CHECKOUT/skills"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
JSONC="$CONFIG_DIR/opencode.jsonc"
POINTER="$CONFIG_DIR/skills-repo.path"
AGENTS_DST="$CONFIG_DIR/AGENTS.md"
SETUP_DST="$CONFIG_DIR/commands/setup.md"

MODE="default"
for arg in "$@"; do
  case "$arg" in
    --global) MODE="global" ;;
    --remove-global) MODE="remove-global" ;;
    -h|--help)
      echo "Usage: install.sh [--global] [--remove-global]"
      echo "  default:        write pointer file, install AGENTS.md + /setup command; no global skills entry"
      echo "  --global:       also add this checkout's skills/ dir to the global skills array (advertises library in every project)"
      echo "  --remove-global: remove this checkout (root and skills/ dir) from the global skills array (per-project /setup wiring only)"
      exit 0
      ;;
    *) echo "Unknown arg: $arg (see --help)" >&2; exit 1 ;;
  esac
done

mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/commands"

# 1. Pointer file locating this checkout for /setup (never read by OpenCode, so it advertises nothing).
printf '%s\n' "$CHECKOUT" > "$POINTER"
echo "wrote $POINTER"

# 2. Global `skills` entry: opt-in only (--global) or removal (--remove-global).
#    Default installs stay per-project: /setup adds the checkout's skills/
#    dir to <project>/.opencode/opencode.jsonc, so the library advertises only there.
#    The skills source is <checkout>/skills (not the checkout root: the root
#    holds README/AGENTS/global-AGENTS.md, which OpenCode would advertise as
#    bogus flat-file skills).
if [ "$MODE" = "global" ]; then
SKILLS_DIR="$SKILLS_SOURCE" JSONC_PATH="$JSONC" python3 - <<'EOF'
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

# Migrate the legacy checkout-root entry (pre-skills/ layout advertised
# README/AGENTS/global-AGENTS as bogus skills): drop it, keep skills/ dir.
roots = [os.path.normpath(os.path.join(os.path.normpath(checkout), "..")), os.path.normpath(checkout)]
normed = [normalize(e) for e in skills]
skills = [e for e in skills if normalize(e) not in roots or normalize(e) == os.path.normpath(checkout)]
changed_migration = len(skills) != len(normed)
normed = [normalize(e) for e in skills]

if normalize(checkout) not in normed:
    skills.append(checkout)
    data["skills"] = skills
    changed = True
else:
    changed = False
changed = changed or changed_migration

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(("updated " if changed else "ok ") + path)
EOF
elif [ "$MODE" = "remove-global" ]; then
SKILLS_DIR="$SKILLS_SOURCE" CHECKOUT_ROOT="$CHECKOUT" JSONC_PATH="$JSONC" python3 - <<'EOF'
import json, os, sys

path = os.environ["JSONC_PATH"]
checkout = os.environ["SKILLS_DIR"]
legacy_root = os.environ.get("CHECKOUT_ROOT", "")

def normalize(entry):
    if not isinstance(entry, str):
        return entry
    expanded = os.path.expanduser(os.path.expandvars(entry))
    if not os.path.isabs(expanded):
        expanded = os.path.normpath(os.path.join(os.path.expanduser("~"), expanded))
    return os.path.normpath(expanded)

if not os.path.exists(path):
    print("ok " + path + " (no file, nothing to remove)")
    sys.exit(0)

with open(path, encoding="utf-8") as f:
    raw = f.read()

if not raw.strip():
    print("ok " + path + " (empty, nothing to remove)")
    sys.exit(0)

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
    sys.exit(1)

skills = data.get("skills", [])
if not isinstance(skills, list):
    print(f"ERROR: {path} has a non-list `skills` key; fix it manually.", file=sys.stderr)
    sys.exit(1)

target = normalize(checkout)
legacy = normalize(legacy_root) if legacy_root else None
targets = {target} | ({legacy} if legacy else set())
kept = [e for e in skills if normalize(e) not in targets]
if len(kept) == len(skills):
    print("ok " + path + " (entry not present)")
else:
    data["skills"] = kept
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("updated " + path + " (removed global skills entry)")
EOF
else
  echo "skipped global skills entry (per-project /setup wiring only; use --global to opt in, --remove-global to migrate)"
fi

# 3. Global AGENTS.md: copy on fresh machines; never blind-overwrite.
if [ ! -f "$AGENTS_DST" ]; then
  cp "$CHECKOUT/global-AGENTS.md" "$AGENTS_DST"
  echo "installed $AGENTS_DST"
else
  echo "kept $AGENTS_DST (exists) — ask the agent to merge global-AGENTS.md (repo wins on conflict, local-only content preserved)"
fi

# 4. /setup wizard command.
if ! cmp -s "$CHECKOUT/commands/setup.md" "$SETUP_DST" 2>/dev/null; then
  cp "$CHECKOUT/commands/setup.md" "$SETUP_DST"
  echo "installed $SETUP_DST"
else
  echo "ok $SETUP_DST"
fi

# 5. Verify.
echo "checkout: $CHECKOUT"
echo "pointer: $POINTER"
echo "skills source: $SKILLS_SOURCE"
echo "skills: $(ls -d "$SKILLS_SOURCE"/*/SKILL.md 2>/dev/null | wc -l) skills"
command -v python3 >/dev/null && python3 "$CHECKOUT/scripts/lint-skills.py" | tail -1
echo "Done. /setup stays global; library skills advertise only in projects where /setup ran. Per project, cd there and run /setup."
