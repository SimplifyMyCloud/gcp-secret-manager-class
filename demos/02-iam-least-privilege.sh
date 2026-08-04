#!/usr/bin/env bash
# 02-iam-least-privilege.sh - who can read a secret, and proving the boundary.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "== 1. The two roles that matter =="
cat <<'TXT'
  roles/secretmanager.secretAccessor  -> read secret VALUES (the sensitive one)
  roles/secretmanager.viewer          -> read metadata only, NOT values
  roles/secretmanager.admin           -> full control (create/destroy/set IAM)
Grant secretAccessor on the SECRET, not the project. Least privilege.
TXT

echo
echo "== 2. Show the IAM policy on the db-password secret =="
gcloud secrets get-iam-policy "$LAUNCH_SECRET" --format=json

echo
echo "== 3. The app service account has accessor on THIS secret only =="
echo "Impersonating: $WOPR_SA"
# Requires that YOU have roles/iam.serviceAccountTokenCreator on $WOPR_SA.
gcloud secrets versions access latest --secret="$LAUNCH_SECRET" \
  --impersonate-service-account="$WOPR_SA" \
  && echo ">> success: app SA can read db-password"

echo
echo "== 4. Prove the boundary: same SA canNOT read a DIFFERENT secret =="
gcloud secrets versions access latest --secret="$WARPLAN_SECRET" \
  --impersonate-service-account="$WOPR_SA" \
  || echo ">> denied: app SA has NO access to $WARPLAN_SECRET (expected - least privilege works)"

echo
echo "== 5. Test access without granting it: IAM Policy Troubleshooter style =="
echo "Ask: can this member access this resource? (via testIamPermissions)"
gcloud secrets get-iam-policy "$LAUNCH_SECRET" \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/secretmanager.secretAccessor" \
  --format="table(bindings.members)"
