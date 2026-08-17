# Two things to remember

**📏 It's for *secrets*, not *blobs* — 64 KiB max**
Passwords, keys, tokens, connection strings. **Not** files.
Big file → **GCS** · put *its key* → **Secret Manager**.

**💸 It's basically free — ≈ $0.39/mo**
You only pay for **active versions**, so `destroy` drained ones.
No budget excuse not to use it.

> **Notes:**
> - Everything else today = one habit: runtime fetch, least privilege, rotate, audit — this is just the recap
> - 64 KiB: it's a vault for the *key to the kingdom*, not the kingdom. Encrypt a big file, store the file in GCS, keep the DEK/password here
> - Cost: $0.06/active version/mo + tiny access fee — a rounding error. Destroyed versions are free
