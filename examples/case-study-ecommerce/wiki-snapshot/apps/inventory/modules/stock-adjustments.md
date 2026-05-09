---
title: Stock adjustments module
type: module
status: active
owners: [inventory]
updated: 2026-04-19
---

# Stock adjustments

The single code path for any change to `stock_levels`. Every other module that needs to alter stock counts must call this service — never write to the table directly.

## Why a single chokepoint

Three reasons:

1. **Audit trail.** Every adjustment writes to `audit_log` with the actor, reason, and (where applicable) the upstream event ID. Reconstruction from the audit log is how we recovered from the 2026-04 stock-drift incident — see [[apps/inventory/debugging/2026-04-stock-drift]].
2. **Idempotency.** All callers must provide an `external_id` (e.g. the `external_batch_id` from a daily-sales upload, or a manual-correction UUID). The service rejects duplicates.
3. **Constraints.** Stock cannot go negative without an explicit "allow_negative=True" flag, which is logged and reviewed weekly.

## API surface

```
adjust_stock(
    product_uuid: UUID,
    branch_id: int,
    delta: Decimal,
    external_id: str,
    reason: AdjustmentReason,
    actor: str,
    allow_negative: bool = False
) -> AdjustmentResult
```

Reasons we use today: `SALE`, `RETURN`, `TRANSFER_IN`, `TRANSFER_OUT`, `MANUAL_CORRECTION`, `LOSS`, `RECEIVED`.

## Tables touched

- `stock_levels` — UPDATE (the new total)
- `audit_log` — INSERT (the change record)

## Used by

- `app/services/daily_sales_import.py` — applies one adjustment per line item in a daily-sales batch from pos
- `app/api/admin_corrections.py` — manual corrections from the admin UI
- `app/services/transfer_processor.py` — branch-to-branch transfers

## Relevant integrations

- [[integrations/02-pos--inventory--daily-sales]] — most stock adjustments enter through here
