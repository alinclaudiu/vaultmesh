---
title: aggregator
type: app
status: deprecated
owners: [aggregator]
updated: 2026-05-04
---

# aggregator (legacy, being phased out)

## Role and responsibility (historical)

For ~6 years, aggregator was the single hub for orders coming from various sources: webstore (when it was first built), in-person sales (before pos existed), B2B integrations, and a never-quite-finished marketplace integration. It collected orders, did some normalization, and forwarded to admin.

Per ADR [[decisions/2026-03-introduce-event-bus]], we are removing aggregator and replacing its responsibilities with a direct webstore→admin path (already in production) plus a future event bus for the few remaining edge cases.

## Status

- Webstore stopped sending new orders to aggregator on 2026-04-15
- The 2 a.m. `legacy_daily_close` cron must keep running through 2026-Q3 (it does end-of-day reconciliation against stale data still flowing through legacy paths)
- Final decommission targeted for 2026-09

## Stack

- Framework: PHP 7.4
- MySQL 5.7
- Server: 2
- Production path: `/srv/aggregator`

## Don't

- **Don't add features.** The decision is to remove it.
- **Don't refactor.** Refactoring legacy code that's about to be deleted is wasted effort.
- **Don't fix non-critical bugs.** Document them, leave them. If they were going to be a problem, they would have been one already.

## Do

- Document landmines as you discover them. Format: `wiki/apps/aggregator/debugging/YYYY-MM-slug.md` even if you didn't fix anything — the *knowledge* of the landmine is the artifact.
- Make sure the 2 a.m. cron keeps running. If it fails, see (when written) `wiki/apps/aggregator/runbooks/cron-2am-failed.md`.

## Main modules

- _(deliberately not documenting modules — the app is going away)_

## Integrations

aggregator was historically a producer for several legacy contracts; those pages are frozen and not listed in the active index. They still exist on disk for reference but are tagged `status: legacy`.

## Notable recent debugging

- _(none recent — the app has been stable in maintenance mode)_

## Local conventions

- Write defensively. Future engineers reading your notes are likely the ones decommissioning.
- "Phase-out" is a valid log-entry tag; use it so other servers' sessions know the context.
