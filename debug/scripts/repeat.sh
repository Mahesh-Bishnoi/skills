#!/usr/bin/env bash
# Run a command N times and report how often it fails.
# Use it to measure a flaky bug's failure rate, and to prove a fix (0 failures).
#
# Usage:
#   bash repeat.sh <N> [-j <parallel>] -- <command> [args...]
#
# Examples:
#   bash repeat.sh 50 -- pytest tests/test_orders.py::test_save -x -q
#   bash repeat.sh 200 -j 8 -- npm test -- -t "saves order"
#
# Output of the first failing run is kept in a temp file so you can read it.
# Exit code: 0 if every run passed, 1 if any run failed.

set -uo pipefail

usage() { sed -n '2,13p' "$0" >&2; exit 2; }

[[ $# -ge 3 ]] || usage
runs="$1"; shift
parallel=1
if [[ "$1" == "-j" ]]; then parallel="$2"; shift 2; fi
[[ "${1:-}" == "--" ]] || usage
shift
[[ "$runs" =~ ^[0-9]+$ && "$parallel" =~ ^[0-9]+$ && $# -gt 0 ]] || usage

workdir="$(mktemp -d "${TMPDIR:-/tmp}/repeat.XXXXXX")"

run_one() {
  local i="$1"; shift
  if "$@" > "$workdir/run-$i.log" 2>&1; then
    rm -f "$workdir/run-$i.log"
    echo pass > "$workdir/status-$i"
  else
    echo fail > "$workdir/status-$i"
  fi
}

start=$(date +%s)
for ((i = 1; i <= runs; i++)); do
  run_one "$i" "$@" &
  while (( $(jobs -rp | wc -l) >= parallel )); do wait -n; done
done
wait
elapsed=$(( $(date +%s) - start ))

fails=$(grep -l fail "$workdir"/status-* 2>/dev/null | wc -l)
passes=$(( runs - fails ))
printf 'runs=%d pass=%d fail=%d fail_rate=%d%% elapsed=%ds\n' \
  "$runs" "$passes" "$fails" $(( fails * 100 / runs )) "$elapsed"

if (( fails > 0 )); then
  for ((i = 1; i <= runs; i++)); do
    [[ -f "$workdir/run-$i.log" ]] && { first="$workdir/run-$i.log"; break; }
  done
  echo "first failing run log: $first"
  echo "--- last 30 lines ---"
  tail -n 30 "$first"
  exit 1
fi
rm -rf "$workdir"
