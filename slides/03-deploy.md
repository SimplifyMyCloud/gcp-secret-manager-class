# Deploy as code — and keep values OUT of state

```hcl
resource "google_secret_manager_secret" "launch_code" {
  secret_id = "wargames-launch-code"
  replication { auto {} }
}
# NOTE: no google_secret_manager_secret_version here — on purpose.
```

**Terraform builds the container, IAM, CMEK, rotation. The VALUE is added via CLI** so plaintext never lands in `terraform.tfstate`.

```
$ grep -c "CPE1704TKS\|DL6913THX" terraform.tfstate
0            ← the secret value is NOT in state
$ gcloud secrets versions access latest --secret=wargames-launch-code
DL6913THX    ← it lives in the service, added out-of-band
```

> **Notes:** The footgun: a `secret_version` resource writes plaintext into state, readable by anyone with the state bucket. Manage policy as code (reviewable PR); inject values via CLI/pipeline. 14 real resources came from this repo; `apply` also emits outputs the demo scripts consume. `.gitignore` blocks state & tfvars.
> 🔧 LIVE: the two commands above.
