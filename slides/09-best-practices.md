# Best practices (the "winning moves")

- **Grant `secretAccessor` on the secret, never the project** — smallest blast radius
- **One secret, one purpose** — don't stuff a JSON blob of 20 creds into one secret
- **Read `latest`, cache with a short TTL** — rotation with no redeploy
- **Keep values out of Terraform state** — manage containers/IAM in TF, inject values via CLI/pipeline
- **Turn on DATA_READ audit logs** — otherwise you can't see who read what
- **Label everything** — cost attribution, and targets for IAM Conditions / org policy
- **Automate rotation** — Pub/Sub → function → new version

> **Speaker notes:** If they remember one slide, make it this one. Each bullet maps to something we demoed. The recurring theme is minimize blast radius and keep a paper trail: least-privilege IAM, per-secret scoping, audit logs on, and never let plaintext leak into state or job args.

---

# Gotchas & footguns

- **`--data="value"` leaks** into shell history and `ps` → always `--data-file=-`
- **DATA_READ audit logs are OFF by default** → enable per project or you're blind
- **CMEK availability is on you** → disable/lose the key and the secret goes dark
- **`destroy` is irreversible** → disable first, destroy after a drain window
- **Project-level `secretAccessor` = skeleton key** → almost never what you want
- **`next_rotation_time` must be future** → and pin it, or Terraform diffs forever
- **Secret Manager doesn't rotate values** → it only *notifies*; you write the rotator
- **64 KiB max** per secret version → it's for secrets, not files/blobs

> **Speaker notes:** These are the real-world trip-ups. The CMEK one is the double-edged sword we showed with the kill switch — power and responsibility. The "doesn't rotate for you" one resets expectations for anyone coming from Vault's dynamic secrets. Call out the audit-logs-off default loudly; it surprises people during their first incident review.

---

# Cost (so nobody's surprised)

- **Active secret versions:** ~$0.06 per version per location / month
- **Access operations:** ~$0.03 per 10,000 operations
- **Rotation notifications / Pub/Sub:** negligible
- **CMEK:** you also pay Cloud KMS (~$0.06/key version/month + ops)

Practically free for this class; the cost lever at scale is **cache reads** (don't fetch on every request) and **destroy dead versions**.

> **Speaker notes:** Numbers are ballpark list price — check current pricing. The point for engineers: the thing that actually runs up a bill is a hot path that calls `access` on every single request instead of caching. That's both a cost and a rate-limit problem. Cache with a short TTL and you solve both.
