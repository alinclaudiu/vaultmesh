---
title: Server 1 — webstore + admin
type: infrastructure
status: active
owners: [webstore, admin]
updated: 2026-04-30
---

# Server 1

## Apps hosted

- [[apps/webstore]] at `/srv/webstore`
- [[apps/admin]] at `/srv/admin`

## Stack

- OS: Debian 12
- Postgres 15 (shared instance for webstore + admin)
- Node.js 20 (for webstore)
- Ruby 3.2 (for admin)
- nginx as reverse proxy

## Hardware / capacity

_(stub — fill in when relevant. Currently a 4-vCPU / 16GB VM. Sized for ~3x peak traffic, comfortable headroom outside of holiday season.)_

## Backups

_(stub — Postgres is backed up nightly via pg_dump to S3, retained 30 days. Verify quarterly.)_

## Monitoring

_(stub — basic CPU/disk/memory in Grafana; app-level metrics from each app's own emission.)_

## Notable incidents on this server

_None recently._

## Notes

This server hosts the customer-facing layer. Downtime here = customer-visible outage. Treat changes (deploy, restart, etc.) accordingly.

The shared Postgres on this server is used by both webstore and admin via integration [[integrations/03-webstore--admin--orders]]. Don't restart Postgres without informing both teams.
