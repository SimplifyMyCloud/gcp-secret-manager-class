# Consuming secrets: the one pattern

**Fetch at runtime, using the workload's own identity. Never hardcode, never commit.**

- **App devs** — client library + Application Default Credentials (no "secret zero"):
  ```python
  client.access_secret_version(name=".../wargames-launch-code/versions/latest")
  # payload comes back base64 → decode. (Under the hood: an authenticated REST GET.)
  ```
- **SRE / platform** — Cloud Run `--set-secrets=DB_PASSWORD=wargames-launch-code:latest`,
  GKE CSI driver, **Workload Identity** → no key files; value never in a manifest or CI.
- **BigQuery / data** — external-connection SA, Dataflow worker SA, Airflow SM backend all
  get `secretAccessor` and fetch at runtime — **not** job args / pipeline options / metadata DB.

> **Notes:**
> - Every consumer = an SA with `secretAccessor` fetching at runtime
> - Data anti-pattern: JDBC pw in a Dataflow job arg / Airflow Variable (same leak as `--data=`)
> - Pin regional secrets for residency
> - 🔧 LIVE (optional): curl REST `:access` → base64 decode = DL6913THX
