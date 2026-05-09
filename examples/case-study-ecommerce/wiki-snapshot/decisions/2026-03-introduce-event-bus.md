---
title: Introduce a lightweight event bus, phase out aggregator
type: adr
status: accepted
owners: [admin, webstore, aggregator]
updated: 2026-03-15
---

# ADR: Introduce a lightweight event bus, phase out aggregator

## Status

`accepted` — promoted from `apps/admin/proposed-adr/` on 2026-03-15

Original proposal date: 2026-03-12
Discussion: #arch-decisions Slack channel, 2026-03-13 to 2026-03-15
Promotion: 2026-03-15

## Context

aggregator is a 6-year-old PHP service that originally collected orders from multiple sources (the original webstore, a B2B integration, and a never-quite-finished marketplace adapter) and forwarded them to admin. Today:

- 95%+ of orders are direct webstore→admin via shared Postgres (since 2024)
- The B2B integration was mothballed in 2025
- The marketplace adapter is incomplete and unused
- aggregator's MySQL holds ~1M historical orders that nobody queries
- Two engineers (one no longer with the company) hold the only mental models of how aggregator's daily-close cron actually works

We want to:

1. Stop sending any new orders through aggregator
2. Document and freeze the legacy daily-close behavior until 2026-Q3
3. Decommission aggregator entirely by 2026-09

The remaining concern: if a new B2B or marketplace integration comes up, where do we put it? aggregator was at least *somewhere* — without it, we'd default to point-to-point pairs which are a path to chaos.

## Decision

We will:

1. **Stop the webstore→aggregator path immediately** (scheduled completion: 2026-04-15)
2. **Maintain aggregator's daily-close cron** through 2026-Q3 to handle the residual data still flowing through legacy paths
3. **Introduce a lightweight pub/sub layer** (initial implementation: NATS or Redis Streams; final choice deferred) for any future cross-app events that don't fit the existing producer/consumer integration pattern
4. **Decommission aggregator** by 2026-09. Archive its MySQL to S3 cold storage. Document the off-ramp.

## Alternatives considered

- **Keep aggregator forever**: pros: no migration risk; cons: technical debt grows, knowledge loss continues, eventually we lose the ability to fix anything in PHP 7.4. Rejected.
- **Migrate aggregator to Python and modernize**: pros: would be cleaner; cons: massive effort to rebuild a service we're trying to delete. Rejected.
- **Do nothing about future cross-app events**: pros: simplest; cons: we'd default to ad-hoc point-to-point integrations, which is the chaos aggregator was originally trying to prevent. Rejected — hence the pub/sub commitment.
- **Adopt Kafka or RabbitMQ now**: pros: industry-standard; cons: operational overhead disproportionate to our scale. Deferred — start with NATS/Redis Streams; revisit if scale demands.

## Consequences

### Positive
- One fewer legacy app to maintain
- Cleaner data flow (orders go directly webstore→admin)
- Reduced attack surface (one fewer service exposed internally)
- Knowledge concentrates in apps that are actively maintained

### Negative / costs
- Need to build the pub/sub layer when needed (estimated 1–2 weeks of engineering when we hit the first use case)
- aggregator's MySQL archive must be retrievable for historical disputes (have a runbook for this — TBD)
- Phase-out window of 6 months is operationally awkward (we have to babysit a service we're trying to kill)

### Neutral / side effects
- Once webstore→aggregator stops, admin's UI will show fewer "legacy origin" badges over time — visible cleanup
- Engineers stop having to learn PHP 7.4 quirks for new joiners

## Apps affected

- [[apps/webstore]] — stops the dual-write to aggregator (done 2026-04-08)
- [[apps/admin]] — visually marks legacy orders during phase-out window (done 2026-04-15)
- [[apps/aggregator]] — frozen for new development, just runs the cron until decommission

## Integrations affected

- [[integrations/03-webstore--admin--orders]] — Breaking changes log entry on 2026-04-08 documents the aggregator path removal

## Implementation plan

1. ✅ 2026-03-15: ADR accepted
2. ✅ 2026-04-08: webstore stops dual-writing to aggregator
3. ✅ 2026-04-15: admin's UI marks legacy orders visually
4. ⏳ 2026-Q3: design and implement the pub/sub layer if a use case appears
5. ⏳ 2026-09: aggregator decommission. Archive MySQL. Final log entry.

## Success metrics

- 100% of new orders flow webstore→admin direct (no aggregator path) by 2026-04-30 ✅ achieved on 2026-04-15
- Zero incidents traced to aggregator after 2026-04-30 (i.e., its phase-out doesn't break anything) — track in `wiki/log.md` for the next 90 days
- aggregator decommissioned by 2026-09 — track ETA monthly
