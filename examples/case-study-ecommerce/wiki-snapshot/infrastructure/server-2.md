---
title: Server 2 — inventory + aggregator
type: infrastructure
status: active
owners: [inventory, aggregator]
updated: 2026-04-30
---

# Server 2

## Apps hosted

- [[apps/inventory]] at `/srv/inventory`
- [[apps/aggregator]] at `/srv/aggregator` (legacy, scheduled decommission 2026-09)

## Stack

- OS: Debian 12
- Postgres 15 (own to inventory)
- MySQL 5.7 (own to aggregator — ⚠️ EOL, but the app is being retired)
- Python 3.11 (for inventory)
- PHP 7.4 (for aggregator — ⚠️ EOL, see above)

## Hardware / capacity

_(stub — currently a 4-vCPU / 32GB VM. Postgres dominates RAM use. Comfortable headroom.)_

## Backups

- Postgres (inventory): nightly pg_dump to S3, 30-day retention. Plus point-in-time WAL archival.
- MySQL (aggregator): weekly mysqldump to S3, 90-day retention. Will move to cold archive once decommissioned.
- The `audit_log` table in inventory has its own quarterly snapshot (in addition to the standard backup) — used as the baseline for the [[apps/inventory/runbooks/inventory-rebuild]] runbook.

## Monitoring

_(stub.)_

## Notable incidents on this server

- 2026-04-18 — see [[apps/inventory/debugging/2026-04-stock-drift]]. Application-level (not server-level) issue, but the response involved this server.

## Notes

This server hosts the data-integrity-critical pieces. **No automatic restarts.** Postgres restarts must be coordinated with the other teams that consume from inventory (pos, webstore, admin).

Once aggregator is decommissioned, this server becomes single-app and can be considered for downsizing.
