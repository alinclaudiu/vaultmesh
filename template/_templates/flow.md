---
title: [Flow name]
type: flow
status: active
owners: [list of apps involved]
updated: YYYY-MM-DD
---

# [Flow name]

## Trigger

[What event starts this flow? e.g. "A customer places an order on the storefront."]

## Expected outcome

[What happens at the end if everything goes well.]

## Apps involved

- [[apps/app-1]]
- [[apps/app-2]]
- ...

## Steps

### 1. [app-1]: [what it does]

[Description of the step. Relevant code: [[apps/app-1/modules/module-x]].]

Data forwarded: [[integrations/NN-...]]

### 2. [app-2]: [what it does]

Receives: [[integrations/NN-...]]

[Description of the step. Relevant code: [[apps/app-2/modules/module-y]].]

Forwards: [[integrations/NN-...]]

### 3. ...

## Failure points

What can break in this flow and what happens:

- **[failure point 1]**: [impact] → [[apps/.../runbooks/...]]
- **[failure point 2]**: ...

## Metrics to monitor

- [e.g. end-to-end success rate, p95 latency, retry count]

## Notes

[Any contextual notes: history, decisions made, TODOs.]
