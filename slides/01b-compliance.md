# Compliance by design — NIST 800-53 r5 + CIS v8 (IG1)

**A "secret" is more than a password** — NIST **IA-5** governs every *authenticator*: API keys, OAuth/refresh tokens, DB connection strings, TLS/SSH private keys, service-account keys, signing keys. All of it is in scope.

| Secret Manager capability | CIS Controls v8 (IG1) | NIST 800-53 r5 |
|---|---|---|
| Per-secret IAM · least privilege · grant/revoke as code | **3.3, 6.1, 6.2** | **AC-3, AC-6** |
| One governed home for creds — no shared/hardcoded passwords | **5.2** | **IA-5** |
| Every access logged (who / what / when) | **8.2** | **AU-2, AU-12** |
| Destroy / crypto-shred old versions (secure disposal) | **3.5** | **MP-6** |
| *Beyond IG1:* always-on AES-256 + CMEK | 3.11 *(IG2)* | SC-28, SC-13, SC-12 |

- **IG1 "for free"** — adopting Secret Manager satisfies these foundational safeguards by default, not by manual effort.
- **The audit log *is* the evidence** — controls you can *prove* to an auditor, not just claim.

> **Notes:**
> - IG1 = essential cyber hygiene — the baseline every org is expected to meet
> - "Not just passwords": teams guard passwords but leave API keys in `.env` and SA-key JSON in the repo — equally in scope for IA-5
> - Each row is a control an auditor checks — satisfied by centralizing secrets here vs scattered in code/env/config
> - 3.3 + 6.1/6.2 → per-secret IAM and the grant/revoke *process* (Terraform = the documented, reviewable process)
> - 5.2 Use Unique Passwords → one store enables a unique cred per system; kills reuse/hardcoding
> - 8.2 Collect Audit Logs → Cloud Audit Logs (turn DATA_READ on) = your audit evidence
> - 3.5 Securely Dispose → destroy a version = crypto-shred; metadata stays for the trail
> - CMEK adds separation of duties → NIST **AC-5** (KMS admin ≠ secret admin) — good Q&A depth
> - Honesty: encryption-at-rest is CIS 3.11 = **IG2**, not IG1 — present as a bonus, not an IG1 claim
