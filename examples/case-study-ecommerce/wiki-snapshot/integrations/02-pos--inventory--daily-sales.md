---
title: pos → inventory: daily sales batch
type: integration
status: active
owners: [pos, inventory]
producer: pos
consumer: inventory
transport: cron-file
updated: 2026-04-22
---

# pos → inventory: daily sales batch

> This page is owned by **pos**.
> inventory writes only in the **Consumer notes** section below.

## What flows

End-of-day, each pos branch uploads an aggregated batch of all sales for the day. inventory consumes the batch and adjusts stock levels per SKU per branch.

## Transport

- **Type**: HTTPS multipart file upload
- **URL**: `POST https://inventory.internal/api/v2/daily-sales`
- **Frequency**: Once per branch per day, around 23:50 local time
- **Initiator**: pos pushes
- **Format**: JSON body with batch metadata + JSONL file of line items

## Authentication

- **Method**: HTTP Bearer token, per-branch
- **Credentials**: stored on each pos instance under `/etc/pos/secrets/inventory_token`
- **Rotation**: every 90 days

## Payload schema

```json
{
  "external_batch_id": "branch-02-2026-05-07-001",
  "branch_id": "branch-02",
  "date": "2026-05-07",
  "line_count": 142,
  "lines_file": "<multipart>"
}
```

The `lines_file` is JSONL, one record per line:

```jsonl
{"line_seq": 1, "product_uuid": "f47a...", "qty": 2, "unit_price": "9.99", "sold_at": "2026-05-07T09:14:23+02:00"}
{"line_seq": 2, "product_uuid": "a3b4...", "qty": 1, "unit_price": "29.99", "sold_at": "2026-05-07T09:18:01+02:00"}
...
```

### Required fields

| Field | Type | Description |
|---|---|---|
| `external_batch_id` | string | Unique per (branch, day, attempt). **Stable across retries.** Format: `<branch>-<YYYY-MM-DD>-<NNN>` |
| `branch_id` | string | Matches the branch ID known to inventory |
| `date` | ISO-date | Business day (not necessarily wall-clock) |
| `line_count` | int | Number of records in `lines_file`; mismatch = reject |
| `line_seq` (per line) | int | 1-indexed within the batch. Composite uniqueness with `external_batch_id`. |
| `product_uuid` | UUID | Must exist in inventory's catalog |
| `qty` | int | Positive |
| `unit_price` | decimal-as-string | What was actually charged (may differ from current catalog price if a discount applied) |
| `sold_at` | ISO-8601 with TZ | Timestamp from the local pos clock |

## Error handling

- **Retry policy**: pos retries up to 5 times with exponential backoff. **Same `external_batch_id` on every retry.**
- **Timeout**: 60 seconds for the upload itself
- **If consumer (inventory) is down**: pos queues the batch locally and retries on next cron tick. After 24h queued, raises an alarm to ops.
- **If payload is invalid (4xx)**: inventory returns a structured error; pos logs and alerts. We do NOT auto-retry on 4xx — humans investigate.
- **Idempotency**: yes, by composite key `(external_batch_id, line_seq)`. Re-uploading the same batch is a no-op. **This is critical** — see Breaking changes log entry on 2026-04-19 and the [[../apps/inventory/debugging/2026-04-stock-drift]] page for the incident that taught us this.

## Expected volume

- 4 branches × ~150 lines/day = ~600 line items/day total
- Batch size: typical 1–50 KB, peak 200 KB

## Monitoring

- Producer (pos): `pos_daily_batch_success_rate` per branch — alert if any branch < 100% over 7 days
- Consumer (inventory): `inventory_daily_batch_received_rate` — alert if a branch hasn't reported by 02:00 the next day
- Reconciliation: weekly cron compares `audit_log SALE` count vs pos's sales-report API; alert if divergence > 1%

## Breaking changes log

> Filled in by **pos only**.

### 2026-04-19 — `external_batch_id` and `line_seq` strictly required (BREAKING)
- **What changed**: `external_batch_id` is now mandatory and must be stable across retries. Composite uniqueness `(external_batch_id, line_seq)` enforced server-side. Any batch without these is rejected with 422.
- **Impact for consumer (inventory)**: this is actually an enabling change for inventory — duplicate uploads are now safe. inventory rolled out the matching idempotency guard simultaneously.
- **Coordination required**: pos rolled this out across all 4 branches by 2026-04-22 (see log entry of that date)
- **Why**: see [[../apps/inventory/debugging/2026-04-stock-drift]]

### 2026-01-15 — initial contract
- Initial schema as described above.

## Consumer notes

> Filled in by **inventory**.

- **Idempotency check is critical.** Before applying any line, we verify `(external_batch_id, line_seq)` is unique. Implemented as a unique index. Tested under retry conditions — see [[../apps/inventory/debugging/2026-04-stock-drift]] for why.
- **Late batches are tolerated.** A batch with `date=2026-05-07` arriving 2026-05-09 is still accepted. We detect "too old" only at the 14-day mark and alert (because that suggests a branch was offline for two weeks).
- **Price drift between batch upload time and catalog price**: we trust the `unit_price` in the batch, not the current catalog price. If a discount was applied at the time of sale, that's what's recorded.
- **Stock can go negative through this path** if a sale happened against a stale catalog (offline mode at pos). We flag it (`audit_log` entry includes `was_negative=true`) and reconcile via the `inventory-rebuild` runbook if it happens often.

## References

- Producer code: [[apps/pos/modules/daily-batch]]
- Consumer code: [[apps/inventory/modules/daily-sales-import]] (referenced from `apps/inventory/modules/stock-adjustments`)
- Flow: [[flows/end-of-day-reconciliation]]
- Incident: [[apps/inventory/debugging/2026-04-stock-drift]]
