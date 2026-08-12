# GCP Secret Manager — 30-minute classroom session

> *"Shall we play a game?"* — a hands-on intro to Google Cloud Secret Manager,
> themed after **WarGames (1982)**. Deployed with Terraform, driven from the
> `gcloud` CLI, targeting project **`simplifymycloud-dev`**.

The running example: WOPR's nuclear **launch code** (`CPE1704TKS`) as the secret
we create, version, access, secure, and rotate.

## Repository layout

```
terraform/   Infrastructure as code — secret containers, IAM, CMEK, rotation
demos/       Runnable gcloud walkthroughs (run line-by-line in class)
slides/      Vanilla-markdown deck modules (--- per slide, import to Google Slides)
```

## The example resources (all prefixed `wargames-`)

| Resource | What it teaches |
|---|---|
| `wargames-launch-code` | Core secret lifecycle (create / version / access / destroy) |
| `wargames-wopr` (service account) | Least-privilege consumer — `secretAccessor` on one secret |
| `wargames-cmek-warplan` | CMEK deep dive + the KMS "kill switch" |
| `wargames-joshua-backdoor` | Rotation notifications via Pub/Sub |
| `wargames-rotation-events` (topic) | Where rotation messages land |

## Deploy

```bash
cd terraform
terraform init

# Terraform needs Application Default Credentials. Either run
#   gcloud auth application-default login
# OR hand it a token minted from your gcloud CLI session:
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)

# Set demo_impersonator to enable the least-privilege impersonation demo
# (grants YOU serviceAccountTokenCreator on the WOPR SA — Owner does NOT
# include this). Skip it and the impersonation demo won't run.
terraform apply -var="demo_impersonator=user:you@example.com"
```

Note: the `secretmanager.serviceAgent` IAM bindings depend on a `time_sleep`
because the Secret Manager service agent is created asynchronously and needs a
moment to propagate before it can be referenced in IAM.

Terraform creates the secret **containers, IAM, CMEK key, and rotation wiring**
— but **not** the secret values, on purpose (a `secret_version` resource would
store the plaintext in Terraform state). Add the values via the CLI:

```bash
source demos/00-env.sh
printf 'CPE1704TKS' | gcloud secrets versions add "$LAUNCH_SECRET" --data-file=-
```

## Run the demos (in order)

```bash
source demos/00-env.sh          # shared env vars + a friendly WOPR greeting
./demos/01-basics.sh            # create / version / access / disable / destroy
./demos/02-iam-least-privilege.sh
./demos/03-security-deep-dive.sh   # encryption at rest, CMEK kill switch, audit logs
./demos/04-rotation-lifecycle.sh
./demos/99-cleanup.sh           # tears everything down (terraform destroy)
```

Run the demo scripts **line-by-line** in class rather than all at once.

## Build the slide deck

Each `slides/NN-*.md` is one module. Concatenate for a single import:

```bash
cat slides/*.md > deck.md
```

Convention: `---` separates slides, `#`/`##` is the slide title, and speaker
notes are the `> **Speaker notes:**` blockquote at the end of each slide (move
them to the Google Slides notes pane on import).

---

## Status (as of 2026-08-12) — ready to present ✅

- ✅ Terraform applied to `simplifymycloud-dev` (11 resources live)
- ✅ Demos run live; **real captured output** baked into the slides
- ✅ Complete deck: slide modules `00`–`10` (WarGames themed)

**Teardown after the session:**

```bash
cd terraform && terraform destroy -var="demo_impersonator=user:you@example.com"
```
