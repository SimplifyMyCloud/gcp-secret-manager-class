# Compliance by design — NIST 800-53 r5 + CIS v8 (IG1)

Centralizing every secret in Secret Manager satisfies core **essential cyber-hygiene (IG1)** safeguards — turning "manage your secrets" from a policy line into an enforced, auditable control.

| Secret Manager capability | CIS Controls v8 (IG1) | NIST 800-53 r5 |
|---|---|---|
| Per-secret IAM · least privilege · grant/revoke as code | **3.3, 6.1, 6.2** | **AC-3, AC-6** |
| One governed home for creds — no shared/hardcoded passwords | **5.2** | **IA-5** |
| Every access logged (who / what / when) | **8.2** | **AU-2, AU-12** |
| Destroy / crypto-shred old versions (secure disposal) | **3.5** | **MP-6** |
| *Beyond IG1:* always-on AES-256 + CMEK | 3.11 *(IG2)* | SC-28, SC-13, SC-12 |

> **Notes:**
> - IG1 = essential cyber hygiene — the baseline every org is expected to meet
> - Each row is a control an auditor checks — satisfied by centralizing secrets here vs scattered in code/env/config
> - 3.3 + 6.1/6.2 → per-secret IAM and the grant/revoke *process* (Terraform = the documented, reviewable process)
> - 5.2 Use Unique Passwords → one store enables a unique cred per system; kills reuse/hardcoding
> - 8.2 Collect Audit Logs → Cloud Audit Logs (turn DATA_READ on)
> - 3.5 Securely Dispose → destroy a version = crypto-shred; metadata stays for the audit trail
> - Honesty: encryption-at-rest is CIS 3.11 = **IG2**, not IG1 — present as a bonus, not an IG1 claim
> - NIST anchor control for secrets = **IA-5 (Authenticator Management)**
