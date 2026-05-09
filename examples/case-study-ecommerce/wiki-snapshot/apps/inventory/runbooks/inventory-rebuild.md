---
title: Inventory rebuild from audit log
type: runbook
status: active
owners: [inventory]
updated: 2026-04-28
---

# Inventory rebuild from audit log

## When to run this

When you have credible evidence that `stock_levels` is wrong:

- A branch reports a divergence > 5 units on multiple SKUs
- The weekly audit-log-vs-sales-report cron alerts
- After any incident affecting the daily-sales import (see [[apps/inventory/debugging/2026-04-stock-drift]])

**Don't** run it preemptively. The audit_log is large; replay is slow; the reconciliation creates noise in the audit log itself (because it inserts MANUAL_CORRECTION rows). Only run when you have a real reason.

## What it does

Replays `audit_log` from a known-good baseline forward, rebuilding `stock_levels` as it goes. Compares the result with current `stock_levels` and produces a per-SKU diff. You then apply the diff as MANUAL_CORRECTION adjustments.

## Pre-flight checks

```bash
# 1. Confirm the audit log is internally consistent
psql -d inventory -c "SELECT COUNT(*) FROM audit_log WHERE created_at > NOW() - INTERVAL '90 days'"
# Should be a non-zero, monotonically growing number across runs.

# 2. Confirm no daily-sales import is currently running
ps aux | grep daily_sales_import
# Should show nothing.

# 3. Make a backup of current stock_levels
pg_dump -d inventory -t stock_levels > /tmp/stock_levels_$(date +%Y%m%d_%H%M).sql
```

## Procedure

```bash
cd /srv/inventory
python scripts/inventory_rebuild.py \
    --baseline-date 2026-01-01 \
    --output /tmp/rebuild_diff.csv \
    --dry-run
```

The script:
1. Loads `stock_levels` snapshot at `--baseline-date` (we keep monthly snapshots)
2. Replays every `audit_log` entry from baseline to now
3. Compares the rebuilt levels with current `stock_levels`
4. Writes the diff to `--output`

Review the CSV. Sanity-check a few rows manually against the audit log.

If the diff looks reasonable, re-run without `--dry-run`:

```bash
python scripts/inventory_rebuild.py \
    --baseline-date 2026-01-01 \
    --output /tmp/rebuild_diff.csv \
    --apply
```

This applies the diff as MANUAL_CORRECTION adjustments via the standard `stock_adjustments` service (so they go through audit logging properly).

## After

1. Notify the branches whose stock changed — they'll do a physical recount next time.
2. Add a log entry: "inventory: ran inventory-rebuild, corrected N SKUs across M branches, total delta X units"
3. If this rebuild was triggered by an incident, link the runbook execution back from the debugging page.

## Failure modes

**The script aborts mid-run.** Stock_levels is left as it was before `--apply`. Audit log may have *partial* MANUAL_CORRECTION entries — review them, manually compensate if needed.

**The diff is huge (> 1% of all stock).** Don't apply blindly. There may be a deeper bug. Stop, escalate, investigate.

**The diff is zero.** You weren't actually divergent. Whoever called for the rebuild was looking at stale data. Move on.

## Why this exists at all

This runbook exists because the 2026-04 incident proved we needed it. The first time we needed to do this, it took 8 hours of figuring out. The second time, it should take 30 minutes.

If you find yourself running this and the runbook is wrong, **fix the runbook before you forget what you learned**.
