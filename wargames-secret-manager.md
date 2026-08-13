# GCP Secret Manager

### Storing secrets the right way — a live 25 minutes

Simplify My Cloud · Platform Team

> **Notes:**
> - All live in `simplifymycloud-dev` — Terraform + gcloud, no slideware
> - Running example: WOPR's nuclear launch code (WarGames, 1982)
> - Opener: "Shall we play a game?"

---

# Agenda (~25 min)

1. **Why** Secret Manager — 2 min
2. **Concepts** — secret vs version, replication — 3 min
3. **Deploy as code** — 2 min
4. **CLI lifecycle** — 3 min
5. **IAM & least privilege** — 3 min
6. **Security** — encryption, CMEK kill switch, audit — 5 min
7. **Rotation** — 3 min
8. **Consuming secrets** — 2 min · Wrap + cheat sheet — 2 min

> **Notes:**
> - One killer live demo per section
> - Deep-dive material → full backup deck if asked
> - Pace: ~1 slide/min

---

# Why Secret Manager?

**The problem — where secrets live today, and why each is a trap:**

- Hardcoded in source → in Git history **forever**
- `.env` / plaintext env vars → visible in `ps`, logs, crash dumps
- `terraform.tfvars` / state → sits in your VCS & state bucket
- Slack / tickets / spreadsheets → ungoverned, unauditable

**What Secret Manager adds that none of those have:**

| | Access control | Audit | Rotation | Ops |
|---|---|---|---|---|
| env vars / files | ❌ | ❌ | ❌ | low |
| self-hosted Vault | ✅ | ✅ | ✅ | **high** |
| **Secret Manager** | ✅ IAM | ✅ built-in | ✅ notify | **none** |

> **Notes:**
> - Every bad location shares one flaw: no access control, audit, rotation, or revocation
> - Secret Manager = managed API (on Cloud KMS) that adds exactly those four
> - Not a KV store (64 KiB max); Vault only for dynamic secrets / multi-cloud
> - 🔧 LIVE (optional): `gcloud secrets list --filter=name:wargames` → names, never values

---

# Core concept: Secret vs. Version

```
wargames-launch-code   (container — name + IAM + replication, NO value)
 └── Version 1   "CPE1704TKS"    [DESTROYED]  payload gone, metadata kept
 └── Version 2   "DL6913THX"     [ENABLED]    ← "latest"
```

- **Secret** = container: policy, IAM, replication — never the value
- **Version** = one immutable payload; add a new one, never edit
- Read by number or the alias **`latest`** (newest enabled)
- States: **ENABLED** → **DISABLED** (reversible) → **DESTROYED** (permanent, metadata remains)

> **Notes:**
> - THE mental model: IAM on the secret, bytes on the versions
> - Immutable = free history, instant rollback, safe rotation
> - Disable = light switch (reversible); destroy = shredder — disable first
> - 🔧 LIVE: `versions list wargames-launch-code` → `access latest` → DL6913THX

---

# Replication: where the ciphertext lives

- **Automatic** (default) — Google replicates + manages the key. Use this unless you have a reason not to.
- **User-managed** — you pin the region(s). Required for **data residency** and for **CMEK** (your own key).

```yaml
# wargames-launch-code           # wargames-cmek-warplan
replication:                     replication:
  automatic: {}                    userManaged:
                                     replicas:
                                     - location: us-central1
                                       customerManagedEncryption:
                                         kmsKeyName: .../wargames-key
```

> **Notes:**
> - CMEK requires user-managed replication (key + secret, same region)
> - Data eng: pin the secret to your dataset's region for residency
> - 🔧 LIVE: `gcloud secrets describe wargames-cmek-warplan --format="yaml(replication)"`

---

# Deploy as code — and keep values OUT of state

```hcl
resource "google_secret_manager_secret" "launch_code" {
  secret_id = "wargames-launch-code"
  replication { auto {} }
}
# NOTE: no google_secret_manager_secret_version here — on purpose.
```

**Terraform builds the container, IAM, CMEK, rotation. The VALUE is added via CLI** so plaintext never lands in `terraform.tfstate`.

```
$ grep -c "CPE1704TKS\|DL6913THX" terraform.tfstate
0            ← the secret value is NOT in state
$ gcloud secrets versions access latest --secret=wargames-launch-code
DL6913THX    ← it lives in the service, added out-of-band
```

> **Notes:**
> - Footgun: a `secret_version` resource writes plaintext into state (bucket-readable)
> - Policy as code (reviewable PR); inject values via CLI/pipeline
> - `.gitignore` blocks state & tfvars
> - 🔧 LIVE: the two commands above

---

# CLI: add a value, then read it

```bash
# Add a version — via stdin so the value never hits ps / history / logs
printf 'CPE1704TKS' | gcloud secrets versions add wargames-launch-code --data-file=-
#   Created version [1] of the secret [wargames-launch-code].

gcloud secrets versions access latest --secret=wargames-launch-code   # -> CPE1704TKS
gcloud secrets versions access 1      --secret=wargames-launch-code   # pinned, same payload
```

- `--data-file=-` = stdin. **Never `--data="secret"`** — that leaks to `ps` & shell history.
- Apps read **`latest`** (rotation with no redeploy); pin a number only for controlled rollouts.

> **Notes:**
> - `access` = the one sensitive verb: returns plaintext, needs `secretAccessor`, audited
> - Cache with a short TTL; don't call it per-request
> - 🔧 LIVE: add + access latest + access 1

---

# CLI: immutable, then the safe teardown

```bash
gcloud secrets versions add wargames-launch-code --data-file=-   # new version; old ones frozen
gcloud secrets versions disable 1 --secret=wargames-launch-code  # reversible — access now fails
gcloud secrets versions destroy 1 --secret=wargames-launch-code  # IRREVERSIBLE — payload deleted
```

```
NAME  STATE
2     enabled       ← still readable
1     destroyed     ← payload gone, metadata row remains for audit
```

> **Notes:**
> - No "edit" — only add (append-only)
> - Disable → observe → destroy = the safety net
> - Destroyed keeps metadata (audit) and is free
> - 🔧 LIVE: disable a spare version → FAILED_PRECONDITION → destroy

---

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
> - Reading the value (`secretAccessor`) ≠ seeing it exists (`viewer`)
> - Resource-scoped IAM = blast radius of one secret
> - `secretVersionAdder` = write-only rotation role

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

---

# Security: encryption at rest + CMEK

- **Always on.** AES-256 before it touches disk. No off switch.
- **Envelope:** payload ← DEK ← wrapped by a KEK in Cloud KMS.
- Default KEK is **Google-managed** (zero config). **CMEK** = you own the KEK.

**What CMEK buys you:**
- You control **key rotation** cadence (ours: 90 days, in code)
- **Separation of duties** — a KMS admin can revoke crypto access independent of secret IAM
- Required by **PCI / FedRAMP / internal policy**

> **Notes:**
> - Envelope (DEK ← KEK): rotate/revoke the KEK without re-encrypting data
> - CMEK = Google can't decrypt without your key enabled
> - Only user of our key = the SM service agent — a grant you can revoke
> - 🔧 LIVE (optional): `gcloud kms keys get-iam-policy wargames-key …`

---

# The "break glass" controls

**Need a secret to stop being readable NOW? Layer three controls:**

```bash
# 1) Disable the VERSION — INSTANT (fails at the SM layer, before KMS)
gcloud secrets versions disable 2 --secret=wargames-cmek-warplan
#    -> access now returns FAILED_PRECONDITION: DISABLED

# 2) Revoke IAM (secretAccessor)  — stops authorized callers
# 3) Disable the CMEK KEY — the crypto kill switch (see note on timing)
```

> **Notes:**
> - Honest: KMS-key disable is NOT instant — SM caches payloads (secs–mins)
> - Key disable guarantees no NEW decryption; DESTROY key = permanent crypto-shred
> - Instant stop = disable the VERSION (SM layer, before KMS)
> - Defense in depth: version-disable + revoke IAM + disable key
> - 🔧 LIVE: version disable → instant FAILED_PRECONDITION → re-enable

---

# Every access is audited

```
### DATA_READ (AccessSecretVersion) — who read what, just now:
23:52:15  wargames-wopr@…   wargames-cmek-warplan/versions/latest   (denied attempt, logged)
23:52:14  wargames-wopr@…   wargames-launch-code/versions/latest
00:18:42  chris@simplifymy.cloud   wargames-cmek-warplan
```

- **ADMIN_WRITE** logged by default; **DATA_READ** must be **enabled per project**
- Who / what / when / from where — immutable; impersonation attributed to the real identity
- Export to **BigQuery / SIEM** → alert on anomalies (new reader, odd region, spike)

> **Notes:**
> - Prevention = IAM; detection = audit logs
> - Turn DATA_READ on proactively or you're blind in an incident
> - Even denied attempts are logged — your intrusion signal
> - 🔧 LIVE: `gcloud logging read '…AccessSecretVersion…' --freshness=1h`

---

# Rotation: Secret Manager notifies, YOU rotate

- ✅ Fires a **Pub/Sub message** on a schedule · ❌ does **not** mint credentials

```
next_rotation_time fires → Pub/Sub: wargames-rotation-events
  → your Cloud Function/Run job → mint new cred upstream
    → gcloud secrets versions add  (new version = latest)
      → disable old after a drain window
```

```yaml
rotation: { nextRotationTime: '2026-09-01', rotationPeriod: 2592000s }   # 30 days
topics:  [ projects/…/topics/wargames-rotation-events ]
```

> **Notes:**
> - SM owns the *when*; you own the *how* (your upstream)
> - Gotcha: grant SM agent pubsub.publisher BEFORE the secret references the topic
> - Gotcha: PIN next_rotation_time (not now()+X) or Terraform diffs forever

---

# Zero-downtime cutover (live)

```
BEFORE   latest (v3) -> joshua-reissued-193931
ROTATE   Created version [4]
AFTER    latest (v4) -> joshua-rotated-210547     ← moved, no redeploy
         old   (v3)  -> joshua-reissued-193931    ← stragglers still work (drain)
```

- Apps read **`latest`** → pick up new value on next fetch, no redeploy
- Old version stays **ENABLED** during drain → no cutover outage → then disable → destroy
- Cache with a short TTL so rotation propagates in minutes

> **Notes:**
> - Payoff of the version model — invisible to consumers
> - "Joshua" = a static backdoor a kid reused; rotate so a stale copy is worthless
> - 🔧 LIVE: access latest → add version → latest moved, old still works

---

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

---

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

---

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
