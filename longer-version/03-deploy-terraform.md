# Deploy with Terraform

Everything you'll see is defined as code in `terraform/`:

- `main.tf` — the secret container + least-privilege consumer SA
- `kms.tf` — CMEK deep-dive secret (your own KMS key)
- `rotation.tf` — rotation-notification secret + Pub/Sub topic
- `outputs.tf` — handy IDs for the CLI demo

```bash
cd terraform
terraform init
terraform apply
```

> **Speaker notes:** Infrastructure-as-code matters here for a specific reason: the *access policy* to your secrets should be reviewed like any other code. IAM bindings in Terraform get a PR, a diff, and an approver — far better than someone clicking "grant" in the console.

---

# The one line we DON'T write in Terraform

```hcl
resource "google_secret_manager_secret" "db_password" {
  secret_id = "wargames-launch-code"
  replication { auto {} }
}
# NOTE: no google_secret_manager_secret_version here — on purpose.
```

**Terraform creates the container; the secret VALUE is added via CLI.**

Why? A `secret_version` resource stores the plaintext in **`terraform.tfstate`** — which lands in your state backend, and often in a PR.

> **Speaker notes:** This is the single most important slide for the security folks. It's a genuine footgun: the moment you put a value in a `google_secret_manager_secret_version` resource, that plaintext is in state. State is not encrypted by default in local backends, and even a GCS backend means anyone with bucket read can `terraform show` the secret. So: manage the container, IAM, replication, CMEK, and rotation in Terraform — inject the value out-of-band. If you MUST seed a value in TF, mark it sensitive and use a GCS backend with CMEK + tight IAM, and know the tradeoff.

---

# What `apply` created

```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:
launch_code_secret_id       = "wargames-launch-code"
wopr_service_account        = "wargames-wopr@simplifymycloud-dev.iam.gserviceaccount.com"
cmek_warplan_secret_id      = "wargames-cmek-warplan"
kms_key                     = ".../keyRings/wargames-keyring/cryptoKeys/wargames-key"
joshua_backdoor_secret_id   = "wargames-joshua-backdoor"
rotation_topic              = ".../topics/wargames-rotation-events"
secretmanager_service_agent = "service-288261943767@gcp-sa-secretmanager.iam.gserviceaccount.com"
```

Three secrets, a consumer identity, a KMS key, and a Pub/Sub topic — all as code.

> **Speaker notes:** These outputs feed the demo scripts (see `demos/00-env.sh`). Note the "service agent" — that's Secret Manager's own Google-managed identity, which we granted rights to use the KMS key and publish rotation events. We'll come back to it in the CMEK section.
