---
title: Server 3 — pos (per branch)
type: infrastructure
status: active
owners: [pos]
updated: 2026-04-30
---

# Server 3 — pos (per branch)

## Apps hosted

- [[apps/pos]] at `/opt/pos`

## What "Server 3" means

There isn't a single "Server 3." Each retail branch has its own dedicated server, all numbered Server 3 in the vault. Currently four:

- branch-01 — Server 3 (north location)
- branch-02 — Server 3 (central location)
- branch-03 — Server 3 (east location)
- branch-04 — Server 3 (newest, opened 2026-03-04)

All four servers run the same pos software. Per-branch quirks (printer model, scanner brand, custom receipts) are managed via the JSON config, not server-level.

## Stack

- OS: Debian 12 (small VM or bare-metal mini-PC)
- Python 3.11
- SQLite (local cache + offline-mode queue)
- Connectivity: VPN tunnel back to the head office for inventory access

## Hardware

_(stub — typical: 2-vCPU, 8GB RAM, 250GB SSD. Each branch is sized for the local register count + a small inventory cache.)_

## Backups

- The local SQLite is rebuildable from inventory's catalog + the pending sales batches; not separately backed up.
- The pending sales batches are what matter — they're persisted at `/var/lib/pos/batches/` until inventory acknowledges them. Replicated to S3 hourly as a safety net.

## Monitoring

- Per-branch heartbeat: `pos_alive_<branch_id>` — fires every 5 min from each pos instance.
- Daily-batch success: `pos_daily_batch_success_rate_<branch_id>`.

## Notable incidents

- 2026-05-05 — branch-02 receipt printer firmware glitch. See [[apps/pos/debugging/2026-05-zebra-firmware-glitch]] (pos's domain).

## Notes

Network reliability at retail locations is **not** carrier-grade. Plan for it. The offline mode of pos exists precisely because we can't assume the VPN tunnel is always up.

Each new branch onboarding includes a server provisioning step. See [[apps/pos/runbooks/new-branch-onboarding]] for the post-mortem on branch-04's install (which took 6h instead of the expected 2).
