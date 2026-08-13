# GCP Secret Manager

### Storing secrets the right way — a hands-on 30 minutes

Simplify My Cloud · Platform Team

> **Speaker notes:** Welcome. This is a hands-on session — everything you'll see is deployed live in `simplifymycloud-dev` with Terraform and driven from the `gcloud` CLI. By the end you'll know what Secret Manager is, how to deploy and use it, how its security model actually works, and the patterns to consume secrets safely from apps, data pipelines, and BigQuery workloads.

---

# Agenda (~30 min)

1. **Why** Secret Manager exists — 3 min
2. **Core concepts** — secrets, versions, replication — 4 min
3. **Deploy** with Terraform — 4 min
4. **CLI lifecycle** — create / version / access / destroy — 5 min
5. **IAM & least privilege** — 4 min
6. **Security deep dive** — encryption, CMEK, audit logs — 5 min
7. **Rotation & lifecycle** — 3 min
8. **Consuming secrets** (apps, SRE, BigQuery/data) — 2 min

> **Speaker notes:** Keep an eye on the clock. The two deep dives (security + IAM) are where the security engineers lean in; the consuming-secrets section is where app and data engineers get their patterns. Everything is a real command you can re-run.
