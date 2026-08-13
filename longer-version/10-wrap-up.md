# CLI cheat sheet

```bash
# Create a secret container
gcloud secrets create NAME --replication-policy=automatic

# Add a value (a new version) — via stdin, never as an argument
printf 'VALUE' | gcloud secrets versions add NAME --data-file=-

# Read the value
gcloud secrets versions access latest --secret=NAME

# List versions and their state
gcloud secrets versions list NAME

# Grant least-privilege read to one identity, on this secret only
gcloud secrets add-iam-policy-binding NAME \
  --member="serviceAccount:SA_EMAIL" --role="roles/secretmanager.secretAccessor"

# Lifecycle
gcloud secrets versions disable N  --secret=NAME   # reversible
gcloud secrets versions destroy N  --secret=NAME   # irreversible
```

> **Speaker notes:** This is the take-home slide — tell them to screenshot it. Every command here is one they saw run live. It's 90% of daily Secret Manager usage.

---

# What we covered

- **Why** Secret Manager — managed, IAM-gated, versioned, audited
- **Concepts** — secret vs. version, immutability, `latest`, replication
- **Deploy** — Terraform for containers/IAM; values injected out-of-band
- **CLI** — create → version → access → disable → destroy
- **IAM** — least privilege, scoped to the secret, proven with impersonation
- **Security** — always-on encryption, CMEK kill switch, audit logs
- **Rotation** — Secret Manager notifies; your automation rotates
- **Consuming** — apps, Cloud Run/GKE, and BigQuery/data patterns

> **Speaker notes:** A quick recap to reinforce the arc: we went from "why does this exist" to "here's how I use it tomorrow." Tie each bullet back to the live demo the students just watched.

---

# The only winning move

> *"A strange game. The only winning move is not to play."* — WOPR

**Don't play games with secrets:**

- Don't hardcode them
- Don't commit them
- Don't put them in state, logs, or job args
- **Do** put them in Secret Manager, scope access tightly, and audit everything

**Thanks — let's play a game. Questions?**

> **Speaker notes:** Land the WarGames callback. The "winning move is not to play" maps perfectly onto the whole talk: the way you win the secrets game is by not doing the risky thing in the first place — Secret Manager makes the safe path the easy path. Open the floor for questions. If time allows, offer to run any demo command live on request.
