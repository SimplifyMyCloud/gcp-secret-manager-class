#!/usr/bin/env bash
# 99-cleanup.sh - remove everything the class created.
# Prefer `terraform destroy` for the infra; this handles the values/versions
# that Terraform intentionally does not manage.
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "This destroys all wargames secret versions, then runs terraform destroy."
read -r -p "Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { echo "aborted"; exit 1; }

# Secret values are added out-of-band, but `terraform destroy` deletes the
# whole secret container (versions included), so no manual version cleanup is
# strictly required. Shown here for completeness / partial teardown.

echo "Running terraform destroy..."
terraform -chdir="$(dirname "$0")/../terraform" destroy -auto-approve

echo "Done. Verify nothing wargames remains:"
gcloud secrets list --filter="name:${PREFIX}" --format="value(name)"
