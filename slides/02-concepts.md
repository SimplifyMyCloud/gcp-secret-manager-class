# Core concept: Secret vs. Version

```
wargames-launch-code   (container — name + IAM + replication, NO value)
 └── Version 1   "CPE1704TKS"    [DESTROYED]  payload gone, metadata kept
 └── Version 2   "DL6913THX"     [ENABLED]    ← "latest"
```

- **Secret** = container: policy, IAM, replication — never the value
- **Version** = one immutable payload; add a new one, never edit
- Read by number or the alias **`latest`** (newest enabled)
- States: **ENABLED** → **DISABLED** (reversible) → **DESTROYED** (permanent, metadata remains)

> **Notes:** This is THE mental model. IAM lives on the secret; bytes live on versions. Immutability = free history, instant rollback, safe rotation. Disable is a light switch; destroy is a shredder — disable first, destroy after a drain window.
> 🔧 LIVE: `gcloud secrets versions list wargames-launch-code` then `... versions access latest` → DL6913THX.

---

# Replication: where the ciphertext lives

- **Automatic** (default) — Google replicates + manages the key. Use this unless you have a reason not to.
- **User-managed** — you pin the region(s). Required for **data residency** and for **CMEK** (your own key).

```yaml
# wargames-launch-code           # wargames-cmek-warplan
replication:                     replication:
  automatic: {}                    userManaged:
                                     replicas:
                                     - location: us-central1
                                       customerManagedEncryption:
                                         kmsKeyName: .../wargames-key
```

> **Notes:** CMEK requires user-managed replication — key and secret in the same region. Data engineers: pin the secret to the same region as a regional BigQuery/Dataflow dataset for residency.
> 🔧 LIVE: `gcloud secrets describe wargames-cmek-warplan --format="yaml(replication)"`.
