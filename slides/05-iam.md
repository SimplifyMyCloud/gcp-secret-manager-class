# IAM: least privilege, scoped to the secret

| Role | Grants | Give it to |
|---|---|---|
| `secretmanager.secretAccessor` | **read values** (`versions.access`) | apps / workloads |
| `secretmanager.viewer` | metadata only, **not values** | dashboards / auditors |
| `secretmanager.secretVersionAdder` | add versions, **can't read** | rotation jobs |

**Grant on the SECRET, not the project.** Project-level `secretAccessor` = skeleton key to *every* secret.

```bash
gcloud secrets add-iam-policy-binding wargames-launch-code \
  --member="serviceAccount:wargames-wopr@…" --role="roles/secretmanager.secretAccessor"
```

> **Notes:**
> - Read the *value* (`secretAccessor`) ≠ see it *exists* (`viewer`) — that split is the whole game
> - Grant on the **secret, not the project** — project-level = skeleton key to every secret
> - `secretVersionAdder` = write-only (rotation jobs add versions, never read old ones)
> - Compliance callback: this *is* NIST **AC-6** (least privilege) / CIS **6.1–6.2**, made concrete

---

# Prove the boundary — become WOPR (live)

```bash
# WOPR reads its OWN secret (granted):
… access latest --secret=wargames-launch-code   --impersonate-service-account=wargames-wopr@…
# -> DL6913THX

# WOPR reads a DIFFERENT secret (not granted):
… access latest --secret=wargames-cmek-warplan  --impersonate-service-account=wargames-wopr@…
# -> PERMISSION_DENIED: 'secretmanager.versions.access' denied (or it may not exist)
```

> **Notes:**
> - Same identity, two secrets, opposite outcomes = least privilege live
> - `--impersonate` = test as the app, no deploy (needs tokenCreator; Owner lacks it)
> - GCP won't confirm a secret exists to an unauthorized caller
> - Impersonated reads are audited AS WOPR
> - 🔧 LIVE: both impersonation calls
