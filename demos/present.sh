#!/usr/bin/env bash
# present.sh — WarGames-themed interactive demo runner for the Secret Manager class.
#
#   ./demos/present.sh            # step through with ENTER
#   TYPE_SPEED=0 ./demos/present.sh   # no typewriter effect (instant)
#   GO_WORD=launch ./demos/present.sh # require typing 'launch'+ENTER instead of bare ENTER
#   START=5 ./demos/present.sh     # jump straight to section 5 (IAM)
#
# Each step: the command is "typed" at a WOPR> prompt, then waits for you.
# Hit ENTER (or type your GO_WORD) to execute it live. Ctrl-C to bail.
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
TYPE_SPEED="${TYPE_SPEED:-0.010}"   # seconds/char; 0 disables
GO_WORD="${GO_WORD:-}"              # empty = bare ENTER; else must type this word
START="${START:-1}"; SECTION=0

typeit() { # type a string like a human
  local s="$1" i
  [ "$TYPE_SPEED" = "0" ] && { printf '%s' "$s"; return; }
  for (( i=0; i<${#s}; i++ )); do printf '%s' "${s:$i:1}"; sleep "$TYPE_SPEED"; done
}
wait_go() {
  if [ -z "$GO_WORD" ]; then printf " ${DIM}(⏎)${RESET}"; read -r _
  else local g=""; while [ "$g" != "$GO_WORD" ]; do printf " ${DIM}(type '%s'+⏎)${RESET} " "$GO_WORD"; read -r g; done; fi
}
say()     { printf "\n${DIM}# %s${RESET}\n" "$*"; }
section() { SECTION=$((SECTION+1)); printf "\n${MAGENTA}${BOLD}━━━ [%s] %s ━━━${RESET}\n" "$SECTION" "$*"; }
# present + execute
pe() {
  [ "$SECTION" -lt "$START" ] && return 0
  printf "\n${CYAN}${BOLD}WOPR>${RESET} "; typeit "${GREEN}${1}${RESET}"; wait_go; printf "\n"
  eval "$1"; printf "${DIM}———${RESET}\n"
}

clear
cat <<BANNER
${GREEN}${BOLD}
        GREETINGS PROFESSOR FALKEN.

        W O P R  —  War Operation Plan Response
        GCP Secret Manager · live demo console

        SHALL WE PLAY A GAME?
${RESET}${DIM}   project: ${PROJECT_ID}   |   ENTER to advance · Ctrl-C to abort${RESET}
BANNER
wait_go

# ── 1 · WHY ──────────────────────────────────────────────────────────────────
section "WHY — secrets exist as governed objects, never bare values"
pe 'gcloud secrets list --filter="name:wargames" --format="table(name.basename(), createTime.date())"'

# ── 2 · CONCEPTS ─────────────────────────────────────────────────────────────
section "CONCEPTS — secret (container) vs versions, and 'latest'"
pe 'gcloud secrets versions list "$LAUNCH_SECRET" --format="table(name, state, createTime.date())"'
pe 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo'
say "Replication: automatic vs user-managed (CMEK requires user-managed)"
pe 'gcloud secrets describe "$WARPLAN_SECRET" --format="yaml(replication)"'

# ── 3 · DEPLOY AS CODE ───────────────────────────────────────────────────────
section "DEPLOY — the value is NOT in Terraform state (on purpose)"
pe 'grep -c "CPE1704TKS\|DL6913THX" "$STATE"; echo "   ^ matches in terraform.tfstate (want 0)"'
pe 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo "   ^ value lives in the service, added via CLI"'

# ── 4 · CLI LIFECYCLE ────────────────────────────────────────────────────────
section "CLI — add via stdin, read latest vs pinned, reversible disable"
pe 'printf "NEW-LAUNCH-CODE-%s" "$(date +%H%M%S)" | gcloud secrets versions add "$LAUNCH_SECRET" --data-file=-'
pe 'echo -n "latest -> "; gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo'
say "Disable is REVERSIBLE (destroy is not). Watch it go dark, then bring it back."
pe 'V=$(gcloud secrets versions list "$LAUNCH_SECRET" --filter="state=enabled" --format="value(name)" --sort-by=~name --limit=1); echo "newest version = $V"'
pe 'gcloud secrets versions disable "$V" --secret="$LAUNCH_SECRET"'
pe 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET" 2>&1 | grep -o "FAILED_PRECONDITION.*DISABLED state." || true'
pe 'gcloud secrets versions enable "$V" --secret="$LAUNCH_SECRET"; echo "restored"'

# ── 5 · IAM ──────────────────────────────────────────────────────────────────
section "IAM — least privilege, proven by impersonating WOPR"
pe 'gcloud secrets get-iam-policy "$LAUNCH_SECRET" --format="table(bindings.role, bindings.members)"'
say "WOPR reads its OWN secret (granted):"
pe 'gcloud secrets versions access latest --secret="$LAUNCH_SECRET" --impersonate-service-account="$WOPR_SA" 2>/dev/null; echo'
say "WOPR reaches for a secret it was NOT granted (expect denial):"
pe 'gcloud secrets versions access latest --secret="$WARPLAN_SECRET" --impersonate-service-account="$WOPR_SA" 2>&1 | grep -o "PERMISSION_DENIED.*denied" | head -1 || true'

# ── 6 · SECURITY ─────────────────────────────────────────────────────────────
section "SECURITY — encryption, the INSTANT break-glass, and audit"
say "Our CMEK key is used only by the Secret Manager service agent:"
pe 'gcloud kms keys get-iam-policy "$PREFIX-key" --keyring="$PREFIX-keyring" --location="$REGION" --format="table(bindings.role, bindings.members)"'
say "Break glass = disable the VERSION (instant, no cache lag). Watch the war plan go dark:"
pe 'gcloud secrets versions disable 1 --secret="$WARPLAN_SECRET"'
pe 'gcloud secrets versions access latest --secret="$WARPLAN_SECRET" 2>&1 | grep -o "FAILED_PRECONDITION.*DISABLED state." || true'
pe 'gcloud secrets versions enable 1 --secret="$WARPLAN_SECRET"; echo "war plan restored"'
say "Every access is audited — here are our own reads, attributed by identity:"
pe 'gcloud logging read '"'"'protoPayload.serviceName="secretmanager.googleapis.com" AND protoPayload.methodName:"AccessSecretVersion"'"'"' --project="$PROJECT_ID" --freshness=1h --limit=4 --format="value(timestamp.date(%H:%M:%S), protoPayload.authenticationInfo.principalEmail)"'

# ── 7 · ROTATION ─────────────────────────────────────────────────────────────
section "ROTATION — Secret Manager notifies; a new version = zero-downtime cutover"
pe 'gcloud secrets describe "$BACKDOOR_SECRET" --format="yaml(rotation, topics)"'
say "Live cutover: add a version, 'latest' moves, old stays enabled (drain overlap):"
pe 'echo -n "before -> "; gcloud secrets versions access latest --secret="$BACKDOOR_SECRET"; echo'
pe 'printf "joshua-rotated-%s" "$(date +%H%M%S)" | gcloud secrets versions add "$BACKDOOR_SECRET" --data-file=-'
pe 'echo -n "after  -> "; gcloud secrets versions access latest --secret="$BACKDOOR_SECRET"; echo'
pe 'gcloud secrets versions list "$BACKDOOR_SECRET" --filter="state=enabled" --format="table(name, state)"'

# ── 8 · CONSUMING ────────────────────────────────────────────────────────────
section "CONSUMING — what the client library does under the hood (REST + ADC)"
pe 'TOKEN=$(gcloud auth print-access-token); curl -s -H "Authorization: Bearer $TOKEN" "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$LAUNCH_SECRET/versions/latest:access" | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(\"decoded secret:\", base64.b64decode(d[\"payload\"][\"data\"]).decode())"'

printf "\n${GREEN}${BOLD}A STRANGE GAME. THE ONLY WINNING MOVE IS NOT TO PLAY.${RESET}\n"
printf "${DIM}Demo complete. WOPR out.${RESET}\n\n"
