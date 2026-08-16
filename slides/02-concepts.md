# Secret vs. Version — it's just Git

**Secret = git repo · Version = git commit**

```
wargames-launch-code   ← the "repo": name + IAM + replication (NO value)
 └── v1  CPE1704TKS   [DESTROYED]   payload gone, metadata kept
 └── v2  DL6913THX    [ENABLED]     ← latest  (like HEAD)
```

- **Secret** = the repo — name, access (IAM), where it lives; **never the value**
- **Version** = a commit — one immutable value; you **add**, never edit
- **Pin a version by number** — like a commit hash, just an integer; **`latest`** = newest enabled
- States: **ENABLED → DISABLED** (reversible) **→ DESTROYED** (permanent, metadata remains)

> **Notes:**
> - The whole model in one line: **Secret = git repo, Version = git commit**
> - Name / IAM / replication live on the repo; the bytes live in the commits (versions)
> - Immutable & append-only → free history, instant rollback, safe rotation (like `git log`)
> - `latest` = HEAD · `access <N>` = `git checkout <sha>` · `versions list` = `git log`
> - Analogy is directional — no branching, versions are integers (not SHAs), and truly immutable (no force-push/rewrite)
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
