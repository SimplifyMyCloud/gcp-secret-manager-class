#!/usr/bin/env bash
# 01-basics.sh - the core lifecycle of a secret, entirely on the CLI.
# Run line-by-line in class; do not just execute the whole file.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "== 1. List secrets in the project (containers, never values) =="
gcloud secrets list --filter="name:${PREFIX}" --format="table(name, createTime, replication.automatic.list())"

echo
echo "== 2. Add the FIRST version (the actual secret material) =="
# The value is piped from stdin with --data-file=-, so it never appears as a
# process argument (which would leak into shell history and `ps` output).
printf 'CPE1704TKS' | gcloud secrets versions add "$LAUNCH_SECRET" --data-file=-

echo
echo "== 3. Access the latest version =="
gcloud secrets versions access latest --secret="$LAUNCH_SECRET"
echo   # (newline after the raw value)

echo
echo "== 4. Add a SECOND version (secrets are versioned + immutable) =="
printf 'DL6913THX' | gcloud secrets versions add "$LAUNCH_SECRET" --data-file=-

echo
echo "== 5. 'latest' now resolves to v2; you can still pin an explicit version =="
echo -n "latest -> "; gcloud secrets versions access latest --secret="$LAUNCH_SECRET"; echo
echo -n "v1     -> "; gcloud secrets versions access 1      --secret="$LAUNCH_SECRET"; echo

echo
echo "== 6. Inspect version state (ENABLED / DISABLED / DESTROYED) =="
gcloud secrets versions list "$LAUNCH_SECRET" --format="table(name, state, createTime)"

echo
echo "== 7. Disable v1 (reversible) - access now fails =="
gcloud secrets versions disable 1 --secret="$LAUNCH_SECRET"
gcloud secrets versions access 1 --secret="$LAUNCH_SECRET" || echo ">> denied: version is DISABLED (expected)"

echo
echo "== 8. Destroy v1 (IRREVERSIBLE) - material is deleted, metadata remains =="
gcloud secrets versions destroy 1 --secret="$LAUNCH_SECRET" --quiet
gcloud secrets versions list "$LAUNCH_SECRET" --format="table(name, state)"
