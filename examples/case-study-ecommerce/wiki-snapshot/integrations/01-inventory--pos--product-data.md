---
title: inventory → pos: product data
type: integration
status: active
owners: [inventory, pos]
producer: inventory
consumer: pos
transport: rest
updated: 2026-05-09
---

# inventory → pos: product data

> This page is owned by **inventory**.
> pos and webstore (which also consumes this contract) write only in the **Consumer notes** section below.

## What flows

The full product catalog: SKU UUIDs, names, codes, tax classes, prices, and per-branch stock. pos uses this to render the cashier UI; webstore uses it to render the storefront.

## Transport

- **Type**: REST (HTTPS)
- **URL**: `GET https://inventory.internal/api/v2/catalog`
- **Frequency**: pos pulls every 30 minutes; webstore pulls every 15 minutes
- **Initiator**: consumer pull (not producer push)
- **Format**: JSON, paginated (since 2026-05-07)

## Authentication

- **Method**: HTTP Bearer token (per-consumer)
- **Credentials**: stored on each consumer's side under `config/secrets/inventory_token` (NEVER pasted in this wiki — see [[../../../../docs/05-security-model]])
- **Rotation**: every 90 days, coordinated through the shared-credentials channel (out of band)

## Payload schema

```json
{
  "page": 1,
  "page_size": 500,
  "total_pages": 9,
  "products": [
    {
      "uuid": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "code": "SKU-12345",
      "name": "Example product",
      "tax_class": "standard",
      "price": "199.99",
      "currency": "EUR",
      "stock_per_branch": {
        "branch-01": 12,
        "branch-02": 0,
        "branch-03": 5,
        "branch-04": 3
      },
      "bulk_update_supported": true
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `uuid` | UUID | yes | Stable across renames |
| `code` | string | yes | Human-readable SKU code (may change rarely) |
| `name` | string | yes | Display name |
| `tax_class` | enum | yes | `standard`, `reduced`, `zero` |
| `price` | decimal-as-string | yes | Always serialized as string to avoid float drift |
| `currency` | ISO-4217 | yes | EUR for now |
| `stock_per_branch` | map | yes | branch_id → integer count |
| `bulk_update_supported` | boolean | no | Indicates whether `POST /products/bulk` accepts this product |

## Error handling

- **Retry policy**: consumer should retry with exponential backoff up to 5 times (initial delay 1s)
- **Timeout**: 30 seconds (the catalog is large)
- **If consumer cannot reach producer**: pos falls back to its local SQLite cache and degrades gracefully (cashiers can still sell, but stock numbers may be stale). webstore shows a maintenance banner.
- **If payload is invalid**: consumer logs and skips; producer's monitoring alerts on >0.1% invalid response rate
- **Idempotency**: the endpoint is read-only; safe to retry

## Expected volume

- ~12,000 products today
- Page size 500 → 24 page requests per pull
- Each consumer pulls every 15–30 min: ~100 requests/hour total

## Monitoring

- Producer: `inventory_catalog_endpoint_latency_p95` — alert if > 2s
- Producer: `inventory_catalog_endpoint_5xx_rate` — alert if > 0.1%
- Consumer (pos): `pos_catalog_freshness_minutes` — alert if > 60 min on any branch (means catalog hasn't synced)

## Breaking changes log

> Filled in by **inventory only**. Every schema or semantic change gets a new entry, no matter how small.

### 2026-05-09 — `bulk_update_supported` flag (additive)
- **What changed**: added optional `bulk_update_supported` boolean to each product
- **Impact for consumer**: none if ignored; can be used by admin to decide if bulk-edit is allowed per product
- **Coordination required**: none

### 2026-05-07 — Pagination introduced (BREAKING)
- **What changed**: response is now `{page, page_size, total_pages, products: [...]}` instead of bare `[...]`. Consumers must iterate pages.
- **Impact for consumer**: code that did `for product in response.json()` will break — must now do `response.json()["products"]` and follow `total_pages`.
- **Coordination required**: pos and webstore have until 2026-06-15 to migrate. Old behavior is supported via `?legacy=true` query parameter for the transition period.
- **Status**: pos migrated 2026-05-07; webstore migrated 2026-05-08. Legacy parameter will be removed 2026-06-15.

### 2026-02-22 — `stock_per_branch` map (additive)
- **What changed**: each product now includes a per-branch stock map
- **Impact for consumer**: pos can now show real per-branch availability; webstore can show "available in your nearest store"
- **Coordination required**: none — additive, ignore the field if not used

## Consumer notes

> Filled in by consumers (pos and webstore). Edge cases, deviations, observations.

### pos

- **Catalog freshness vs stock accuracy**: we cache the catalog locally for 30 min. Stock numbers shown to cashiers may be up to 30 min stale. We accept this; the daily-sales upload reconciles it nightly. If a cashier sees stock=5 in the system and there are physically 0 on the shelf, they sell the on-shelf item (not the system item).
- **Pagination retry behavior**: if a single page request fails, we retry that page (not the whole batch). Confirmed safe with inventory team 2026-05-08.
- **Consumer notes update 2026-05-07**: confirmed that the `external_batch_id` related to integration 02 is also stable across our retries — see contract 02.

### webstore

- **Pricing TTL**: we cache the catalog at the Fastify layer with a 15-min TTL aligned with the cron. As of 2026-05-06 we also respect inventory's `Cache-Control: max-age=...` response header — that fixed a bug where carts with sat > 30 min showed stale prices at checkout.
- **Stock visibility**: we currently show "in stock" / "out of stock" from the storefront perspective (sum across branches we ship from). Per-branch visibility is not shown to customers.

## References

- Producer code: [[apps/inventory/modules/stock-adjustments]]
- Consumer code (pos): [[apps/pos/modules/catalog-sync]]
- Consumer code (webstore): [[apps/webstore/modules/catalog-rendering]]
- Flows that use this contract: [[flows/customer-order-lifecycle]], [[flows/end-of-day-reconciliation]]
