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
gcloud secrets versions access latest --secret=wargames-launch-code \
  --impersonate-service-account=wargames-wopr@simplifymycloud-dev.iam.gserviceaccount.com
# -> DL6913THX

# WOPR reads a DIFFERENT secret (not granted):
gcloud secrets versions access latest --secret=wargames-cmek-warplan \
  --impersonate-service-account=wargames-wopr@simplifymycloud-dev.iam.gserviceaccount.com
# -> PERMISSION_DENIED: 'secretmanager.versions.access' denied on resource (or it may not exist)
```

> **Notes:**
> - Same identity, two secrets, opposite outcomes = least privilege live
> - **`--impersonate-service-account`** = borrow the app's identity for one command — you run *as WOPR*, no deploy, no key file, no code change. The gold standard for "does this SA actually have the access it needs?"
>   - How it works: you ask GCP for a **short-lived token** minted for that SA; every call then carries the SA's permissions, not yours
>   - The gate is **`roles/iam.serviceAccountTokenCreator`** *on the target SA* — the right to mint that token
>   - **Owner does NOT include it.** Surprises people: IAM roles aren't a hierarchy, they're additive sets — `Owner` can *administer* the SA but can't *become* it until you explicitly grant tokenCreator. That's separation of duties by design (managing an identity ≠ acting as it)
>   - In our lab that's the `demo_impersonator` Terraform var — grant it to yourself before showtime or the FIRST call `PERMISSION_DENIED`s on *you*, not WOPR
> - GCP won't confirm a secret exists to an unauthorized caller
> - Impersonated reads are audited AS WOPR
> - 🔧 LIVE: both impersonation calls
