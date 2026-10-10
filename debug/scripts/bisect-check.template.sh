#!/usr/bin/env bash
# Pass/fail check for `git bisect run`. Copy this OUTSIDE the repo first
# (e.g. a temp dir) so checking out old commits doesn't change or delete it.
#
#   cp bisect-check.template.sh "${TMPDIR:-/tmp}/bisect-check.sh"   # then edit it
#   git bisect start
#   git bisect bad HEAD
#   git bisect good <known-good-commit>
#   git bisect run bash "${TMPDIR:-/tmp}/bisect-check.sh"
#   git bisect log      # record the result
#   git bisect reset    # always finish with this
#
# Exit codes understood by git bisect:
#   0     this commit is GOOD (bug absent)
#   1     this commit is BAD  (bug present)
#   125   cannot test this commit (build broken for unrelated reasons) -> skip
# Anything else (e.g. 127, 128+) ABORTS the bisect, so map errors explicitly.

set -uo pipefail

# --- edit below ---------------------------------------------------------

# 1. Build / install. If this fails, the commit can't be tested: skip it.
npm ci --silent > /dev/null 2>&1 || exit 125
# npm run build > /dev/null 2>&1 || exit 125

# 2. Run the feedback loop. Check the EXACT symptom, not just the exit code,
#    so an unrelated failure isn't mistaken for the bug.
output="$(timeout 120 npx vitest run tests/orders.test.ts -t "total" 2>&1)"
status=$?

if [[ $status -eq 124 ]]; then
  exit 125                                   # timed out: can't judge, skip
fi
if grep -q "expected 30.3" <<<"$output"; then
  exit 1                                     # the bug's exact symptom: BAD
fi
if [[ $status -eq 0 ]]; then
  exit 0                                     # passed: GOOD
fi
exit 125                                     # failed some other way: skip

# --- edit above ---------------------------------------------------------
