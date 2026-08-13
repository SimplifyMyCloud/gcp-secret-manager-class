# 🎤 Presenter run-of-show — GCP Secret Manager (WarGames)

**Target: ~22 min content + ~5 min Q&A.** Deck: `slides/` (19 slides). Live terminal: `demos/present.sh`.

---

## ✅ Pre-flight (morning of)

```bash
# 1. Refresh auth (tokens expire overnight)
gcloud auth login
gcloud auth application-default login          # only needed if re-deploying

# 2. Health check — all three should succeed
gcloud secrets list --filter="name:wargames" --project simplifymycloud-dev
gcloud secrets versions access latest --secret=wargames-launch-code --project simplifymycloud-dev

# 3. Open the green CRT terminal (Ghostty), font-size 20
# 4. Deck open in Google Slides (build with ./build-deck.sh slides > deck.import.md)
```

Launch the demo console (advance word = **`pencil`**):
```bash
TYPE_SPEED=0.02 ./demos/present.sh
```
Knobs: `TYPE_SPEED=0` (instant) · `START=6 ./demos/present.sh` (jump to a section) · `GO_WORD= ` (bare ENTER).

---

## 🎬 Run of show (8 sections)

| # | Section (slides) | The one live demo | Punch line |
|---|---|---|---|
| 1 | **Why** (1) | `secrets list` — names, never values | 4 things a `.env` can't give you |
| 2 | **Concepts** (2) | `versions list` + `access latest` | secret = container, version = payload, read `latest` |
| 3 | **Deploy** (1) | `grep value terraform.tfstate` → 0 | policy as code; values out of state |
| 4 | **CLI** (2) | add via stdin, disable→re-enable | immutable, append-only, safe teardown |
| 5 | **IAM** (2) | impersonate WOPR: allowed vs DENIED | least privilege enforcing itself |
| 6 | **Security** (3) | **version-disable** (instant) + audit log | kill switch + who-read-what |
| 7 | **Rotation** (2) | live cutover: `latest` moves, old drains | SM notifies; you rotate; zero-downtime |
| 8 | **Consuming** (1) | REST `:access` → base64 decode | runtime fetch + ambient identity |
| — | **Close** (2+1) | cheat sheet + "only winning move" | don't hardcode/commit/log — centralize |

**Kill-switch note:** demo the **version disable** (instant). Explain the *KMS key* disable is the crypto-shred but caches for seconds–minutes — don't wait for it live.

---

## 🧯 If something breaks

| Symptom | Fix |
|---|---|
| `Reauthentication failed` | `gcloud auth login` |
| Terraform `could not find default credentials` | `export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)` |
| Impersonation `PERMISSION_DENIED: getAccessToken` | token-creator still propagating — wait ~1 min, or it's the *expected* denial on the wrong secret |
| A demo command errors | `present.sh` continues; just narrate and move on |
| Ghostty config error toast | harmless (bad lines skipped); dismiss |

---

## 🧹 Teardown (after the session)

```bash
cd terraform && terraform destroy -var="demo_impersonator=user:chris@simplifymy.cloud"
```

Stops the ~$0.39/month clock and returns the project to zero.
