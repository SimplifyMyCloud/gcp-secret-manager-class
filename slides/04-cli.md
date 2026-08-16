# CLI: add a value, then read it

```bash
# Add a version — via stdin so the value never hits ps / history / logs
printf 'CPE1704TKS' | gcloud secrets versions add wargames-launch-code --data-file=-
#   Created version [1] of the secret [wargames-launch-code].

gcloud secrets versions access latest --secret=wargames-launch-code   # -> CPE1704TKS
gcloud secrets versions access 1      --secret=wargames-launch-code   # pinned, same payload
```

- **The `|` pipes the value into the command's stdin** — `--data-file=-` reads *from* stdin, so the secret never appears as a command argument.
- **Never `--data="secret"`** — as an argument it leaks to `ps`, shell history, and logs.
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
> - **Immutable & append-only** — no "edit," only add (same as a git commit)
> - **Disable = light switch** (reversible — flip it back) · **destroy = shredder** (permanent)
> - Golden rule: **disable → watch for breakage → destroy** after a drain window; never destroy blind
> - Destroy deletes the *payload* but keeps the version's **metadata** → auditors see it existed and when it died (ties to CIS 3.5 secure disposal)
> - Destroyed versions are **free** — only active versions bill
> - 🔧 LIVE: disable a version → show `FAILED_PRECONDITION` → destroy → row flips to `destroyed` (watch the error message change)
