# Examples

This folder is the *demonstration layer* of VaultMesh. Read it after the docs to see the pattern in motion.

## What's here

- **[`case-study-ecommerce/`](case-study-ecommerce/)** — a fully fictional 5-app, 3-server e-commerce ecosystem with ~15 wiki pages, ~20 log entries, 3 integrations, 2 flows, 1 promoted ADR, 1 proposed ADR, 1 debugging page, 1 runbook. **Start here.**
- **[`log-entry-anatomy.md`](log-entry-anatomy.md)** — a 60-second annotated breakdown of what makes a good log entry vs a useless one.

## Recommended reading order

1. [`case-study-ecommerce/README.md`](case-study-ecommerce/README.md) — the meta-overview
2. [`case-study-ecommerce/architecture.md`](case-study-ecommerce/architecture.md) — what's in the case study
3. [`case-study-ecommerce/wiki-snapshot/index.md`](case-study-ecommerce/wiki-snapshot/index.md) — what the wiki looks like as it sits
4. [`case-study-ecommerce/wiki-snapshot/log.md`](case-study-ecommerce/wiki-snapshot/log.md) — read the top 10 entries
5. [`log-entry-anatomy.md`](log-entry-anatomy.md) — see what makes log entries useful
6. The integration page in the case study: [`01-inventory--pos--product-data.md`](case-study-ecommerce/wiki-snapshot/integrations/01-inventory--pos--product-data.md) — see the producer/consumer split
7. [`2026-04-stock-drift.md`](case-study-ecommerce/wiki-snapshot/apps/inventory/debugging/2026-04-stock-drift.md) — a debugging page for an incident the log entries refer to. This is where the wiki really pays for itself.
