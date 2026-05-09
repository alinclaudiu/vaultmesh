---
title: Shared Postgres schema (webstore + admin)
type: shared
status: active
owners: [webstore, admin]
updated: 2026-04-08
---

# Shared Postgres schema (webstore + admin)

The Postgres instance on Server 1 is shared between webstore and admin. This page documents the table-ownership conventions so we don't accidentally trample each other.

## Tables and ownership

| Table | Writes | Reads | Notes |
|---|---|---|---|
| `orders` | webstore (most cols), admin (fulfillment cols only) | both | See [[../integrations/03-webstore--admin--orders]] for column-level ownership |
| `order_line_items` | webstore | both | Created with the order; immutable after |
| `customer_addresses` | webstore | both | Customer-supplied; webstore owns |
| `support_tickets` | admin | admin | webstore doesn't read |
| `staff_users` | admin | admin | Internal users |
| `audit_actions` | admin | admin | UI action log |
| `cart_drafts` | webstore | webstore | Pre-checkout state |

## Migrations

- Each app has its own migrations directory. Migrations that touch shared tables must be **reviewed by the other team** before merge.
- We use `pg_dump --schema-only` artifacts checked into each app's repo to track the current expected schema; a CI check fails if they drift.
- Adding a column: usually safe (additive) — coordinate via a quick Slack message.
- Renaming or dropping a column: needs an ADR proposal.
- Changing types: needs an ADR proposal.

## Why shared, not separate?

Historical: webstore and admin grew up together as one Rails app, were split by ownership later, but the database split was deferred indefinitely. The cost of keeping it shared (coordination on schema changes) is lower than the cost of splitting (data ownership questions, replication, dual-write complexity). Revisit if the apps grow far apart in shape.

## What's NOT in this DB

- Inventory data — that's in inventory's own Postgres on Server 2
- Aggregator's legacy orders — those are in aggregator's MySQL (also on Server 2)

## Schema diagram

_(stub — would normally have a Mermaid ER diagram here. For the case study we'll just leave it as a TODO.)_

## Notes

If you find yourself wanting a "shared" table that doesn't belong squarely in either webstore or admin, that's a sign you might need a third app or a service layer. Don't just add it to whoever's "closer."
