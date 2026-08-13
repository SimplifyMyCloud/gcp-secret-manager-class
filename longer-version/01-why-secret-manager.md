# The problem: where do secrets live today?

- Hardcoded in source → leaks to Git history **forever**
- Baked into container images → anyone with `docker pull` has them
- Plaintext env vars / `.env` files → visible in `ps`, crash dumps, logs
- Config management (Ansible vars, `terraform.tfvars`) → in state & VCS
- Shared in Slack / tickets / spreadsheets → ungoverned, unauditable

> **Speaker notes:** Ask the room: "where does your DB password live right now?" Almost every breach post-mortem includes a credential in the wrong place. The point isn't shame — it's that these locations share one flaw: no access control, no audit trail, no rotation, no revocation.

---

# What GCP Secret Manager is

A **fully-managed, regional-or-global service** to store, version, access, and audit secrets — API keys, passwords, certificates, tokens.

- **Encrypted at rest** by default (AES-256), always
- **IAM-controlled** access — per-secret, least-privilege
- **Versioned & immutable** — full history, safe rotation
- **Audited** — every access is a Cloud Audit Log entry
- **Integrated** — Cloud Run, GKE, Cloud Functions, IAM, KMS, Terraform

> **Speaker notes:** Emphasize "managed": no servers, no Vault cluster to run. It's a Google API with an IAM front door. It is NOT a general key-value store and NOT a database-credential broker — it stores the secret and tells you when to rotate; your automation does the rotating.

---

# Why not just use Vault / env vars / KMS directly?

| Option | Access control | Audit | Rotation | Ops burden |
|---|---|---|---|---|
| Env vars / files | ❌ | ❌ | ❌ | Low |
| Encrypt with KMS yourself | ⚠️ manual | ⚠️ | ❌ | Medium |
| Self-hosted Vault | ✅ | ✅ | ✅ | **High** |
| **Secret Manager** | ✅ IAM | ✅ built-in | ✅ notify | **None** |

> **Speaker notes:** KMS encrypts/decrypts data but doesn't store it or manage versions — Secret Manager uses KMS under the hood and adds storage, versioning, IAM, and audit. Vault is powerful but you run it. For teams already on GCP, Secret Manager is the low-friction default; reach for Vault when you need dynamic secrets or multi-cloud brokering.
