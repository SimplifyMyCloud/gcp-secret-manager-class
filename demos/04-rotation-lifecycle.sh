#!/usr/bin/env bash
# 04-rotation-lifecycle.sh - rotation notifications and safe version cutover.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "== 1. The rotating secret is wired to a Pub/Sub topic + schedule =="
gcloud secrets describe "$BACKDOOR_SECRET" \
  --format="yaml(name, topics, rotation)"

echo
echo "== 2. Secret Manager NOTIFIES; YOUR automation rotates. The flow: =="
cat <<'TXT'
  next_rotation_time fires -> Pub/Sub message on wargames-rotation-events
    -> Cloud Function / Cloud Run consumes it
    -> generates a new credential in the upstream system (DB, API provider)
    -> gcloud secrets versions add  (new ENABLED version becomes 'latest')
    -> apps pick up 'latest' on next fetch; old version disabled after drain.
TXT

echo
echo "== 3. Simulate the rotation step a consumer would perform =="
printf 'joshua-ROTATED-%s' "$(date +%s)" | gcloud secrets versions add "$BACKDOOR_SECRET" --data-file=-
gcloud secrets versions list "$BACKDOOR_SECRET" --format="table(name, state, createTime)"

echo
echo "== 4. Zero-downtime cutover: apps should reference 'latest', not a pinned N"
echo "    so a new version is picked up without a redeploy."
gcloud secrets versions access latest --secret="$BACKDOOR_SECRET"; echo

echo
echo "== 5. Manually publish a test message (proves the topic is reachable) =="
gcloud pubsub topics publish "${PREFIX}-rotation-events" \
  --message='{"test":"rotation-drill"}' \
  --attribute="eventType=SECRET_ROTATE,secretId=${BACKDOOR_SECRET}"
