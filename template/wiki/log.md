---
title: Session log
type: log
updated: YYYY-MM-DD
---

# Session log

Append-only. Every session that touches code or the vault should leave an entry here. New entries go at the **top** so the most recent activity is the first thing the next session sees.

Format:

```
## YYYY-MM-DD HH:MM — {app} on Server {N}
- modules touched: [list or -]
- integrations verified/updated: [list or -]
- notable decisions or debugging added: [list or -]
```

---

_No entries yet. The first session that runs `vs` and modifies anything will add the first entry here._
