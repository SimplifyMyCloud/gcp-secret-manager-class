# CLI: create a version (add the value)

```bash
# Pipe the value via stdin so it never appears in `ps` or shell history.
printf 'CPE1704TKS' \
  | gcloud secrets versions add wargames-launch-code --data-file=-
```

```
Created version [1] of the secret [wargames-launch-code].
```

- `--data-file=-` reads from **stdin** — the value is not a CLI argument
- Use `--data-file=./path` for binary secrets (certs, keystores)

> **Speaker notes:** Never do `--data="mypassword"` — that string ends up in your shell history, in `ps aux`, and possibly in your terminal scrollback and any command-logging. `--data-file=-` with a piped `printf` is the safe idiom. For a file, point at the path. Max secret size is 64 KiB.

---

# CLI: access a version

```bash
gcloud secrets versions access latest --secret=wargames-launch-code
# -> CPE1704TKS

gcloud secrets versions access 1 --secret=wargames-launch-code
# -> CPE1704TKS  (explicit pin)
```

- `latest` is an **alias** that always resolves to the newest enabled version
- Apps should read `latest` so rotation needs no redeploy

> **Speaker notes:** Live-demo this. Then add a v2 and show that `latest` moves but the pinned `1` stays. The `access` verb is the sensitive one — it returns plaintext and is the action gated by `roles/secretmanager.secretAccessor` and logged as a DATA_READ audit event.

---

# CLI: versioning is immutable & append-only

```bash
printf 'DL6913THX' \
  | gcloud secrets versions add wargames-launch-code --data-file=-

gcloud secrets versions list wargames-launch-code \
  --format="table(name, state, createTime)"
```

```
NAME  STATE     CREATE_TIME
2     ENABLED   2026-08-03T…      ← latest
1     ENABLED   2026-08-03T…
```

> **Speaker notes:** There is no "edit". Every change is a new version, giving you a complete, auditable history and instant rollback (just re-point apps or disable the bad version). This append-only model is what makes rotation safe.

---

# CLI: disable → destroy (the safe teardown)

```bash
# Reversible: block access but keep the bytes
gcloud secrets versions disable 1 --secret=wargames-launch-code

# Irreversible: delete the payload, keep audit metadata
gcloud secrets versions destroy 1 --secret=wargames-launch-code
```

```
Disabled version [1]…
Destroyed version [1]…   # state is now DESTROYED; row still visible
```

> **Speaker notes:** The disable-then-destroy pattern is your rotation safety net. Disable the old version, watch dashboards/logs for anything still trying to use it, and only destroy after a drain window. Destroy is permanent — the payload is gone — but the version's metadata sticks around so auditors can see it existed and when it was destroyed.
