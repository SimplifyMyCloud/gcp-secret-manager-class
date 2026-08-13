# IAM: the three roles you actually use

| Role | Grants | Give it to |
|---|---|---|
| `secretmanager.secretAccessor` | **read secret values** | apps / workloads |
| `secretmanager.viewer` | read metadata, **not values** | dashboards / auditors |
| `secretmanager.admin` | create, destroy, set IAM | platform team (sparingly) |

Also: `secretVersionAdder` (add versions but not read) — perfect for a **rotation function** that writes new values without read access.

> **Speaker notes:** The key insight: reading the *value* (`secretAccessor`) is a different, more sensitive permission than seeing the secret *exists* (`viewer`). And `secretVersionAdder` lets a rotation job write new versions without ever being able to read existing ones — beautiful least privilege. Avoid handing out `admin`.

---

# Grant on the SECRET, not the project

```bash
# GOOD: this SA can read exactly one secret
gcloud secrets add-iam-policy-binding wargames-launch-code \
  --member="serviceAccount:wargames-wopr@…iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# BAD: project-level grant = read EVERY secret in the project
# gcloud projects add-iam-policy-binding … --role=secretAccessor
```

> **Speaker notes:** Resource-scoped IAM is the whole game. A project-level `secretAccessor` is a skeleton key to every secret you have — exactly the blast radius you're trying to avoid. Grant on the individual secret. In our Terraform this is `google_secret_manager_secret_iam_member`, scoped to the one secret.

---

# Proving the boundary (live)

```bash
# app SA CAN read its own secret…
gcloud secrets versions access latest --secret=wargames-launch-code \
  --impersonate-service-account=wargames-wopr@…iam.gserviceaccount.com
# -> DL6913THX

# …but is DENIED on a secret it wasn't granted
gcloud secrets versions access latest --secret=wargames-cmek-warplan \
  --impersonate-service-account=wargames-wopr@…iam.gserviceaccount.com
# -> PERMISSION_DENIED: Permission 'secretmanager.versions.access'
#    denied on resource wargames-cmek-warplan
```

> **Speaker notes:** `--impersonate-service-account` lets you test as the app without deploying anything — you assume the SA's identity (you need `serviceAccountTokenCreator` on it). Show the success, then the denial on a different secret. That denial IS least privilege working: same identity, different resource, no access.

---

# Advanced: narrow it further

- **IAM Conditions** — grant only during a time window, or only to versions with a matching label/prefix
- **VPC Service Controls** — put Secret Manager in a perimeter so even a valid token can't exfiltrate values from outside the perimeter
- **Org policy** — e.g. `constraints/gcp.restrictNonCmekServices` to *require* CMEK on secrets

> **Speaker notes:** For the security engineers: IAM answers "who", VPC-SC answers "from where". VPC Service Controls is the control that stops a leaked service-account key from being used to pull secrets from an attacker's laptop — the API call is rejected at the perimeter regardless of IAM. Org policies let you mandate CMEK org-wide so no one can create a Google-key secret by accident.
