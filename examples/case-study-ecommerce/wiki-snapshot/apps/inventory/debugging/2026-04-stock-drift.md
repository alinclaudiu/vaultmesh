---
title: 2026-04 stock drift incident
type: debugging
status: active
owners: [inventory]
updated: 2026-04-19
---

# 2026-04 stock drift

## Symptom

On 2026-04-18, branch-02 reported physical inventory counts that diverged from the system by 12–15 units across 8 SKUs. Branch-04 reported similar (smaller) divergences for 3 SKUs. Both branches had been running normally; no obvious trigger.

## Investigation timeline

**18:30** — Branch-02 manager called the on-call. Initial thought: theft or miscounting on their end. Asked for a photo of their physical count sheet, received it, sat with it for 20 minutes — counts looked plausible.

**19:15** — Pulled `audit_log` for branch-02 over the past 7 days. Counted SALE entries. Compared to pos's sales report for the same period. **Inventory had ~14% fewer SALE entries than pos had sales.**

**20:00** — Suspect: daily-sales import is dropping rows. Pulled the daily batches from pos (we keep them in `raw_uploads/`). Counted lines per batch. Compared to `audit_log` SALE inserts per `external_batch_id`. Confirmed: about 1 in 7 batches had partial application.

**21:30** — Read `app/services/daily_sales_import.py`. Found the bug (see Root cause below).

**22:30** — Wrote a temporary dedup hack and deployed it. Stopped the bleeding.

**(next morning, 2026-04-19) 09:00–17:00** — Wrote the proper fix and the rebuild plan. See Fix and Prevention below.

## Root cause

The import code looked roughly like:

```python
for line in batch.lines:
    if not already_imported(line.line_id):
        apply_adjustment(line)
        mark_imported(line.line_id)
```

Two problems compounded:

1. **`already_imported` checked by `line_id`, not by `(batch_id, line_id)`.** When a pos branch uploaded a batch, then re-uploaded it after a network glitch (which the offline-mode design *encourages*), the second upload had the *same line_ids*. We thought we'd already imported them. But the network glitch had cut the first upload mid-stream, and only ~85% of lines had actually been applied + marked.

2. **No transaction wrapping.** `apply_adjustment` and `mark_imported` were two separate DB statements. If anything (DB hiccup, deploy at the wrong time) happened between them, the adjustment would apply but the line wouldn't get marked as imported. Next upload, we'd re-apply.

Together: the partial-upload + non-transactional-marking interaction meant *some lines applied 0 times and some applied 2 times*, and which ones varied with luck.

## Fix

Two-part:

### Immediate (deployed 2026-04-18 22:30)

Hot-fix added a `(batch_id, line_id)` composite check before applying. Stopped further drift but didn't fix existing divergence.

### Proper (deployed 2026-04-19, see [[apps/inventory/modules/daily-sales-import]])

1. **Idempotency key change.** Now: `external_batch_id` (assigned by pos at batch creation, stable across retries) + `line_seq` (1-indexed within batch). Composite uniqueness in DB.
2. **Transaction wrapping.** Apply and mark in a single DB transaction. Either both succeed or both fail.
3. **External_batch_id required.** Schema change on integration 02 — see Breaking changes log on [[integrations/02-pos--inventory--daily-sales]].

### Reconciliation

Used the audit log + the original raw batch files to reconstruct what *should* have been applied. Wrote a one-off script (`scripts/reconcile_2026_04.py`) that computed the corrective adjustment per branch per SKU. Applied with `reason=MANUAL_CORRECTION, actor='reconciliation_script'` so the audit log reflects the truth.

The `inventory-rebuild` runbook ([[apps/inventory/runbooks/inventory-rebuild]]) was written from this experience.

## Prevention

- The `external_batch_id` requirement is now strictly enforced; pos integration tests verify it
- A weekly cron compares `audit_log` SALE counts against pos's sales-report API — alerts if divergence > 1%
- Code review rule: any service that mutates `stock_levels` must use a transaction. Linter pending.

## Lessons

- We had been confident in the daily-sales import for ~2 years. **Idempotency bugs hide for a long time** because most network glitches resolve on the first retry.
- The `audit_log` is genuinely sacred. Reconstructing the correct state would have been impossible without it.
- Don't assume that "we always retry, it's fine" — verify it under partial-failure conditions.
