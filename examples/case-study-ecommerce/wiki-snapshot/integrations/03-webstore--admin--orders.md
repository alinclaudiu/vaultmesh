---
title: webstore → admin: new orders
type: integration
status: active
owners: [webstore, admin]
producer: webstore
consumer: admin
transport: shared-db
updated: 2026-04-08
---

# webstore → admin: new orders

> This page is owned by **webstore**.
> admin writes only in the **Consumer notes** section below.

## What flows

When a customer completes checkout on webstore, we INSERT a row into the shared `orders` table. admin is structured to detect new orders (via Postgres NOTIFY/LISTEN) and pick them up for fulfillment workflow.

## Transport

- **Type**: Shared Postgres database (via NOTIFY/LISTEN for change detection)
- **Schema/table**: `orders` (and related: `order_line_items`, `customer_addresses`)
- **Frequency**: real-time (notification-driven)
- **Initiator**: webstore INSERTs; admin's listener wakes up
- **Format**: standard relational rows + JSONB blob for cart snapshot

## Authentication

- **Method**: Postgres role-based — webstore writes via the `webstore_app` role; admin reads (and updates non-shared columns) via `admin_app`
- **Credentials**: in each app's `config/database.yml` / `.env`. **Never document the actual values here.**
- **Rotation**: yearly, coordinated through DBA channel

## Schema (relevant tables)

```sql
-- Owned by: webstore (writes), admin (reads + updates non-shared cols)
CREATE TABLE orders (
  id BIGSERIAL PRIMARY KEY,
  external_id VARCHAR(64) UNIQUE NOT NULL,  -- webstore's ID, idempotency key
  state order_state NOT NULL DEFAULT 'created',
  customer_email VARCHAR(255) NOT NULL,
  total_cents INT NOT NULL,
  cart_snapshot JSONB NOT NULL,             -- written by webstore, read-only after
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- admin-owned columns:
  fulfillment_state VARCHAR(32),            -- only admin updates
  assigned_to_user_id BIGINT,               -- only admin updates
  internal_notes TEXT                       -- only admin writes
);

CREATE TYPE order_state AS ENUM (
  'created', 'pending_payment', 'paid', 'fulfilled', 'cancelled', 'refunded'
);
```

Full schema diagram lives in [[../shared/postgres-schema]].

### Ownership of state transitions

| State transition | Who triggers it |
|---|---|
| `created` → `pending_payment` | webstore (Stripe init) |
| `pending_payment` → `paid` | webstore (Stripe webhook) |
| `pending_payment` → `cancelled` | webstore (timeout) |
| `paid` → `fulfilled` | admin (warehouse marks shipped) |
| `paid` → `refunded` | admin (manual via support UI) |

## Error handling

- **No retry policy needed** — INSERT either succeeds or webstore raises; no async coordination required because the database is the message bus.
- **Idempotency**: webstore uses `external_id` as the unique key; if a checkout flow retries (e.g., browser back-and-replay) the duplicate INSERT fails on the unique constraint and webstore handles gracefully.
- **If admin is down**: orders are still created in the database; admin will pick them up when it comes back. No data loss.
- **If webstore is down**: customers can't check out. Orders simply don't get created. (This is the hardest failure mode operationally; see [[apps/webstore/runbooks/holiday-readiness]] when written.)

## Expected volume

- ~200–500 orders/day baseline
- Peak ~3,000/day during sales (Black Friday)

## Monitoring

- `webstore_orders_created_per_minute` — health metric
- `admin_orders_unprocessed_count` (orders in `paid` state for > 1 hour without `fulfillment_state` set) — alert if > 10

## Breaking changes log

> Filled in by **webstore only**.

### 2026-04-08 — Aggregator path removed for new orders (operational, no schema change)
- **What changed**: webstore no longer also-writes to aggregator's MySQL. New orders are INSERT-only into shared Postgres.
- **Impact for consumer (admin)**: admin should expect 100% of new orders via shared DB by 2026-04-15. Legacy orders still trickle in from aggregator's nightly batch until phase-out completes.
- **Coordination required**: per ADR [[decisions/2026-03-introduce-event-bus]]; admin had been ready since 2026-03-20.

### 2026-01 — Cart snapshot in JSONB (additive)
- Added `cart_snapshot` column. Captures the full cart state at checkout time (line items, prices, discounts) so admin can reconstruct what the customer saw if there's a dispute.

## Consumer notes

> Filled in by **admin**.

- **NOTIFY/LISTEN works well for ~1k orders/min;** above that we'd want a queue. Not currently a problem.
- **`cart_snapshot` is gold for support.** When a customer disputes "I was charged X but the page said Y", we can reconstruct exactly what the page said.
- **State machine enforcement**: admin treats the `state` column as authoritative; we never bypass the state machine to "force" a state change.
- **Aggregator legacy orders**: until phase-out completes (target 2026-09), some orders still arrive via aggregator's nightly batch. We mark them visually in the UI ("legacy") so support knows the path. See log entry 2026-04-15.

## References

- Producer code: [[apps/webstore/modules/checkout]]
- Consumer code: [[apps/admin/modules/order-state-machine]]
- Flow: [[flows/customer-order-lifecycle]]
- Related ADR: [[decisions/2026-03-introduce-event-bus]]
