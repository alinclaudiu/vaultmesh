---
title: Customer order lifecycle
type: flow
status: active
owners: [webstore, admin, inventory]
updated: 2026-04-08
---

# Customer order lifecycle

From a customer clicking "Buy" to a shipped order. Three apps participate: webstore (orchestrator), admin (fulfillment), inventory (stock decrement on confirmed sale via end-of-day reconciliation, see related flow).

## Trigger

A customer on webstore completes the checkout form and Stripe approves the payment.

## Expected outcome

- An `orders` row exists in shared Postgres with `state='paid'`
- A confirmation email is sent to the customer
- The order appears in admin's fulfillment queue
- Stock impact is reflected in inventory (eventually, via the end-of-day path or manual)

## Apps involved

- [[apps/webstore]]
- [[apps/admin]]
- [[apps/inventory]] (read-only during this flow; stock movements come later via [[end-of-day-reconciliation]])

## Steps

### 1. webstore: present cart and prices

User adds products to cart. webstore renders prices from its 15-minute cache of [[integrations/01-inventory--pos--product-data]]. If a price changed in inventory, the cart shows the cached price, and webstore validates against fresh prices at checkout submit.

Code: [[apps/webstore/modules/catalog-rendering]], [[apps/webstore/modules/checkout]].

### 2. webstore: create order, init Stripe

User clicks Buy. webstore:
1. Validates that the cart prices match a fresh fetch from inventory (within 5% tolerance for FX moves; otherwise re-prompts).
2. INSERTs an `orders` row with `state='created'` and `external_id=<UUID>` ([[integrations/03-webstore--admin--orders]]).
3. Initiates a Stripe PaymentIntent.
4. Transitions the order to `state='pending_payment'`.

### 3. webstore: handle Stripe webhook

When Stripe confirms (webhook), webstore transitions the order to `state='paid'` and emits a Postgres NOTIFY.

### 4. admin: pick up the order

admin's NOTIFY listener wakes up. The order appears in the fulfillment queue with `fulfillment_state=NULL`.

Code: [[apps/admin/modules/order-state-machine]].

### 5. admin: warehouse fulfillment

A warehouse staff member uses admin to mark the order picked, packed, and shipped. admin transitions to `state='fulfilled'`.

### 6. (asynchronous) inventory: stock impact

For online-fulfilled orders, the stock impact is **not** captured by the daily-sales batch (which is for in-store/pos sales). Instead, admin's fulfillment workflow calls inventory's stock-adjustment API directly when packing a shipment. See [[apps/inventory/modules/stock-adjustments]].

> **Note on ownership of this step**: this is admin calling inventory, not pos's daily batch. It runs via integration "00 — admin → inventory: shipment-stock-decrement" which is **not yet documented as a contract page** (it's been on the TODO list since the 2026-Q1 planning meeting). When it gets written, it'll be `00-admin--inventory--shipment-stock`.

## Failure points

- **Stripe webhook delayed or lost**: the order stays in `pending_payment` indefinitely. The `escheatment_check` cron in admin flags orders > 14 days in this state for human review. Customers may also re-trigger by visiting the "my orders" page.
- **Warehouse forgets to mark fulfilled**: the order sits in `paid` state. admin's `admin_orders_unprocessed_count` metric alerts on > 10 orders > 1h old.
- **Stock decrement fails**: admin retries up to 3 times. If still failing, the order is marked `fulfilled` anyway (we shipped it; the stock count is wrong but recoverable via [[apps/inventory/runbooks/inventory-rebuild]]).
- **Catalog drift between cart and checkout**: webstore re-validates at submit. If the cart price differs from the fresh price by > 5%, we re-prompt the user. Less than 5% — we honor the cart price. (Decision recorded informally; not yet ADR-worthy.)

## Metrics to monitor

- p95 time from `created` to `paid` (should be < 30s — Stripe is the bottleneck)
- p95 time from `paid` to `fulfilled` (should be < 24h business hours)
- Rate of `pending_payment` → `cancelled` (high rate suggests checkout UX friction)

## Notes

This flow is the spine of the business. Touch with care. Anything that crosses the webstore↔admin boundary should be reviewed by both teams.
