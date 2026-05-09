---
title: [App name]
type: app
status: active
owners: [app-name]
updated: YYYY-MM-DD
---

# [App name]

## Role and responsibility

[What this app does in the ecosystem, in 2–3 sentences.]

## Stack

- Framework: [framework + version]
- Language runtime: [version]
- Datastore: [type + version]
- Server: [N]
- Production path: `[/path/to/app]`

## Main modules

- [[apps/[name]/modules/module-1]] — [what it does]
- [[apps/[name]/modules/module-2]] — [what it does]
- ...

## Integrations

### Producer for
- [[integrations/NN-...]] — [short description]

### Consumer for
- [[integrations/NN-...]] — [short description]

## Cron jobs / periodic processes

| Name | Frequency | What it does | Runbook if it fails |
|------|-----------|--------------|---------------------|
| ... | ... | ... | [[apps/[name]/runbooks/...]] |

## Runbooks

- [[apps/[name]/runbooks/...]] — [situation]

## Notable recent debugging

- [[apps/[name]/debugging/YYYY-MM-...]] — [short summary]

## Local conventions specific to this app

[Any local convention worth flagging: unusual namespaces, in-house patterns, etc.]
