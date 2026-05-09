---
title: admin
type: app
status: active
owners: [admin]
updated: 2026-05-08
---

# admin

## Role and responsibility

Back-office UI for staff: managing the catalog (in cooperation with inventory), processing orders (refunds, address changes, lost orders), customer support actions. Used by 8–12 people across customer support, fulfillment, and finance.

## Stack

- Framework: Rails 7
- Postgres 15 (shared with webstore)
- Server: 1
- Production path: `/srv/admin`

## Main modules

- [[apps/admin/modules/order-state-machine]] — the order lifecycle from `created` to `fulfilled`/`refunded`/`cancelled`
- [[apps/admin/modules/customer-support]] — refund preview, address change, support-ticket linking
- [[apps/admin/modules/catalog-management]] — UI for editing catalog (calls inventory's API; doesn't write directly)

## Integrations

### Producer for
- _(none today)_

### Consumer for
- [[integrations/03-webstore--admin--orders]] — new orders from webstore (shared Postgres)
- [[integrations/01-inventory--pos--product-data]] — read-only catalog/price info for the support and fulfillment views (not formally split into its own contract yet; we ride along on contract 01)

## Cron jobs / periodic processes

| Name | Frequency | What it does | Runbook |
|------|-----------|--------------|---------|
| `daily_summary` | 06:00 daily | Emails the previous day's order summary to ops@ | - |
| `escheatment_check` | Weekly Mon 09:00 | Flags orders stuck in `pending_payment` > 14 days | - |

## Runbooks

- _(none yet)_

## Notable recent debugging

- _(none recently — all minor work this past month)_

## Local conventions specific to this app

- We **read** from the shared Postgres but only write to tables we own (orders, support_tickets, etc.). The catalog-related tables are managed by inventory's API; we never write directly to them.
- Per ADR 2026-03, the legacy aggregator path is being phased out. Old order partials are visually marked so support staff knows their origin.
- Refunds in production are a manual workflow (out of code review's reach). Code changes that affect refund logic require explicit sign-off from finance.
