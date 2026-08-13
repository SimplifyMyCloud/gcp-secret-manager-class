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

> **Notes:**
> - THE mental model: IAM on the secret, bytes on the versions
> - Immutable = free history, instant rollback, safe rotation
> - Disable = light switch (reversible); destroy = shredder — disable first
> - 🔧 LIVE: `versions list wargames-launch-code` → `access latest` → DL6913THX

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

> **Notes:**
> - CMEK requires user-managed replication (key + secret, same region)
> - Data eng: pin the secret to your dataset's region for residency
> - 🔧 LIVE: `gcloud secrets describe wargames-cmek-warplan --format="yaml(replication)"`
