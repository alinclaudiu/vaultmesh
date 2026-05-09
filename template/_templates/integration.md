---
title: [Producer] → [Consumer]: [Subject]
type: integration
status: active
owners: [producer, consumer]
producer: [producer-app]
consumer: [consumer-app]
transport: [rest | soap | shared-db | cron-file | cron-fetch | queue]
updated: YYYY-MM-DD
---

# [Producer] → [Consumer]: [Subject]

> This page is owned by **[producer]**.
> [consumer] only writes in the **Consumer notes** section below.

## What flows

[Short description of what the producer sends to the consumer.]

## Transport

- **Type**: [REST / SOAP / shared MySQL table / file on disk / cron fetch / queue]
- **URL / Path / Query**: [e.g. POST https://internal.example/api/orders — or table name, or file path]
- **Frequency**: [real-time / every X min / daily at HH:MM / trigger-based]
- **Initiator**: [producer push / consumer pull / DB trigger]
- **Format**: [JSON / XML / CSV / SQL / ...]

## Authentication

- **Method**: [Bearer token / HTTP Basic / IP whitelist / shared DB credential]
- **Credentials**: reference `config/...` (NEVER paste content here)
- **Rotation**: [how often, if applicable]

## Payload schema

```json
{
  "example": "fictional",
  "comment": "replace with real schema"
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | int | yes | ... |
| ... | ... | ... | ... |

## Error handling

- **Retry policy**: [none / N times with exponential backoff / etc.]
- **Timeout**: [X seconds]
- **If consumer is unreachable**: [what producer does]
- **If payload is invalid**: [what consumer does]
- **Idempotency**: [are duplicate requests safe? how is duplication detected?]

## Expected volume

- [e.g. 100–500 messages/day, peak 50/hour]

## Monitoring

- [How do you know this integration is healthy? Metrics, logs, alerts.]

## Breaking changes log

> Filled in by the **producer only**. New entry on EVERY schema or
> semantic change, no matter how small it seems.

### YYYY-MM-DD — [short title]
- **What changed**: ...
- **Impact for consumer**: ...
- **Coordination required**: [e.g. simultaneous deploy / grace period / N/A]

## Consumer notes

> Filled in by the **consumer**. Observations on how data is interpreted,
> edge cases encountered, deviations from the spec.

- ...

## References

- Producer code: [[apps/[producer]/modules/...]]
- Consumer code: [[apps/[consumer]/modules/...]]
- Flows that use this contract: [[flows/...]]
