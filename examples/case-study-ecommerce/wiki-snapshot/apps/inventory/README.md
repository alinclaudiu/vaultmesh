---
title: inventory
type: app
status: active
owners: [inventory]
updated: 2026-05-09
---

# inventory

## Role and responsibility

Single source of truth for product catalog, stock levels, and prices across the Acme ecosystem. Every other app reads its product/price/stock data from here. inventory writes to its own database; everyone else reads via API.

If inventory is wrong, the storefront sells things we don't have, the POS shows incorrect stock, and accounting can't reconcile. Treat changes here with care.

## Stack

- Framework: Python 3.11 + FastAPI
- PostgreSQL: 15.x
- Server: 2
- Production path: `/srv/inventory`

## Main modules

- [[apps/inventory/modules/stock-adjustments]] — apply/reverse stock movements with full audit trail
- [[apps/inventory/modules/price-updater]] — bulk price updates with versioning
- [[apps/inventory/modules/daily-sales-import]] — accept end-of-day batches from pos (consumer side of integration 02)

## Integrations

### Producer for
- [[integrations/01-inventory--pos--product-data]] — catalog, prices, stock per branch (consumed by pos and webstore)

### Consumer for
- [[integrations/02-pos--inventory--daily-sales]] — end-of-day sales batches from each pos branch

## Cron jobs / periodic processes

| Name | Frequency | What it does | Runbook |
|------|-----------|--------------|---------|
| `audit_log_compactor` | Nightly 03:00 | Compacts the audit_log table (older than 90 days) | (no runbook yet — has never failed) |
| `stale_price_check` | Hourly | Logs prices that haven't been updated in > 30 days | - |

## Runbooks

- [[apps/inventory/runbooks/inventory-rebuild]] — rebuild the stock table from `audit_log` when divergence is suspected. Critical, treat carefully.

## Notable recent debugging

- [[apps/inventory/debugging/2026-04-stock-drift]] — physical counts diverged from system; root cause was missing idempotency in daily-sales import. Added an `external_batch_id` requirement and a uniqueness constraint.

## Local conventions specific to this app

- The `audit_log` table is **append-only**. Never UPDATE or DELETE rows in it. Other tools rely on its monotonic ordering for replay.
- All stock changes go through `app/services/stock_adjustments.py`. **No direct UPDATEs on `stock_levels` from other code paths.**
- We use `decimal.Decimal` for prices, never floats. There's a linter rule that catches this.
- Database migrations are reviewed by two people (sensitive enough to warrant the friction).
