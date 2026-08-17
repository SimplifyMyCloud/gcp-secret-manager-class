# Encryption: where Google-managed keys stop and CMEK starts

**Always on** — AES-256, envelope-encrypted (`DEK ← KEK in Cloud KMS`), before it touches disk. No off switch.

**Google-managed KEK — right for ~90%**
- Zero config, zero cost, auto-rotated, **always available**
- **Same AES-256 as CMEK** — the crypto is identical

**CMEK — you own the KEK *and its risks***
- Driven by **data sovereignty & contracts** (SecNumCloud, C5, HYOK) — *not* PCI/HIPAA
- Lets you **cut Google off** — revoke decryption independent of secret IAM
- ⚠️ The key is now **your single point of failure** — kill it and every secret it wraps goes dark

> **Notes:**
> - The one-liner: **CMEK changes *who holds the key*, not *how strong the lock is*** — same AES-256 either way
> - Envelope (DEK ← KEK): rotate/revoke the KEK without re-encrypting the payload — you just re-wrap the tiny DEK
> - Why Google-managed is an engineering gift: it removes an entire *operational surface* — no rotation jobs, no key-availability risk, no on-call for "the key is gone"
> - The CMEK trap people forget: your key IS a single point of failure now. Google-managed keys can't take you down; your own key can
> - When it's genuinely worth it: a regulator/contract requires customer-held keys, OR you need the ability to unilaterally revoke Google's ability to decrypt
> - Only user of our key = the SM service agent — a grant you can revoke (that's the break-glass on the next slide)
> - 🔧 LIVE (optional): `gcloud kms keys get-iam-policy wargames-key …`

---

# Containment ladder — DEFCON for a compromised secret

| DEFCON | Action | Speed | Reversible? | Use when |
|---|---|---|---|---|
| 🔵 **5** | Secret **active** — all versions readable | — | — | Peacetime; normal ops |
| 🟢 **4** | **Disable the version** — `versions disable` | **Instant** | ✅ Yes | First move — stop the bleeding |
| 🟡 **3** | **Revoke IAM** — remove `secretAccessor` | Fast | ✅ Yes | Cut off *who* can read it |
| 🔴 **2** | **Disable the CMEK key** — crypto kill switch | Mins (cache) | ✅ Yes | No *new* decryption, org-wide |
| ⚪ **1** | **Destroy** — `versions destroy` / destroy key | Permanent | ❌ No | **Break glass** — crypto-shred, gone |

**Escalate only as far as you must.** Your fastest option (DEFCON 4) is also your safest — instant *and* reversible.

> **Notes:**
> - DEFCON 5 = normal readiness, DEFCON 1 = nuclear — same ladder as our incident response
> - DEFCON 4 (disable version) is the everyday move: **instant** because it fails at the SM layer, *before* KMS — and reversible, so a false alarm costs you nothing
> - DEFCON 2 honesty: disabling the KMS key is **NOT instant** — SM caches decrypted payloads for secs–mins. It guarantees no NEW decryption, not an immediate stop
> - DEFCON 1 is the ONLY true "break glass": destroy = permanent crypto-shred. Version destroy kills one secret; key destroy nukes *every* secret that key wraps
> - Real break-glass discipline: escalate one level at a time, disable before you destroy, never destroy blind
> - 🔧 LIVE: DEFCON 4 → `versions disable` → instant `FAILED_PRECONDITION` → re-enable (flip it back, no harm)

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
