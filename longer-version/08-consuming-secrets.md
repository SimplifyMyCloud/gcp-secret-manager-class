# Consuming secrets: app developers

**Never read a secret into code from a file or env literal.** Fetch at runtime via the client library, using the workload's own service account (no keys).

```python
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()
name = "projects/simplifymycloud-dev/secrets/wargames-launch-code/versions/latest"
password = client.access_secret_version(name=name).payload.data.decode()
```

- Uses **Application Default Credentials** — no secret to bootstrap the secrets client
- Cache in memory with a short TTL; refresh on `latest`

> **Speaker notes:** The bootstrapping trick: you authenticate to Secret Manager with the workload's ambient identity (ADC / metadata server), so there's no "secret zero" to store. The client fetches the real secret at runtime. This is the pattern for Cloud Run, GKE, Cloud Functions, GCE — all of them have an attached service account you grant `secretAccessor` to.

---

# Consuming secrets: SRE / platform patterns

- **Cloud Run** — mount a secret as an env var or a file, no code change:
  ```bash
  gcloud run deploy api --image=… \
    --set-secrets=DB_PASSWORD=wargames-launch-code:latest
  ```
- **GKE** — Secret Manager CSI driver mounts secrets as files in the pod
- **Workload Identity** — pods/workloads get a GCP SA, no exported keys
- **Terraform** manages the IAM binding; **CI** never sees the value

> **Speaker notes:** For SRE the win is that the value never lives in your deployment manifest, your CI variables, or a Kubernetes Secret you have to sync. Cloud Run's `--set-secrets` and the GKE CSI driver pull straight from Secret Manager at start/mount time. Combined with Workload Identity there are zero long-lived key files anywhere in the path.

---

# Consuming secrets: BigQuery & data engineers

- **BigQuery external connections** (Cloud SQL, Spanner, external DBs): store the DB password in Secret Manager; the connection's service account gets `secretAccessor`.
- **Dataflow / Beam:** fetch JDBC and API creds from Secret Manager inside the pipeline, gated by the worker service account — not pipeline options or job args.
- **Composer / Airflow:** the Secret Manager **secrets backend** resolves connections & variables from Secret Manager, not the metadata DB.
- **Data residency:** pin secrets with user-managed replication to the same region as your dataset.

> **Speaker notes:** For the data folks specifically: the recurring anti-pattern is a JDBC password sitting in a Dataflow job argument (visible in the console job graph) or in an Airflow Variable in the metadata DB. Both are readable by anyone with job/DB view access. Route them through Secret Manager and the worker/connection SA fetches at runtime. Airflow's built-in Secret Manager backend makes this a config change, not a code rewrite. And residency: keep the secret's replica region aligned with the data it protects.
