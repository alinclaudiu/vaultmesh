---
title: End-of-day reconciliation
type: flow
status: active
owners: [pos, inventory, admin]
updated: 2026-04-22
---

# End-of-day reconciliation

The flow that closes the books for in-store sales each day. Initiator: pos (per branch). Result: inventory has up-to-date stock levels, admin has the day's sales summary.

## Trigger

The 23:50 cron on each pos branch instance.

## Expected outcome

- Each branch's daily sales batch is uploaded to inventory ([[integrations/02-pos--inventory--daily-sales]])
- inventory has applied the corresponding stock decrements
- admin's morning summary email reflects the previous day's totals

## Apps involved

- [[apps/pos]] (per branch, all four)
- [[apps/inventory]]
- [[apps/admin]]

## Steps

### 1. pos: assemble the batch

At 23:50 local time on each branch, pos's `daily_batch` cron runs:

1. Reads the day's sales from local SQLite
2. Aggregates into a JSON envelope + JSONL line file
3. Generates `external_batch_id = "<branch>-<YYYY-MM-DD>-001"` (the `001` suffix increments only on retries — but the base part is *stable* per branch per day)
4. Saves the batch locally to `/var/lib/pos/batches/` for replay if the upload fails

Code: [[apps/pos/modules/daily-batch]].

### 2. pos: upload to inventory

POSTs the batch to inventory's daily-sales endpoint ([[integrations/02-pos--inventory--daily-sales]]).

- On success: marks the batch as uploaded, emits a log entry
- On 4xx: alarms; humans investigate
- On 5xx or network error: retries with exponential backoff, up to 5 times. **Same `external_batch_id` on retries** — this is the idempotency fix from 2026-04 (see [[apps/inventory/debugging/2026-04-stock-drift]])
- After 24h of failures: alarms loudly; ops on-call pages

### 3. inventory: validate and apply

inventory receives the batch:

1. Validates `external_batch_id` is unique (or, if present, that no records yet exist for it — supports retry)
2. For each line, calls `stock_adjustments.adjust_stock(...)` with `reason=SALE`
3. Each adjustment writes to `audit_log` with the composite `(external_batch_id, line_seq)` for traceability

Code: [[apps/inventory/modules/daily-sales-import]] → [[apps/inventory/modules/stock-adjustments]].

### 4. admin: morning summary (independent path)

At 06:00 next day, admin's `daily_summary` cron:

1. Queries the `audit_log` (read-only) for SALE entries from the previous business day
2. Aggregates by branch and SKU
3. Emails a summary to ops@

Code: [[apps/admin/modules/customer-support]] (the summary is part of the support tooling).

This step doesn't require inventory or pos to be up by 06:00; it just queries the audit_log as it stands at that moment. If a branch's batch hasn't arrived by 06:00, the summary email shows that branch as "MISSING" with last-uploaded date.

## Failure points

- **Network outage at branch**: pos queues batches locally, retries on next cron tick. After 24h, alarms.
- **inventory rejects the batch (4xx)**: usually a schema problem (e.g., a product UUID that doesn't exist). pos alerts; humans investigate; usually a data fix in inventory followed by a manual re-upload.
- **Duplicate upload**: handled by the composite uniqueness constraint on `(external_batch_id, line_seq)`. Returns 200 with `applied=0` so pos sees it succeeded. (See [[apps/inventory/debugging/2026-04-stock-drift]] for what happened before this was enforced.)
- **Stock goes negative**: allowed (with a flag) for offline-mode sales that beat the catalog refresh. Logged as `was_negative=true`. If frequent, run [[apps/inventory/runbooks/inventory-rebuild]].

## Metrics to monitor

- `pos_daily_batch_success_rate` per branch (should be 100% over a rolling 7-day window)
- `inventory_daily_batch_received_rate` (alert if a branch hasn't reported by 02:00 next day)
- Reconciliation: weekly cron compares `audit_log` SALE count vs pos's sales-report API per branch. Alert if divergence > 1%. (This cron was added after the 2026-04 incident.)

## Notes

This flow appears boring. It's not. The 2026-04 incident showed that the daily-sales import is the most fragile part of the entire ecosystem from a data-integrity perspective — failures here corrupt stock counts, which silently cascades into overselling on webstore and "we ran out, sorry" calls to support. Treat changes to this flow with the same care as changes to checkout.
