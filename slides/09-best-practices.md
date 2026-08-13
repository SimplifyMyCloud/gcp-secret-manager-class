# Best practices & top footguns

**Winning moves:**
- Grant `secretAccessor` **on the secret, not the project**
- One secret, one purpose (IAM is per-secret — don't bundle 20 creds)
- Read `latest` + cache (short TTL) · keep values **out of state**
- Turn on **DATA_READ** audit logs · label everything · automate rotation

**Footguns that bite:**
- `--data="…"` leaks → use `--data-file=-`
- DATA_READ logs **off by default** → enable proactively
- CMEK availability is on you · `destroy` is irreversible
- **64 KiB max** — it's for secrets, not blobs (big file → GCS, its key → Secret Manager)

> **Notes:**
> - Every winning move maps to a demo we ran
> - Our lab passes all: secret-scoped IAM, 0 in state, DATA_READ on, labeled, rotation automated
> - Cost ≈ $0.39/mo — only *active* versions bill, so destroy drained ones
