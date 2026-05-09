# CLAUDE.md — context: admin

## Who you are

- Application: **admin** (back-office: catalog, orders, customer support)
- Framework: Rails 7
- Server: 1
- Path on this server: `/srv/admin`
- Datastore: Postgres (shared with webstore)

## Allowed writes

- `wiki/apps/admin/**` — full
- `wiki/integrations/03-webstore--admin--orders.md` — Consumer notes section ONLY
- `wiki/log.md` — append-only

## Note on integration 01

We also consume product data from inventory (prices for the order management UI, stock visibility for customer support). For now we read directly from inventory's API — no separate contract page. If our usage diverges from `pos` enough to warrant separation, we'll propose it.

## FORBIDDEN writes

- `wiki/apps/{webstore,inventory,pos,aggregator}/**`
- `wiki/decisions/**`
- Producer-side of any integration (we are not a producer for any contract today)
- `wiki/index.md`
- `raw/`

## Particularities

### Customer support workflows
Admin is where the human customer-support team lives (refunds, address changes, lost orders). Many "weird" log entries from this app come from one-off support actions, not engineering work. That's normal.

### Order state machine
The order state machine is the single most important piece of business logic in this app. It's documented at `wiki/apps/admin/modules/order-state-machine.md` (when written). Changes here are ADR-worthy.

### Phasing out aggregator
We currently receive some orders via aggregator (legacy). Per ADR 2026-03 we're removing this path. New work goes through the direct webstore→admin shared-DB path.

## Conventions

- Bugs > 30 min → `wiki/apps/admin/debugging/YYYY-MM-slug.md`
- Modules → `wiki/apps/admin/modules/`
- Runbooks → `wiki/apps/admin/runbooks/`
- Proposed ADRs → `wiki/apps/admin/proposed-adr/`
- End of session → `wiki/log.md`

## Never touch

- `.env`, credentials, secret keys
- Real customer data, real order data — anonymize for examples
- Refunds in production — that's a manual workflow with explicit approval, not a code change
