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

> **Notes:** SM owns the *when*; you own the *how* (only you know how to rotate in your upstream). Gotchas: grant the SM service agent pubsub.publisher on the topic BEFORE the secret references it; PIN next_rotation_time (not now()+X) or Terraform diffs forever.

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

> **Notes:** The payoff of the version model. "Joshua" was a static backdoor password a kid reused — rotate it so a stale copy is worthless.
> 🔧 LIVE: access latest → add version → access latest (moved) + access old (still works).
