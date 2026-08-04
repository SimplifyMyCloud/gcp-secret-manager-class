# Security deep dive: encryption at rest

- **Always on.** Every secret version is encrypted with **AES-256** before it touches disk — you cannot turn it off.
- **Envelope encryption:** the payload is encrypted with a Data Encryption Key (DEK); the DEK is wrapped by a Key Encryption Key (KEK) in Cloud KMS.
- Default KEK is **Google-managed** — zero config.
- Optional **CMEK** — swap in a KEK *you* own and control.

```
plaintext ──AES-256──▶ ciphertext on disk
   DEK ──wrapped by──▶ KEK (Google-managed  OR  your CMEK)
```

> **Speaker notes:** Envelope encryption is standard practice: a per-secret data key encrypts the bytes, and a key-encryption-key (in KMS) wraps that data key. With Google-managed keys you get all of this for free and never think about it. CMEK just replaces the top-level KEK with one in your own KMS keyring — which gives you the controls on the next slides.

---

# Security deep dive: CMEK = you hold the key

Bring your own Cloud KMS key. What that buys you:

- **You control key rotation** cadence (we set 90 days in `kms.tf`)
- **You control availability** — disable the key and the secret is instantly unreadable
- **Separation of duties** — a KMS admin can revoke crypto access independent of Secret Manager IAM
- Required by many **compliance regimes** (PCI, FedRAMP, internal policy)

CMEK requires **user-managed replication** (key + secret in the same region).

> **Speaker notes:** The compliance framing lands with the security folks: CMEK means Google literally cannot decrypt your secret without your key being enabled. Note the tradeoff — you're now responsible for that key's availability. Disable or delete it by mistake and your secret goes dark. That's the point of the next slide, used deliberately.

---

# Security deep dive: the CMEK kill switch

```bash
# Disable the KMS key version → CMEK secret becomes UNREADABLE immediately
gcloud kms keys versions disable 1 \
  --key=wargames-key --keyring=wargames-keyring --location=us-central1

gcloud secrets versions access latest --secret=wargames-cmek-warplan
# -> FAILED_PRECONDITION: key is disabled

# Re-enable to restore access; DESTROY the key = permanent crypto-shred
```

> **Speaker notes:** This is the "break glass" control. Suspect a secret is compromised and being actively read? Disable the key — every read fails in seconds, globally, regardless of who holds `secretAccessor`. Re-enable when safe. Destroying the key version is a cryptographic shred: the ciphertext is still on disk but is now unrecoverable noise. IAM revocation stops *future* grants; the key kill switch stops *everyone right now*.

---

# Security deep dive: every access is audited

```bash
gcloud logging read \
  'protoPayload.serviceName="secretmanager.googleapis.com"
   AND protoPayload.methodName:"AccessSecretVersion"' \
  --limit=5 --freshness=1d \
  --format="table(timestamp,
     protoPayload.authenticationInfo.principalEmail,
     resource.labels.secret_id)"
```

- **ADMIN_WRITE** (create/destroy/set-IAM) — logged **by default**
- **DATA_READ** (accessing a value) — **must be enabled** per project
- Who, what, when, from which IP — immutable in Cloud Audit Logs

> **Speaker notes:** Turn on DATA_READ audit logs for Secret Manager (IAM & Admin → Audit Logs) or you won't see the accesses — only the admin actions. Once on, every single value read is attributed to a principal with a timestamp and caller IP. Export these to BigQuery or your SIEM and you can alert on anomalies: a service account reading a secret it's never touched, access from an unexpected region, a spike in reads. That's your detection layer on top of IAM's prevention layer.
