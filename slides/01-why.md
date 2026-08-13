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

> **Notes:**
> - Every bad location shares one flaw: no access control, audit, rotation, or revocation
> - Secret Manager = managed API (on Cloud KMS) that adds exactly those four
> - Not a KV store (64 KiB max); Vault only for dynamic secrets / multi-cloud
> - 🔧 LIVE (optional): `gcloud secrets list --filter=name:wargames` → names, never values
