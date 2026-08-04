#!/usr/bin/env bash
# 03-security-deep-dive.sh - encryption at rest, CMEK, and audit logging.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "== 1. Encryption at rest is ALWAYS on. With CMEK, YOU own the key. =="
echo "The CMEK secret is pinned to one region and one KMS key:"
gcloud secrets describe "$WARPLAN_SECRET" \
  --format="yaml(name, replication)"

echo
echo "== 2. Add a value to the CMEK secret, then read it back =="
printf 'GLOBAL-THERMONUCLEAR-WAR' | gcloud secrets versions add "$WARPLAN_SECRET" --data-file=-
gcloud secrets versions access latest --secret="$WARPLAN_SECRET"; echo

echo
echo "== 3. The 'kill switch': disable the KMS key -> secret becomes UNREADABLE =="
KEY="${PREFIX}-key"; KEYRING="${PREFIX}-keyring"
gcloud kms keys versions list --key="$KEY" --keyring="$KEYRING" --location="$REGION" \
  --format="table(name, state)"
echo ">> (In class) disable the primary key version:"
echo "   gcloud kms keys versions disable 1 --key=$KEY --keyring=$KEYRING --location=$REGION"
echo ">> Access then fails with FAILED_PRECONDITION until you re-enable it."
echo ">> Destroying the key version = cryptographic shred (data unrecoverable)."

echo
echo "== 4. Audit logging: every ACCESS is recorded in Cloud Audit Logs =="
echo "Secret access is a DATA_READ log. Reading a secret leaves a trail:"
gcloud logging read \
  'protoPayload.serviceName="secretmanager.googleapis.com" AND protoPayload.methodName:"AccessSecretVersion"' \
  --project="$PROJECT_ID" --limit=5 --freshness=1d \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, resource.labels.secret_id)"

echo
echo ">> If the table above is empty, DATA_READ audit logs may need enabling:"
echo "   Console: IAM & Admin > Audit Logs > Secret Manager API > Data Read."
echo "   (ADMIN_WRITE actions like create/destroy are logged by default.)"
