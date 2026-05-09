#!/usr/bin/env bash
#
# vault-push (vp) -- show status, ask for confirmation, commit + push.
# Run at the end of a session, ONLY after explicit human approval of the diff.
#
# By design this requires interactive confirmation -- never wire it into a
# non-interactive automation. The whole point is that a human sees the diff.
#
# Usage: vp "myapp: short message"
#
# This is the script form. The deploy/setup-server.sh installs a generated
# version of this at $HOME/vault-push with VAULT_PATH baked in.

set -e

VAULT="${VAULT_PATH:?VAULT_PATH must be set}"

cd "$VAULT" || { echo "Vault not found at $VAULT"; exit 1; }

if [ "$#" -lt 1 ]; then
  echo "Usage: vp \"commit message\""
  echo "Example: vp \"inventory: document the daily reconciliation cron\""
  exit 1
fi
MSG="$*"

echo "-> Vault status ($VAULT):"
echo "------------------------------------"
git status --short
echo "------------------------------------"

CHANGES="$(git status --porcelain)"
if [ -z "$CHANGES" ]; then
  echo "Nothing to commit. Vault is clean."
  exit 0
fi

echo
echo "Commit message: \"$MSG\""
echo
printf "Confirm commit + push? [y/N] "
read -r ans
case "$ans" in
  [yY]*) ;;
  *) echo "Aborted."; exit 0 ;;
esac

git add .
git commit -m "$MSG"
echo
echo "-> Pushing to remote..."
git push
echo "OK Done."
