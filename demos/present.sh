#!/usr/bin/env bash
# present.sh — WarGames-themed interactive demo runner for the Secret Manager class.
#
#   ./demos/present.sh             # step SLIDE by slide; type 'pencil'+ENTER to run each
#   GO_WORD= ./demos/present.sh    # advance with a bare ENTER instead
#   TYPE_SPEED=0 ./demos/present.sh    # no typewriter effect (instant)
#   STEP_PAUSE=0 ./demos/present.sh    # no pause between commands within a slide
#   START=13 ./demos/present.sh     # jump straight to SLIDE 13 (skip everything before)
#   CLEAR_SCREEN=0 ./demos/present.sh  # keep scrollback (default clears screen per slide)
#   INTRO=0 ./demos/present.sh         # skip the WarGames dial-up cold open
#
# Slide numbers below match the LIVE Google Slides deck (pricing moved to slide 5,
# so every content slide from "core concepts" on is +1 vs the markdown source).
#
# Model: type the go-word 'pencil' ONCE at the logon screen to "log on" (pure
# theatre — the password David reads off the school desk). After that, a bare
# ENTER advances. One advance = one whole SLIDE's demo: EVERY command for that
# slide types itself out, executes live, and prints its output automatically —
# no typing between commands. When the slide's demo is done it waits again; ENTER
# advances to the NEXT slide's demo.
# On each 'pencil' the screen is wiped first, so only the current slide's demo is
# on screen (its banner stays pinned at the top). Set CLEAR_SCREEN=0 to keep the
# scrollback. Each command is tagged with its slide number so you never lose your place.
# Ctrl-C to bail.
#
# NOTE: intentionally NOT `set -e` — some demos fail on purpose (denied access).
set -uo pipefail
source "$(dirname "$0")/00-env.sh" >/dev/null
STATE="$(dirname "$0")/../terraform/terraform.tfstate"

# ── theme ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  GREEN=$(tput setaf 2); CYAN=$(tput setaf 6); YELLOW=$(tput setaf 3)
  RED=$(tput setaf 1); MAGENTA=$(tput setaf 5)
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; CYAN=""; YELLOW=""; RED=""; MAGENTA=""
fi
trap 'printf "%s" "$RESET"' EXIT
TYPE_SPEED="${TYPE_SPEED:-0.010}"   # seconds/char while "typing" a command; 0 disables
STEP_PAUSE="${STEP_PAUSE:-0.4}"     # seconds to breathe between commands within a slide
CLEAR_SCREEN="${CLEAR_SCREEN:-1}"   # 1 = wipe the screen at each slide so ONLY its demo shows; 0 = keep scrollback
INTRO="${INTRO:-1}"                 # 1 = play the WOPR dial-up cold open (WarGames first contact); 0 = skip to console
# 'pencil' = the password David finds written on the school desk to hack in
# (WarGames). Fittingly, a written-down password — the exact anti-pattern this
# talk warns against. Override: GO_WORD=foo, or GO_WORD= for bare ENTER.
GO_WORD="${GO_WORD-pencil}"
START="${START:-1}"; CURRENT_SLIDE=0
UNLOCKED=0   # flips to 1 after the go-word is typed ONCE (the theatrical "logon"); then ⏎ advances

typeit() { # type a string like a human
  local s="$1" i
  [ "$TYPE_SPEED" = "0" ] && { printf '%s' "$s"; return; }
  for (( i=0; i<${#s}; i++ )); do printf '%s' "${s:$i:1}"; sleep "$TYPE_SPEED"; done
}
wait_go() {
  # Type the go-word ONCE to "log on"; after that (UNLOCKED) a bare ⏎ advances.
  if [ -z "$GO_WORD" ] || [ "$UNLOCKED" = "1" ]; then printf " ${DIM}(⏎)${RESET}"; read -r _
  else local g=""; while [ "$g" != "$GO_WORD" ]; do printf " ${DIM}(type '%s'+⏎ to log on)${RESET} " "$GO_WORD"; read -r g; done; UNLOCKED=1; fi
}

# ── COLD OPEN: David war-dials WOPR + the backdoor logon (WarGames, 1983) ─────
# Pure theatre before the console. The backdoor password is JOSHUA — a written-
# down name, the exact anti-pattern this whole talk is about (cf. the demo secret
# '$BACKDOOR_SECRET'). INTRO=0 skips it for quick rehearsals.
boot_sequence() {
  [ "$INTRO" = "0" ] && return 0
  clear
  printf "\n${DIM}   IMSAI 8080  ·  300/1200 baud  ·  war-dialer online${RESET}\n\n"; sleep 0.4
  printf "${DIM}   "; typeit "ATDT 311-555-2368"; printf "${RESET}\n"; sleep 0.5
  printf "${DIM}   DIALING . . .${RESET}\n"; sleep 0.7
  printf "${DIM}   CARRIER DETECTED${RESET}\n"; sleep 0.3
  printf "${GREEN}   CONNECT 1200${RESET}\n\n"; sleep 0.6
  # First attempt — guess the professor's own name. DENIED. (the "obvious" secret fails.)
  printf "${GREEN}${BOLD}   LOGON: ${RESET}${GREEN}"; sleep 0.5; typeit "FALKEN"; printf "${RESET}\n\n"; sleep 0.7
  printf "${RED}${BOLD}   IDENTIFICATION NOT RECOGNIZED BY SYSTEM.${RESET}\n"; sleep 0.6
  printf "${RED}   --CONNECTION TERMINATED--${RESET}\n\n"; sleep 1.1
  # Redial and try the backdoor: JOSHUA, the dead son's name left in the code.
  printf "${DIM}   REDIALING . . .${RESET}\n"; sleep 0.6
  printf "${GREEN}   CONNECT 1200${RESET}\n\n"; sleep 0.5
  printf "${GREEN}${BOLD}   LOGON: ${RESET}${GREEN}"; sleep 0.5; typeit "JOSHUA"; printf "${RESET}\n\n"; sleep 0.7
  printf "${GREEN}${BOLD}   GREETINGS PROFESSOR FALKEN.${RESET}\n\n"; sleep 0.9
  printf "${DIM}   LIST GAMES${RESET}\n"; sleep 0.3
  local g
  for g in "FALKEN'S MAZE" "BLACK JACK" "GIN RUMMY" "HEARTS" "BRIDGE" \
           "CHECKERS" "CHESS" "POKER" "FIGHTER COMBAT" "GUERRILLA ENGAGEMENT" \
           "DESERT WARFARE" "AIR-TO-GROUND ACTIONS" \
           "THEATERWIDE TACTICAL WARFARE" \
           "THEATERWIDE BIOTOXIC AND CHEMICAL WARFARE"; do
    printf "${GREEN}      %s${RESET}\n" "$g"; sleep 0.06
  done
  printf "\n${YELLOW}${BOLD}      GLOBAL THERMONUCLEAR WAR${RESET}\n\n"; sleep 1.0
  printf "${DIM}   ...booting WOPR console...${RESET}\n"; sleep 0.9
}

# slide N "Title" — banner + label + ONE wait for the go-word. Everything after
# it (until the next `slide`) belongs to slide N and auto-runs on that one go-word.
slide() {
  CURRENT_SLIDE="$1"; shift
  local title="$*"
  printf "\n${MAGENTA}${BOLD}━━━ SLIDE %s ━━━${RESET} ${MAGENTA}%s${RESET}\n" "$CURRENT_SLIDE" "$title"
  [ "$CURRENT_SLIDE" -lt "$START" ] && return 0
  printf "${DIM}   run slide %s's demo${RESET}" "$CURRENT_SLIDE"; wait_go
  # wipe the previous slide's output so only THIS slide's demo is on screen,
  # then reprint the banner as a header so the presenter keeps their place.
  if [ "$CLEAR_SCREEN" != "0" ]; then
    clear
    printf "${MAGENTA}${BOLD}━━━ SLIDE %s ━━━${RESET} ${MAGENTA}%s${RESET}\n" "$CURRENT_SLIDE" "$title"
  else
    printf "\n"
  fi
}
# narration line (no wait)
say() { [ "$CURRENT_SLIDE" -lt "$START" ] && return 0; printf "\n${DIM}# %s${RESET}\n" "$*"; }
# run a single command: type it, execute it, show output — NO wait (auto within a slide)
run() {
  [ "$CURRENT_SLIDE" -lt "$START" ] && return 0
  printf "\n${CYAN}${BOLD}WOPR>${RESET} "; typeit "${GREEN}${1}${RESET}"; printf "\n"
  eval "$1"; printf "${DIM}─── slide %s ───${RESET}\n" "$CURRENT_SLIDE"
  [ "$STEP_PAUSE" = "0" ] || sleep "$STEP_PAUSE"
}

boot_sequence
clear
cat <<BANNER
${GREEN}${BOLD}
        W O P R  —  War Operation Plan Response
        GCP Secret Manager · live demo console

        SHALL WE PLAY A GAME?
${RESET}${YELLOW}   LOGON: the password is written on the desk...${RESET}
${DIM}   project: ${PROJECT_ID}   |   type '${GO_WORD:-⏎}' once to log on, then ⏎ advances each slide   ·   Ctrl-C to abort${RESET}
BANNER
wait_go

# ── SLIDE 3 · WHY ────────────────────────────────────────────────────────────
slide 3 "Why Secret Manager — secrets are governed objects, never bare values"
run 'gcloud secrets list --filter="name:wargames" --format="table(name.basename(), createTime.date())"'

# ── SLIDE 6 · CONCEPTS: secret vs versions ───────────────────────────────────
slide 6 "Core concepts — Secret vs. Version (it's just Git; 'latest'=HEAD)"
run 'gcloud secrets versions list "$LAUNCH_SECRET" --format="table(name, state, createTime.date())"'
run 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo'

# ── SLIDE 7 · CONCEPTS: replication ──────────────────────────────────────────
slide 7 "Replication — automatic vs user-managed (CMEK requires user-managed)"
run 'gcloud secrets describe "$WARPLAN_SECRET" --format="yaml(replication)"'

# ── SLIDE 8 · DEPLOY AS CODE ─────────────────────────────────────────────────
slide 8 "Deploy as IaC — the value is NOT in Terraform state (on purpose)"
run 'grep -c "CPE1704TKS\|DL6913THX" "$STATE"; echo "   ^ matches in terraform.tfstate (want 0)"'
run 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo "   ^ value lives in the service, added via CLI"'

# ── SLIDE 9 · CLI: add + read ────────────────────────────────────────────────
slide 9 "CLI — add a value via stdin (never hits ps/history/logs), then read it"
run 'printf "NEW-LAUNCH-CODE-%s" "$(date +%H%M%S)" | gcloud secrets versions add "$LAUNCH_SECRET" --data-file=-'
run 'echo -n "latest -> "; gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo'

# ── SLIDE 10 · CLI: immutable + safe teardown ────────────────────────────────
slide 10 "CLI — immutable versions; disable is REVERSIBLE (destroy is not)"
say "Watch the newest version go dark, then bring it back — no harm done."
run 'V=$(gcloud secrets versions list "$LAUNCH_SECRET" --filter="state=enabled" --format="value(name)" --sort-by=~name --limit=1); echo "newest version = $V"'
run 'gcloud secrets versions disable "$V" --secret="$LAUNCH_SECRET"'
run 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET" 2>&1 | grep -o "FAILED_PRECONDITION.*DISABLED state." || true'
run 'gcloud secrets versions enable "$V" --secret="$LAUNCH_SECRET"; echo "restored"'

# ── SLIDE 11 · IAM: least privilege ──────────────────────────────────────────
slide 11 "IAM — least privilege, scoped to the secret (not the project)"
run 'gcloud secrets get-iam-policy "$LAUNCH_SECRET" --format="table(bindings.role, bindings.members)"'

# ── SLIDE 12 · IAM: become WOPR ──────────────────────────────────────────────
slide 12 "Prove the boundary — become WOPR (impersonation)"
say "WOPR reads its OWN secret (granted):"
run 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET" --impersonate-service-account="$WOPR_SA" 2>/dev/null; echo'
say "WOPR reaches for a secret it was NOT granted (expect denial):"
run 'gcloud secrets versions access latest --secret="$WARPLAN_SECRET" --impersonate-service-account="$WOPR_SA" 2>&1 | grep -o "PERMISSION_DENIED.*denied" | head -1 || true'

# ── SLIDE 13 · SECURITY: encryption / CMEK ───────────────────────────────────
slide 13 "Encryption — where Google-managed keys stop and CMEK starts"
say "Our CMEK key is used only by the Secret Manager service agent:"
run 'gcloud kms keys get-iam-policy "$PREFIX-key" --keyring="$PREFIX-keyring" --location="$REGION" --format="table(bindings.role, bindings.members)"'

# ── SLIDE 14 · SECURITY: DEFCON containment ladder ───────────────────────────
slide 14 "Containment ladder — DEFCON for a compromised secret"
say "DEFCON 4 — disable the VERSION: instant, reversible, your FIRST move (true break-glass = DEFCON 1 destroy). Watch the war plan go dark:"
run 'gcloud secrets versions disable 1 --secret="$WARPLAN_SECRET"'
run 'gcloud secrets versions access latest --secret="$WARPLAN_SECRET" 2>&1 | grep -o "FAILED_PRECONDITION.*DISABLED state." || true'
run 'gcloud secrets versions enable 1 --secret="$WARPLAN_SECRET"; echo "war plan restored"'

# ── SLIDE 15 · SECURITY: audit ───────────────────────────────────────────────
slide 15 "Every access is audited — attributed by identity"
run 'gcloud logging read '"'"'protoPayload.serviceName="secretmanager.googleapis.com" AND protoPayload.methodName:"AccessSecretVersion"'"'"' --project="$PROJECT_ID" --freshness=1h --limit=4 --format="value(timestamp.date(%H:%M:%S), protoPayload.authenticationInfo.principalEmail)"'

# ── SLIDE 16 · ROTATION: notify ──────────────────────────────────────────────
slide 16 "Rotation — Secret Manager notifies (Pub/Sub); YOU rotate"
run 'gcloud secrets describe "$BACKDOOR_SECRET" --format="yaml(rotation, topics)"'

# ── SLIDE 17 · ROTATION: zero-downtime cutover ───────────────────────────────
slide 17 "Zero-downtime cutover — add a version, 'latest' moves, old drains"
say "Add a version; 'latest' moves; old stays enabled (drain overlap):"
run 'echo -n "before -> "; gcloud secrets versions access latest --secret="$BACKDOOR_SECRET"; echo'
run 'printf "joshua-rotated-%s" "$(date +%H%M%S)" | gcloud secrets versions add "$BACKDOOR_SECRET" --data-file=-'
run 'echo -n "after  -> "; gcloud secrets versions access latest --secret="$BACKDOOR_SECRET"; echo'
run 'gcloud secrets versions list "$BACKDOOR_SECRET" --filter="state=enabled" --format="table(name, state)"'

# ── SLIDE 18 · CONSUMING ─────────────────────────────────────────────────────
slide 18 "Consuming — what the client library does under the hood (REST + ADC)"
run 'TOKEN=$(gcloud auth print-access-token); curl -s -H "Authorization: Bearer $TOKEN" "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$LAUNCH_SECRET/versions/latest:access" | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(\"decoded secret:\", base64.b64decode(d[\"payload\"][\"data\"]).decode())"'

printf "\n${GREEN}${BOLD}A STRANGE GAME. THE ONLY WINNING MOVE IS NOT TO PLAY.${RESET}\n"
printf "${DIM}Demo complete. WOPR out.${RESET}\n\n"
