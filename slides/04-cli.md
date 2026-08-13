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

> **Notes:** `access` is the one sensitive verb — it returns plaintext, needs `secretAccessor`, and is audited. Cache with a short TTL; don't call it per-request.
> 🔧 LIVE: add + access latest + access 1.

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

> **Notes:** No "edit" — only add. Disable→observe→destroy is the rotation safety net. Destroyed versions keep metadata (auditor can see it existed and when it died). Destroyed = also free.
> 🔧 LIVE: disable v-old on a spare secret, show FAILED_PRECONDITION, then destroy.
