# Rotation: what Secret Manager does (and doesn't)

- ✅ It **reminds** you: fires a **Pub/Sub message** on a schedule
- ❌ It does **not** generate new credentials for you
- **Your** automation closes the loop:

```
next_rotation_time fires
  → Pub/Sub topic: wargames-rotation-events
    → Cloud Function / Cloud Run job
      → mint new credential in the upstream (DB, API provider)
      → gcloud secrets versions add   (new ENABLED version = latest)
      → disable old version after a drain window
```

> **Speaker notes:** Set the right expectation: Secret Manager is not a dynamic-secrets broker like Vault. It's a scheduler + notifier. The actual "generate a new DB password and store it" logic is code you write, triggered by the Pub/Sub message. That separation is deliberate — only you know how to rotate a credential in your specific upstream system.

---

# Rotation config (from `rotation.tf`)

```hcl
resource "google_secret_manager_secret" "rotating_api_key" {
  secret_id = "wargames-joshua-backdoor"
  replication { auto {} }

  topics { name = google_pubsub_topic.rotation.id }

  rotation {
    next_rotation_time = "2026-09-01T00:00:00Z"
    rotation_period    = "2592000s"   # 30 days
  }
}
```

The Secret Manager **service agent** needs `pubsub.publisher` on the topic (also in Terraform). Live config on the deployed secret:

```yaml
# gcloud secrets describe wargames-joshua-backdoor --format="yaml(topics,rotation)"
rotation:
  nextRotationTime: '2026-09-01T00:00:00Z'
  rotationPeriod: 2592000s
topics:
- name: projects/simplifymycloud-dev/topics/wargames-rotation-events
```

> **Speaker notes:** Two gotchas encoded here: (1) the service agent must have publish rights on the topic *before* the secret references it, or creation fails — that's why Terraform has an explicit dependency. (2) `next_rotation_time` must be a future timestamp; we pin it rather than compute `now()+30d` so Terraform doesn't show a perpetual diff on every plan.

---

# Zero-downtime rotation for consumers

- Apps read **`latest`**, never a pinned version number
- Adding a new version flips `latest` — **no redeploy**
- Old version stays **ENABLED** during a drain window, then **DISABLED**, then **DESTROYED**
- Cache the value with a short TTL so rotation propagates in minutes

> **Speaker notes:** The consumer-side contract is simple: read `latest`, cache briefly (say 5 minutes), and you get near-seamless rotation. Don't cache forever, or rotation won't take effect; don't fetch on every single request either, or you'll hammer the API and rack up reads. Short TTL is the sweet spot. Keep the old version enabled long enough for all caches to expire before you disable it.
