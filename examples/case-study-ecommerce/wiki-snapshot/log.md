---
title: Session log
type: log
updated: 2026-05-09
---

# Session log

Append-only. Most recent entries at the top. Every session that touches code or vault content adds an entry.

---

## 2026-05-09 11:42 — inventory on Server 2
- modules touched: `app/services/price_updater.py` (added bulk-update endpoint)
- integrations verified/updated: 01 (added `bulk_update_supported: true` flag in catalog response; additive, not breaking)
- notable decisions or debugging added: -
- documented: `apps/inventory/modules/price-updater.md` (new), Breaking changes log entry on contract 01

## 2026-05-08 16:20 — webstore on Server 1
- modules touched: `src/checkout/promo-codes.ts` (fix off-by-one on percentage discounts)
- integrations verified/updated: -
- notable decisions or debugging added: `apps/webstore/debugging/2026-05-promo-percentage-bug.md` — tested with 3 sample codes, confirmed fix

## 2026-05-08 14:05 — admin on Server 1
- modules touched: `app/controllers/customer_support_controller.rb` (refund preview UI)
- integrations verified/updated: -
- notable decisions or debugging added: -

## 2026-05-07 18:30 — pos on Server 3 (branch-04)
- modules touched: `app/sync/daily_batch.py` (idempotency guard improvements per ADR 2026-04 follow-up)
- integrations verified/updated: 02 (Consumer notes updated re: how we handle the `external_batch_id` collision case)
- notable decisions or debugging added: -

## 2026-05-07 10:15 — inventory on Server 2
- modules touched: `app/api/products.py` (paginated catalog endpoint)
- integrations verified/updated: 01 (Breaking changes log: catalog response now paginated; pos and webstore must update by 2026-06-15)
- notable decisions or debugging added: -

## 2026-05-06 19:50 — webstore on Server 1
- modules touched: `src/checkout/cart.ts` (regression fix: stale prices when cart sat > 30 min)
- integrations verified/updated: 01 Consumer notes: noted that pricing TTL should match inventory's cache header; we now respect it
- notable decisions or debugging added: -

## 2026-05-05 14:00 — pos on Server 3 (branch-02)
- modules touched: `app/printers/zebra.py` (workaround for new firmware glitch)
- integrations verified/updated: -
- notable decisions or debugging added: `apps/pos/debugging/2026-05-zebra-firmware-glitch.md` — branch-02 specifically; doc'd which firmware version, which model

## 2026-05-04 22:30 — aggregator on Server 2
- modules touched: -
- integrations verified/updated: -
- notable decisions or debugging added: nothing — checked the 2 a.m. cron logs, all green for the past 14 days. Confirms phase-out timeline (per ADR 2026-03) is on track.

## 2026-05-02 09:15 — admin on Server 1
- modules touched: `app/services/order_export.rb` (CSV export for support team)
- integrations verified/updated: -
- notable decisions or debugging added: -

## 2026-04-28 17:45 — inventory on Server 2
- modules touched: `app/services/audit_log_replay.py`
- integrations verified/updated: -
- notable decisions or debugging added: `apps/inventory/runbooks/inventory-rebuild.md` (new) — formalizes the procedure from the 2026-04 stock-drift incident

## 2026-04-22 11:00 — pos on Server 3 (branch-01, branch-02, branch-03)
- modules touched: `app/sync/daily_batch.py` (rolled out idempotency-guard fix from 2026-04 incident)
- integrations verified/updated: 02 (Consumer notes: confirmed `external_batch_id` is now stable across retries)
- notable decisions or debugging added: -

## 2026-04-19 16:30 — inventory on Server 2
- modules touched: `app/services/daily_sales_import.py` (added idempotency guard)
- integrations verified/updated: 02 (Breaking changes log: `external_batch_id` now strictly required; rejection if missing)
- notable decisions or debugging added: `apps/inventory/debugging/2026-04-stock-drift.md` — root cause + fix + prevention; this is the big one this month

## 2026-04-18 23:00 — inventory on Server 2 (incident response)
- modules touched: hot-fix to `app/services/daily_sales_import.py` (temporary dedup hack)
- integrations verified/updated: -
- notable decisions or debugging added: stock divergence report; physical counts at 2 branches were off by 12-15 units. Investigating overnight, will write up tomorrow.

## 2026-04-15 10:30 — admin on Server 1
- modules touched: `app/views/orders/_legacy_order_partial.html.erb` (visual hint that "this came from aggregator, will go away in Q2")
- integrations verified/updated: -
- notable decisions or debugging added: -

## 2026-04-08 14:00 — webstore on Server 1
- modules touched: `src/checkout/index.ts` (skip aggregator path for new orders, per ADR 2026-03)
- integrations verified/updated: 03 (no change to schema; clarified Consumer notes that admin should expect 100% of new orders via shared DB by 2026-04-15)
- notable decisions or debugging added: -

## 2026-03-15 09:30 — cross: admin + webstore + aggregator
- modules touched: cross-app planning session
- integrations verified/updated: -
- notable decisions or debugging added: ADR 2026-03 promoted to `decisions/`. New orders begin migrating off aggregator over the next 4 weeks.

## 2026-03-12 17:00 — admin on Server 1 (ADR proposal)
- modules touched: -
- integrations verified/updated: -
- notable decisions or debugging added: `apps/admin/proposed-adr/2026-03-introduce-event-bus.md` — proposal to introduce a lightweight pub/sub layer between apps so we can phase out aggregator. Discussion in #arch-decisions Slack channel scheduled for 2026-03-15.

## 2026-03-04 11:20 — pos on Server 3 (branch-04, new install)
- modules touched: -
- integrations verified/updated: 01 (smoke test: pulled catalog, 4,231 products), 02 (smoke test: empty batch upload accepted)
- notable decisions or debugging added: `apps/pos/runbooks/new-branch-onboarding.md` — captured the steps that were undocumented; took 6 hours instead of the expected 2

## 2026-02-22 13:45 — inventory on Server 2
- modules touched: `app/api/stock.py` (per-branch stock query)
- integrations verified/updated: 01 (Breaking changes log: catalog response now includes `stock_per_branch` map; additive, no breaking)
- notable decisions or debugging added: -
