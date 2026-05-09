---
title: webstore
type: app
status: active
owners: [webstore]
updated: 2026-05-08
---

# webstore

## Role and responsibility

Customer-facing storefront. Customers browse, add to cart, check out. Orders flow into admin (via shared Postgres). Stock and prices come from inventory.

## Stack

- Framework: Node.js 20 + Fastify 4
- Postgres 15 (shared with admin)
- Server: 1
- Production path: `/srv/webstore`

## Main modules

- [[apps/webstore/modules/checkout]] — cart → payment → order creation
- [[apps/webstore/modules/catalog-rendering]] — product detail and listing pages, consumes integration 01
- [[apps/webstore/modules/promo-codes]] — discount engine

## Integrations

### Producer for
- [[integrations/03-webstore--admin--orders]] — new orders to admin via shared Postgres

### Consumer for
- [[integrations/01-inventory--pos--product-data]] — catalog, prices, stock visibility (we appear in the Consumer notes section there)

## Cron jobs / periodic processes

| Name | Frequency | What it does | Runbook |
|------|-----------|--------------|---------|
| `cart_cleanup` | Hourly | Removes carts older than 7 days | - |
| `price_refresh` | Every 15 min | Re-fetches catalog from inventory | - |

## Runbooks

- [[apps/webstore/runbooks/holiday-readiness]] — Black Friday / December surge prep (when written; informally inherited from previous year)

## Notable recent debugging

- [[apps/webstore/debugging/2026-05-promo-percentage-bug]] — off-by-one on percentage discounts; promo codes giving 10% off were applying as 9.09%

## Local conventions specific to this app

- We're sharing Postgres with admin (see `wiki/shared/postgres-schema.md`). **Schema changes are coordinated** — never alter a shared table without an ADR proposal.
- Stripe webhook payloads are not stored — we extract only the fields we need.
- Per ADR 2026-03 we no longer route any new orders through aggregator. Watch for accidental references in old code paths.
