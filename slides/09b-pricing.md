# What does it cost? 🍕 Less than a slice.

**One model, three metered things. Everything else is free.**

| You pay for… | Price | Free every month |
|---|---|---|
| **Active versions** (ENABLED or DISABLED) | **$0.06** / version / mo · *per location* | first **6** free |
| **Access operations** (reads) | **$0.03** / 10,000 | first **10,000** free |
| **Rotation notifications** | **$0.05** each | first **3** free |
| Destroyed versions · create/enable/disable | **FREE** | — |

- **Automatic replication = ONE location.** User-managed into N regions bills **N×**.
- Free tier is **per billing account**, pooled across all projects, resets monthly.
- ⚠️ **CMEK adds a separate Cloud KMS bill** (~$0.06/key/mo + crypto ops) — not shown here.

**Our entire WarGames lab: ≈ $0.39/mo** — cheaper than one NYC slice. 🗽

> **Notes:**
> - The pizza line: this whole live demo costs less than a slice; a serious prod setup is still less than the whole pie
> - "Active" counts ENABLED **and** DISABLED — so destroy drained versions to stop paying (destroyed = free)
> - Prorated by real consumption: a version alive 2 days ≈ 2 days billed, not the month
> - The gotcha they'll ask: user-managed replication multiplies version cost by # of regions; automatic = billed as 1
> - Management ops (create/destroy/enable/disable) are FREE — you pay to *store* and *access*, never to *manage*
> - Google's own example: 250 versions + 20 rotations + 50k reads = $15.76/mo total