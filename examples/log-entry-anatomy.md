# Anatomy of a good log entry

The single most important piece of writing discipline in VaultMesh. A 60-second read.

## The format (verbatim)

```markdown
## YYYY-MM-DD HH:MM — {app} on Server {N}
- modules touched: [list or -]
- integrations verified/updated: [list or -]
- notable decisions or debugging added: [list or -]
```

That's it. Three bullets. New entries at the **top** of `log.md`.

## What makes an entry good

Compare three versions of the same session.

### Bad — too vague

```markdown
## 2026-04-19 — inventory
- Fixed a bug in daily sales import
```

What's wrong:
- No time
- No server number (we have multiple servers)
- No specifics — *which* daily sales import? The producer side or consumer side?
- No reference to the integration page or debugging page that captures the detail
- No information about whether the integration changed (= other servers are affected)

A future engineer reading this 6 months from now learns nothing useful.

### Mediocre — has detail but no signals

```markdown
## 2026-04-19 16:30 — inventory on Server 2
- Worked on app/services/daily_sales_import.py
- Made the idempotency check stricter
- Refactored a few things while I was in there
```

What's wrong:
- "Refactored a few things" hides scope
- No mention that the integration contract changed (a critical signal for the *consumer* on a different server)
- No link to the debugging page (the most valuable artifact from this session)
- The reader has to read code to understand what changed

### Good — terse but pointed

```markdown
## 2026-04-19 16:30 — inventory on Server 2
- modules touched: app/services/daily_sales_import.py (added idempotency guard)
- integrations verified/updated: 02 (Breaking changes log: external_batch_id now strictly required; rejection if missing)
- notable decisions or debugging added: apps/inventory/debugging/2026-04-stock-drift.md — root cause + fix + prevention; this is the big one this month
```

What's right:
- Time and server number → the next session can correlate with what happened on other servers around the same time
- Specific file + parenthetical for the *what* and *why*
- Integration change is **flagged as breaking**, with the contract number — a session on pos (Server 3) that runs `vs` tomorrow knows immediately that a consumer-side change is needed
- Pointer to the debugging page → the big artifact lives there, not in the log entry; the log just signposts

## The signals each line carries

| Line | What another server's session learns from reading it |
|---|---|
| `## ... — {app} on Server {N}` | Who, what, when, where |
| `- modules touched:` | What code is now potentially different from what they remember |
| `- integrations verified/updated:` | **The single most important line for cross-server awareness.** A change here means consumers must check the contract. No change = signal that nothing broke for them. |
| `- notable decisions or debugging added:` | Where to look for the *real* artifacts. Log entries are signposts, not destinations. |

## Common failure modes

### Skipping the entry entirely
The cardinal sin. A change without a log entry is invisible to the rest of the mesh. **Always log.** Even a one-line "minor refactor, no integration impact" is better than nothing — it tells future readers "I looked, and nothing was load-bearing."

### Writing the entry but not the artifact
"notable decisions or debugging added: figured out why X was happening, fixed it" — without a debugging page. Now the log entry can't help anyone, because there's nowhere to look up the detail. **If something is worth a log mention, it's worth a wiki page.**

### Burying integration impact
The most expensive failure mode. If you change a contract and don't flag it on the contract's Breaking changes log AND in the log entry, the consumer's next session has no chance of noticing. Future incidents follow.

### Past-tense reflection vs forward-looking signaling
Bad: "Today I worked on X."
Good: "X changed; consumers should expect Y."

The log isn't your diary. It's a message to other sessions.

## A test for your log entry

Read it back to yourself as if you were a sleepy on-call engineer at 3 a.m. on another server. Two questions:

1. **Do I know whether this affects me?** (If you can't tell from the entry, it's incomplete.)
2. **Do I know where to look for more detail?** (If the entry is self-contained but doesn't link to the artifact, you've put the detail in the wrong place.)

If the answer to either is no, edit the entry before `vp`.

## A note on terseness

Log entries should be **short**. The detail belongs in the wiki page, the debugging page, the contract's Breaking changes log, etc. The log entry's job is to say "here's where to look." Two-paragraph log entries are usually a sign that someone wrote prose instead of pointing.

Good entries are 3–8 lines. If yours is consistently 20+, the log might be doing a job that should belong to a separate artifact.
