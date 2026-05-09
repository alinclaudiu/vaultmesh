---
title: Version per-branch pos config to support staged rollouts
type: adr
status: proposed
owners: [pos]
updated: 2026-04-22
---

# ADR: Version per-branch pos config to support staged rollouts

## Status

`proposed` — awaiting promotion. Discussion expected at the next architecture review.

## Context

The branch-02 receipt printer firmware glitch (2026-05-05) and the branch-04 onboarding pain (2026-03-04) both highlighted the same underlying problem: per-branch quirks (printer model, scanner brand, custom receipt template, sometimes specific pricing rules) are managed via a single shared JSON config file in pos, with no versioning beyond git.

When something goes wrong with a per-branch setting, we can't easily roll back just that branch — git history shows changes across all branches. When we want to test a config change, we have to do it in production at one branch and hope.

## Decision (proposed)

Move pos's per-branch config to a versioned, per-branch namespace:

- Each branch's config in its own file: `config/branches/branch-NN.yaml`
- A schema validator (`config/branches/schema.yaml`) that all branch configs must conform to
- Config changes are deployed per-branch, not all-at-once
- Each branch has a `config_version` it currently runs; rollback is changing that version

## Alternatives considered

- **Status quo**: pros: simple, no migration; cons: doesn't solve the problem
- **External config service** (Consul, etcd): pros: powerful; cons: massive overhead for a 4-branch deployment
- **Per-branch git branches**: pros: native rollback; cons: merging is hell with 4 branches; nobody does this for good reasons

## Consequences

### Positive
- Per-branch rollback becomes trivial
- Config validation prevents typos that would brick a branch
- Staging changes at one branch first becomes the default, not the exception

### Negative / costs
- 1–2 days of engineering for the migration
- New convention for engineers to learn

### Neutral / side effects
- Slightly larger configs directory; not material

## Apps affected

- [[apps/pos]] only — others don't have this problem

## Integrations affected

- _(none)_

## Implementation plan

1. Define schema
2. Migrate the 4 existing branch configs into the new structure
3. Update `pos` to load `config/branches/branch-${BRANCH_ID}.yaml`
4. Document in [[apps/pos/runbooks/new-branch-onboarding]]
5. Test in staging at branch-01 first, then roll to others

## Success metrics

- Time-to-rollback for a per-branch config issue: target < 5 minutes (from "we noticed" to "config rolled back at that branch")
- Onboarding a new branch: target back to 2 hours (currently 6, mostly due to config plumbing)
