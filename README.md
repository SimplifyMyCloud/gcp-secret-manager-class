# GCP Secret Manager — 30-minute classroom session

> *"Shall we play a game?"* — a hands-on intro to Google Cloud Secret Manager,
> themed after **WarGames (1982)**. Deployed with Terraform, driven from the
> `gcloud` CLI, targeting project **`simplifymycloud-dev`**.

The running example: WOPR's nuclear **launch code** (`CPE1704TKS`) as the secret
we create, version, access, secure, and rotate.

## Repository layout

```
terraform/       Infrastructure as code — secret containers, IAM, CMEK, rotation
demos/           Runnable gcloud walkthroughs (run line-by-line in class)
slides/          PRESENTATION deck — 19 slides, ~25-30 min (--- per slide, Google Slides)
longer-version/  Full 35-slide deep-dive deck (backup / appendix / self-study)
```

Two decks, same content, different depth:
- **`slides/`** is the tight deck you actually present — one killer live demo per
  section, ~25-30 min. This is the default.
- **`longer-version/`** is the exhaustive 35-slide version (every demo, every deep
  dive). Use it as speaker prep, as a backup for deep questions, or for self-study.

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

## Build the slide deck (with speaker notes → notes pane)

`./build-deck.sh` assembles a deck folder into one import-ready file, converting
each `> **Notes:**` blockquote into an `<!-- HTML comment -->`. Marp and
md2googleslides both treat HTML comments as **speaker notes**, so on import they
land in the notes pane instead of on the slide.

```bash
./build-deck.sh slides         > deck.import.md        # the ~25-30 min deck
./build-deck.sh longer-version > deck-full.import.md   # the full deep-dive deck
```

Then get it into Google Slides via either tool:

```bash
brew install marp-cli && marp deck.import.md --pptx    # -> upload .pptx to Drive, open as Slides
# or, to push straight to Google Slides via the API:
md2gslides deck.import.md
```

Source convention: `---` separates slides, `#`/`##` is the slide title, notes are
the `> **Notes:**` blockquote at the end of each slide, and each note includes a
`🔧 LIVE:` line naming the gcloud command to run at that point.

## Run the terminal demo live (`demos/present.sh`)

A WarGames-themed runner that types each command at a `WOPR>` prompt and waits
for you before executing it live — perfect for pacing the demo on stage.

```bash
./demos/present.sh              # step through; hit ENTER to run each command
TYPE_SPEED=0 ./demos/present.sh # disable the typewriter effect (instant)
GO_WORD=launch ./demos/present.sh   # require typing 'launch'+ENTER instead of bare ENTER
START=5 ./demos/present.sh      # jump straight to section 5 (IAM)
```

It walks the same 8 sections as `slides/`, uses only safe/reversible operations
(disables are re-enabled; nothing is permanently destroyed), and leaves the lab
healthy for a re-run.

---

## Status (as of 2026-08-12) — ready to present ✅

- ✅ Terraform applied to `simplifymycloud-dev` (11 resources live)
- ✅ Demos run live; **real captured output** baked into the slides
- ✅ Complete deck: slide modules `00`–`10` (WarGames themed)

**Teardown after the session:**

```bash
cd terraform && terraform destroy -var="demo_impersonator=user:you@example.com"
```
