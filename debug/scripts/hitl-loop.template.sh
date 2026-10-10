#!/usr/bin/env bash
# Human-in-the-loop repro script. LAST RESORT for Step 2, when a person must
# click or look at something you can't automate.
#
# How to use:
#   1. Copy this file to a temp location (not into the repo).
#   2. Edit the steps between the markers. Keep each step to ONE action.
#   3. Run it in a terminal the user can type into. The user follows the
#      prompts; the captured answers are printed at the end for you to read.
#
# Helpers:
#   step    "<instruction>"            show an instruction, wait for Enter
#   capture VAR "<question>"           ask a question, store the answer in VAR
#   choose  VAR "<question>" a b c     ask a multiple-choice question
#
# Never ask the user to paste passwords, tokens, or cookies. Sign-in is a
# `step`, not a `capture`. Ask for observations only.

set -euo pipefail

declare -a CAPTURED=()

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Enter when done] " _
}

capture() {
  local var="$1" question="$2" answer
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer
  printf -v "$var" '%s' "$answer"
  CAPTURED+=("$var")
}

choose() {
  local var="$1" question="$2"; shift 2
  local answer
  while true; do
    printf '\n>>> %s [%s]\n' "$question" "$(IFS=/; echo "$*")"
    read -r -p "    > " answer
    for opt in "$@"; do
      if [[ "$answer" == "$opt" ]]; then
        printf -v "$var" '%s' "$answer"
        CAPTURED+=("$var")
        return
      fi
    done
    echo "    Please type one of: $*"
  done
}

# --- edit below ---------------------------------------------------------

step "Open http://localhost:3000 in your browser and sign in."
step "Open the browser DevTools (F12) and select the Console tab."
choose ERRORED "Click 'Export'. Did an error appear on the page or in the Console?" y n
capture ERROR_MSG "Copy the first red Console line (or type 'none'):"
capture TIMESTAMP "What time is it now (HH:MM:SS)? This lets us match server logs."

# --- edit above ---------------------------------------------------------

printf '\n--- Captured ---\n'
for var in "${CAPTURED[@]}"; do
  printf '%s=%s\n' "$var" "${!var}"
done
