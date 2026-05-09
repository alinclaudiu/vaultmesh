# Acme E-commerce — architecture overview

A fictional ecosystem used to demonstrate VaultMesh in action. All names, numbers, and details are invented.

## Apps × servers

| App | Server | Path | Framework | Datastore | Role |
|---|---|---|---|---|---|
| webstore | 1 | `/srv/webstore` | Node.js (Fastify) | Postgres (shared with admin) | Customer-facing storefront |
| admin | 1 | `/srv/admin` | Rails 7 | Postgres (shared with webstore) | Back-office: catalog, orders, customer support |
| inventory | 2 | `/srv/inventory` | Python (FastAPI) | Postgres (own) | Single source of truth for stock and prices |
| aggregator | 2 | `/srv/aggregator` | PHP 7.4 (legacy) | MySQL 5.7 | Legacy order hub, being phased out |
| pos | 3 | `/opt/pos` | Python (Flask) | SQLite (local cache) + REST to inventory | Point-of-sale, one install per retail branch |

Server 1 hosts the customer-facing layer. Server 2 hosts the business-critical SoR (inventory) and the legacy aggregator. Server 3 hosts the in-store POS instances.

## Integrations

Two-digit numbering, `producer--consumer--subject`:

| ID | Page | Producer | Consumer | Transport | Subject |
|---|---|---|---|---|---|
| 01 | `01-inventory--pos--product-data.md` | inventory | pos | REST POST | Product catalog, prices, stock |
| 02 | `02-pos--inventory--daily-sales.md` | pos | inventory | Cron file upload | End-of-day sales batch |
| 03 | `03-webstore--admin--orders.md` | webstore | admin | Shared Postgres | New customer orders |

## Flows

End-to-end journeys that touch 2+ apps:

| Flow | Initiator | Apps involved |
|---|---|---|
| `customer-order-lifecycle` | webstore | webstore → admin → inventory |
| `end-of-day-reconciliation` | pos | pos → inventory → admin |

## Decisions (promoted ADRs)

| Date | ADR |
|---|---|
| 2026-03-12 | `2026-03-introduce-event-bus.md` — accepted: introduce a lightweight pub/sub between apps to phase out the aggregator |

## Recent debugging

| Date | Page |
|---|---|
| 2026-04-18 | `apps/inventory/debugging/2026-04-stock-drift.md` — stock counts in inventory diverged from physical counts; root cause was a missing idempotency guard in the daily-sales import |

## Recent runbooks

| Page | Purpose |
|---|---|
| `apps/inventory/runbooks/inventory-rebuild.md` | Rebuild inventory's stock table from the audit log when corruption is suspected |
