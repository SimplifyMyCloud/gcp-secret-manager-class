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
> - NO HUMAN required: the manual CLI pipe (`printf … | gcloud … add`) is the demo/one-off path only. Production rotation is machine-to-machine
> - GCP best practice = an event-driven **Cloud Run / Cloud Functions (2nd gen)** handler, triggered by the Pub/Sub notification (Eventarc / push subscription) — NOT cron, NOT a person
> - It runs as a **dedicated service account with only `secretVersionAdder`** — write-only: can add a new version, CANNOT read existing values (least privilege applied to the rotation job itself)
> - Two steps inside the handler: ① mint a fresh cred via the upstream admin API → ② add it as a new version (the automation calls the API — you never touch the CLI)
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
> - Zero downtime = **overlap, not timing** — old + new both valid at once
> - Apps read **`latest`** → pointer moves, no redeploy
> - Old stays **ENABLED** through a drain window → disable/destroy only after everyone's moved
> - Cache TTL = how fast the drain resolves
> - "Joshua" = a reused static backdoor; rotate so a stale copy is worthless
> - 🔧 LIVE: access latest → add version → latest moved, old still works
