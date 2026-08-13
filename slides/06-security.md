# Security: encryption at rest + CMEK

- **Always on.** AES-256 before it touches disk. No off switch.
- **Envelope:** payload ← DEK ← wrapped by a KEK in Cloud KMS.
- Default KEK is **Google-managed** (zero config). **CMEK** = you own the KEK.

**What CMEK buys you:**
- You control **key rotation** cadence (ours: 90 days, in code)
- **Separation of duties** — a KMS admin can revoke crypto access independent of secret IAM
- Required by **PCI / FedRAMP / internal policy**

> **Notes:**
> - Envelope (DEK ← KEK): rotate/revoke the KEK without re-encrypting data
> - CMEK = Google can't decrypt without your key enabled
> - Only user of our key = the SM service agent — a grant you can revoke
> - 🔧 LIVE (optional): `gcloud kms keys get-iam-policy wargames-key …`

---

# The "break glass" controls

**Need a secret to stop being readable NOW? Layer three controls:**

```bash
# 1) Disable the VERSION — INSTANT (fails at the SM layer, before KMS)
gcloud secrets versions disable 2 --secret=wargames-cmek-warplan
#    -> access now returns FAILED_PRECONDITION: DISABLED

# 2) Revoke IAM (secretAccessor)  — stops authorized callers
# 3) Disable the CMEK KEY — the crypto kill switch (see note on timing)
```

> **Notes:**
> - Honest: KMS-key disable is NOT instant — SM caches payloads (secs–mins)
> - Key disable guarantees no NEW decryption; DESTROY key = permanent crypto-shred
> - Instant stop = disable the VERSION (SM layer, before KMS)
> - Defense in depth: version-disable + revoke IAM + disable key
> - 🔧 LIVE: version disable → instant FAILED_PRECONDITION → re-enable

---

# Every access is audited

```
### DATA_READ (AccessSecretVersion) — who read what, just now:
23:52:15  wargames-wopr@…   wargames-cmek-warplan/versions/latest   (denied attempt, logged)
23:52:14  wargames-wopr@…   wargames-launch-code/versions/latest
00:18:42  chris@simplifymy.cloud   wargames-cmek-warplan
```

- **ADMIN_WRITE** logged by default; **DATA_READ** must be **enabled per project**
- Who / what / when / from where — immutable; impersonation attributed to the real identity
- Export to **BigQuery / SIEM** → alert on anomalies (new reader, odd region, spike)

> **Notes:**
> - Prevention = IAM; detection = audit logs
> - Turn DATA_READ on proactively or you're blind in an incident
> - Even denied attempts are logged — your intrusion signal
> - 🔧 LIVE: `gcloud logging read '…AccessSecretVersion…' --freshness=1h`
