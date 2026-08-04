# Core concept: Secret vs. Version

```
wargames-launch-code   (the container — name + IAM + replication, NO value)
 └── Version 1   "CPE1704TKS"    [DESTROYED]
 └── Version 2   "DL6913THX"     [DISABLED]
 └── Version 3   "JMK2209RTZ"    [ENABLED]  ← "latest"
```

- The **secret** holds policy and metadata — never the value
- Each **version** holds one immutable payload
- You reference a value by number (`3`) or the alias **`latest`**

> **Speaker notes:** This split is the whole mental model. IAM and replication live on the secret; the actual bytes live on versions. Versions are immutable — you never "edit" a secret, you add a new version. This is what makes rotation safe and auditable.

---

# Version states

- **ENABLED** — readable
- **DISABLED** — blocked, but **reversible** (re-enable anytime)
- **DESTROYED** — payload permanently deleted; **metadata remains** for audit

The lifecycle: `add → enable/disable → destroy`. Disable first, destroy once you're certain — destroy is irreversible.

> **Speaker notes:** Practical tip: when rotating, don't destroy the old version immediately. Disable it, watch for errors from stragglers still holding the old value, then destroy after a drain window. Destroyed versions keep their metadata so audits can still see "version 1 existed and was destroyed on this date by this principal."

---

# Replication: where the ciphertext lives

- **Automatic** (default) — Google replicates globally, manages the key.
  *Use this unless you have a reason not to.*
- **User-managed** — you pick the exact region(s).
  Required for **data-residency** rules and for **CMEK** (your own key).

```bash
# automatic
gcloud secrets create my-secret --replication-policy=automatic
# user-managed, pinned to two regions
gcloud secrets create my-secret \
  --replication-policy=user-managed --locations=us-central1,us-east1
```

> **Speaker notes:** For the data engineers: user-managed replication is how you keep a secret physically inside, say, the EU for GDPR, or co-located with a regional BigQuery/Dataflow workload to satisfy residency. It's also mandatory if you want to bring your own KMS key (CMEK), which we'll deploy in the security deep dive.
