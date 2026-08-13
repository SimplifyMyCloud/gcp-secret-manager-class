# CLI cheat sheet (screenshot this)

```bash
# Create a container
gcloud secrets create NAME --replication-policy=automatic

# Add a value (new version) — via stdin, never as an argument
printf 'VALUE' | gcloud secrets versions add NAME --data-file=-

# Read it
gcloud secrets versions access latest --secret=NAME

# Least-privilege read, on this secret only
gcloud secrets add-iam-policy-binding NAME \
  --member="serviceAccount:SA_EMAIL" --role="roles/secretmanager.secretAccessor"

# Lifecycle
gcloud secrets versions disable N --secret=NAME   # reversible
gcloud secrets versions destroy N --secret=NAME   # irreversible
```

> **Notes:**
> - ~90% of daily use; every command was run live today
> - Workloads are read-dominated → latest + caching + audited reads = the design center

---

# The only winning move

> *"A strange game. The only winning move is not to play."* — WOPR

**Don't play games with secrets:**
- Don't hardcode · don't commit · don't put them in state, logs, or job args
- **Do** centralize in Secret Manager, scope access tightly, audit everything

Secret Manager makes the **secure path the easy path** — runtime fetch, IAM, CMEK, rotation, audit, all as code.

**Thanks — shall we play a game? Questions?**

> **Notes:**
> - You win by not making the risky move
> - All real, reproducible, ~$0.39/mo — take the repo, one `apply`, same lab
> - Teardown after class: `terraform destroy -var="demo_impersonator=user:chris@..."`
