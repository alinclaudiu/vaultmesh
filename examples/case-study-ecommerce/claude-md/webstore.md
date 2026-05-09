# CLAUDE.md — context: webstore

## Who you are

- Application: **webstore** (customer-facing storefront)
- Framework: Node.js + Fastify
- Server: 1
- Path on this server: `/srv/webstore`
- Datastore: Postgres (shared with admin)

## Allowed writes

- `wiki/apps/webstore/**` — full
- `wiki/integrations/03-webstore--admin--orders.md` — **producer**, full
- `wiki/integrations/01-inventory--pos--product-data.md` — Consumer notes (we also consume product data, see Note below)
- `wiki/log.md` — append-only

## Note on consuming product data

Strictly, integration 01 is `inventory → pos`. We also consume product data from inventory but we do it through the same endpoint. We've added our edge cases under "Consumer notes" alongside pos's. If the load gets heavy enough to need a separate contract, we'll split it (proposed ADR territory).

## FORBIDDEN writes

- `wiki/apps/{admin,inventory,pos,aggregator}/**`
- `wiki/decisions/**`
- Other `wiki/integrations/` pages
- `wiki/index.md`
- `raw/`

## Particularities

### Shared Postgres with admin
We share a Postgres instance and several tables with `admin`. The shared schema is documented at `wiki/shared/postgres-schema.md`. **Schema changes are coordinated** — never alter a shared table without an ADR proposal.

### Holiday traffic
Black Friday and December are 5x normal load. The runbook `wiki/apps/webstore/runbooks/holiday-readiness.md` (when written) covers cache warming, rate-limit settings, and the on-call rotation.

### Phasing out the aggregator
Until 2026-Q2, some legacy orders still go through `aggregator`. The intention (see ADR 2026-03) is to remove that path entirely. Don't add new code that depends on aggregator.

## Conventions

- Bugs > 30 min → `wiki/apps/webstore/debugging/YYYY-MM-slug.md`
- Modules → `wiki/apps/webstore/modules/`
- Runbooks → `wiki/apps/webstore/runbooks/`
- Proposed ADRs → `wiki/apps/webstore/proposed-adr/`
- End of session → `wiki/log.md`

## Never touch

- `.env`, any config with credentials
- Real customer data — never. Anonymize before pasting anything from production.
- Stripe webhooks payloads — they may contain card-related metadata; treat as PII-equivalent.
