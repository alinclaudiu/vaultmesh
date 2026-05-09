#!/usr/bin/env bash
#
# vault-sync (vs) -- pull the latest vault state from the central remote.
# Run at the start of every session, before reading or writing any vault page.
#
# Read-only and safe -- no confirmation needed.
# If a rebase conflict happens (extremely rare), it stops; resolve manually.
#
# Usage: vs
#
# This is the script form. The deploy/setup-server.sh installs a generated
# version of this at $HOME/vault-sync with VAULT_PATH baked in. This file
# is the canonical reference; if you want it without the bootstrap, copy it
# and replace ${VAULT_PATH:?} with your actual path.

set -e

VAULT="${VAULT_PATH:?VAULT_PATH must be set}"

cd "$VAULT" || { echo "Vault not found at $VAULT"; exit 1; }
echo "-> Syncing vault from $VAULT..."
git pull --rebase --autostash
echo "OK Done. Latest commit:"
git log --oneline -1
