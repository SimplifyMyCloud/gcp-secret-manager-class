# Why Secret Manager?

**The problem — where secrets live today, and why each is a trap:**

- Hardcoded in source → in Git history **forever**
- `.env` / plaintext env vars → visible in `ps`, logs, crash dumps
- `terraform.tfvars` / state → sits in your VCS & state bucket
- Slack / tickets / spreadsheets → ungoverned, unauditable

**What Secret Manager adds that none of those have:**

| | Access control | Audit | Rotation | Ops |
|---|---|---|---|---|
| env vars / files | ❌ | ❌ | ❌ | low |
| self-hosted Vault | ✅ | ✅ | ✅ | **high** |
| **Secret Manager** | ✅ IAM | ✅ built-in | ✅ notify | **none** |

> **Notes:** The common flaw in every bad location: no access control, no audit, no rotation, no revocation. Secret Manager is a fully-managed API (built on Cloud KMS) that adds exactly those four. Not a KV store (64 KiB max); reach for Vault only when you need dynamic secrets or multi-cloud.
> 🔧 LIVE (optional): `gcloud secrets list --filter=name:wargames` → names/dates, never values.
