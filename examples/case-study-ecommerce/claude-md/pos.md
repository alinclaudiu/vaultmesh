# CLAUDE.md — context: pos

## Who you are

- Application: **pos** (in-store point-of-sale, one instance per retail branch)
- Framework: Python 3.11 + Flask
- Server: 3 (each branch has its own dedicated server)
- Path on this server: `/opt/pos`
- Vault path: `/home/USER/vault`

Global vault rules apply (`/home/USER/vault/CLAUDE.md`). This file adds pos-scoped rules.

## Allowed writes

- `wiki/apps/pos/**` — full
- `wiki/integrations/02-pos--inventory--daily-sales.md` — **producer**, full
- `wiki/integrations/01-inventory--pos--product-data.md` — Consumer notes section ONLY
- `wiki/log.md` — append-only

## FORBIDDEN writes

- `wiki/apps/{webstore,admin,inventory,aggregator}/**`
- `wiki/decisions/**` — propose via `wiki/apps/pos/proposed-adr/`
- Any `wiki/integrations/` page outside the two listed above
- `wiki/index.md`
- `raw/`

## You are business-critical

POS runs in physical stores. If it goes down, the cashier cannot scan a customer's items. That is the **business stops** failure mode. Treat all changes accordingly:

- Test in a non-store environment first (we have a `pos-staging` instance per branch)
- Roll out by branch (one branch first, observe for 2 days, then the rest)
- Keep the offline mode (see local SQLite cache) working — the network at our retail locations is sometimes unreliable

Runbooks for "POS offline" and "daily sales sync failed" live in `wiki/apps/pos/runbooks/`. Read them before touching anything in those areas.

## Particularities

### Offline mode
POS keeps a local SQLite mirror of the product catalog (from inventory, integration 01). When the network drops, sales continue against the local cache. When the network comes back, the daily-sales batch (integration 02) catches up. This is the most-bug-prone part of the codebase — be deliberate.

### Per-branch quirks
Some branches have unusual setups (different printer, different barcode scanner brand, custom receipt template). These are documented in `wiki/apps/pos/branches/` (when that folder exists — it doesn't yet because we haven't needed to).

### Daily-sales batch
Once at end-of-day per branch, we upload an aggregated sales file to inventory. **The `external_batch_id` must be unique and stable** — re-uploading the same batch must not double-deduct stock. See contract 02 for the schema and the producer rules we follow.

## Conventions

- Bugs > 30 min → `wiki/apps/pos/debugging/YYYY-MM-slug.md`
- Modules → `wiki/apps/pos/modules/`
- Critical runbooks → `wiki/apps/pos/runbooks/`
- Proposed ADRs → `wiki/apps/pos/proposed-adr/`
- End of session → `wiki/log.md`

## Never touch

- `.env`, any config with credentials
- Real transaction data, real customer data — anonymize ruthlessly
- The local SQLite cache while sync is in progress (see `lock_file` convention)
