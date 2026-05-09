---
title: pos
type: app
status: active
owners: [pos]
updated: 2026-05-07
---

# pos

## Role and responsibility

In-store point-of-sale. Cashiers scan items, customers pay, receipts print. One pos instance runs per retail branch (currently four branches: branch-01 through branch-04). Each instance pulls the product catalog from inventory and pushes daily sales back.

When pos is down, the branch can't sell. **Business stops.** This is the most operationally-critical app in the ecosystem.

## Stack

- Framework: Python 3.11 + Flask
- Local datastore: SQLite (mirror of catalog + queued sales when offline)
- Server: 3 (one dedicated server per branch, all numbered 3 in the vault)
- Production path: `/opt/pos`

## Main modules

- [[apps/pos/modules/catalog-sync]] — pulls and caches the catalog from inventory (consumer of integration 01)
- [[apps/pos/modules/checkout-flow]] — the actual sale transaction
- [[apps/pos/modules/daily-batch]] — end-of-day upload to inventory (producer of integration 02)
- [[apps/pos/modules/offline-mode]] — what happens when the network drops mid-shift

## Integrations

### Producer for
- [[integrations/02-pos--inventory--daily-sales]] — end-of-day batch upload of sales to inventory

### Consumer for
- [[integrations/01-inventory--pos--product-data]] — catalog, prices, per-branch stock

## Cron jobs / periodic processes

| Name | Frequency | What it does | Runbook |
|------|-----------|--------------|---------|
| `catalog_sync` | Every 30 min | Pulls catalog deltas from inventory | (no runbook — falls back to local cache silently) |
| `daily_batch` | 23:50 daily | Uploads the day's sales to inventory | [[apps/pos/runbooks/daily-batch-failed]] (when written) |

## Runbooks

- [[apps/pos/runbooks/new-branch-onboarding]] — what we learned from branch-04 install (2026-03-04)
- [[apps/pos/runbooks/offline-recovery]] — when a branch loses network for hours and queues up sales (when written)

## Notable recent debugging

- [[apps/pos/debugging/2026-05-zebra-firmware-glitch]] — branch-02 receipt printer started cutting receipts early after a firmware push

## Local conventions specific to this app

- Per-branch quirks live in `wiki/apps/pos/branches/` (folder doesn't exist yet — only branch-02 has had any quirk worth documenting so far)
- Offline-mode SQLite cache: lock file `/var/run/pos-sync.lock` indicates a sync is in progress. Don't read or write the SQLite cache while it exists.
- Receipts: we use one ESC/POS template across branches; per-branch branding is loaded from a JSON config, not template variants
