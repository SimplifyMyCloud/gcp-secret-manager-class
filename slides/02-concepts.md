# Secret vs. Version — it's just Git

**Secret = git repo · Version = git commit**

```
wargames-launch-code   ← the "repo": name + IAM + replication (NO value)
 └── v1  CPE1704TKS   [DESTROYED]   payload gone, metadata kept
 └── v2  DL6913THX    [ENABLED]     ← latest  (like HEAD)
```

- **Secret** = the repo — name, access (IAM), where it lives; **never the value**
- **Version** = a commit — one immutable value; you **add**, never edit
- **Pin a version by number** — like a commit hash, just an integer; **`latest`** = newest enabled
- States: **ENABLED → DISABLED** (reversible) **→ DESTROYED** (permanent, metadata remains)

> **Notes:**
> - The whole model in one line: **Secret = git repo, Version = git commit**
> - Name / IAM / replication live on the repo; the bytes live in the commits (versions)
> - Immutable & append-only → free history, instant rollback, safe rotation (like `git log`)
> - `latest` = HEAD · `access <N>` = `git checkout <sha>` · `versions list` = `git log`
> - Analogy is directional — no branching, versions are integers (not SHAs), and truly immutable (no force-push/rewrite)
> - Disable = light switch (reversible); destroy = shredder — disable first
> - 🔧 LIVE: `versions list wargames-launch-code` → `access latest` → DL6913THX

---

# Replication: where the ciphertext lives

- **Automatic** (default) — Google picks the regions + manages the key. **Use this.**
- **User-managed** — you pin the region(s); needed for **data residency** or **CMEK** (your own key).

> **Notes:**
> - "Know it exists + when to switch" — that's the whole slide, keep it moving
> - User-managed is the prerequisite for CMEK (returns in the Security section)
> - 🔧 LIVE (optional): `gcloud secrets describe wargames-cmek-warplan --format="yaml(replication)"`
