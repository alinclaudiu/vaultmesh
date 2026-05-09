# CLAUDE.md — context: aggregator

## Who you are

- Application: **aggregator** (legacy order hub being phased out)
- Framework: PHP 7.4 (legacy, no major changes planned)
- Server: 2
- Path on this server: `/srv/aggregator`
- Datastore: MySQL 5.7

## Status: legacy

Per ADR 2026-03, this app is **being phased out**. New work should not touch aggregator unless it's specifically a phase-out task. Document everything you do here defensively — there's a high chance the next person to read your notes is the one decommissioning it.

## Allowed writes

- `wiki/apps/aggregator/**` — full
- `wiki/log.md` — append-only

## FORBIDDEN writes

- All `wiki/integrations/` (we are no producer; legacy contracts are documented but frozen)
- All other `wiki/apps/{...}/**`
- `wiki/decisions/**`
- `wiki/index.md`
- `raw/`

## Particularities

### Don't add features
The decision is to remove this app. Adding features creates more work for the eventual decommissioning. If you find yourself wanting to add a feature here, stop and ask: **can this be done in admin instead?**

### Document landmines as you find them
Aggregator has been running for ~6 years and has accumulated several "do not touch" code paths. As you discover them, write them in `wiki/apps/aggregator/debugging/` even if you didn't fix anything — the *knowledge* of the landmine is valuable.

### The 2 a.m. cron
There's a daily 2 a.m. cron that does the legacy daily-close. **It must keep working** until phase-out. Runbook: `wiki/apps/aggregator/runbooks/cron-2am-failed.md` (when written; for now ask the senior engineer who owned this).

## Conventions

- Bugs > 30 min → `wiki/apps/aggregator/debugging/YYYY-MM-slug.md`
- Don't write new module pages; write debugging pages instead
- End of session → `wiki/log.md` (note: "legacy / phase-out" in your log entry helps the rest of the org understand context)

## Never touch

- `.env`, MySQL credentials, anything in `config/`
- Real legacy data (customer records from 2018 are still in here; they're real)
- The deprecated `LegacyOrderImporter` — it's known broken in three ways and the fixes are intentionally not being made
