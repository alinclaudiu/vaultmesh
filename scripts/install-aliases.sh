#!/usr/bin/env bash
#
# install-aliases.sh -- add `vs` and `vp` aliases to ~/.bashrc.
# Idempotent: replaces existing aliases if they differ, leaves them alone if not.
#
# Usually you don't run this directly -- deploy/setup-server.sh calls it.
# Provided standalone for cases where you want the aliases without running
# the full bootstrap.
#
# Usage: VAULT_PATH=/path/to/vault bash install-aliases.sh

set -eu

VAULT="${VAULT_PATH:?VAULT_PATH must be set}"
BASHRC="${BASHRC:-$HOME/.bashrc}"

[ -d "$VAULT" ] || { echo "VAULT_PATH does not exist: $VAULT"; exit 1; }
[ -f "$BASHRC" ] || touch "$BASHRC"

# Where the generated wrapper scripts will live
SYNC_SCRIPT="$HOME/vault-sync"
PUSH_SCRIPT="$HOME/vault-push"

# Drop generated wrappers (they bake in VAULT_PATH so users can run `vs` / `vp`
# without setting any env var)
cat > "$SYNC_SCRIPT" << EOF
#!/usr/bin/env bash
set -e
VAULT="$VAULT"
cd "\$VAULT" || { echo "Vault not found at \$VAULT"; exit 1; }
echo "-> Syncing vault from \$VAULT..."
git pull --rebase --autostash
echo "OK Done. Latest commit:"
git log --oneline -1
EOF
chmod +x "$SYNC_SCRIPT"

cat > "$PUSH_SCRIPT" << EOF
#!/usr/bin/env bash
set -e
VAULT="$VAULT"
cd "\$VAULT" || { echo "Vault not found at \$VAULT"; exit 1; }
if [ "\$#" -lt 1 ]; then
  echo "Usage: vp \"commit message\""
  exit 1
fi
MSG="\$*"
echo "-> Vault status (\$VAULT):"
echo "------------------------------------"
git status --short
echo "------------------------------------"
CHANGES="\$(git status --porcelain)"
if [ -z "\$CHANGES" ]; then
  echo "Nothing to commit. Vault is clean."
  exit 0
fi
echo
echo "Commit message: \"\$MSG\""
echo
printf "Confirm commit + push? [y/N] "
read -r ans
case "\$ans" in [yY]*) ;; *) echo "Aborted."; exit 0 ;; esac
git add .
git commit -m "\$MSG"
echo "-> Pushing to remote..."
git push
echo "OK Done."
EOF
chmod +x "$PUSH_SCRIPT"

# Drop aliases idempotently
ALIAS_VS="alias vs='$SYNC_SCRIPT'"
ALIAS_VP="alias vp='$PUSH_SCRIPT'"

if grep -q "^alias vs=" "$BASHRC"; then
  if ! grep -qF "$ALIAS_VS" "$BASHRC"; then
    sed -i.bak "/^alias vs=/d" "$BASHRC"
    echo "$ALIAS_VS" >> "$BASHRC"
    echo "Replaced existing 'vs' alias"
  fi
else
  echo "$ALIAS_VS" >> "$BASHRC"
  echo "Added 'vs' alias to $BASHRC"
fi

if grep -q "^alias vp=" "$BASHRC"; then
  if ! grep -qF "$ALIAS_VP" "$BASHRC"; then
    sed -i.bak "/^alias vp=/d" "$BASHRC"
    echo "$ALIAS_VP" >> "$BASHRC"
    echo "Replaced existing 'vp' alias"
  fi
else
  echo "$ALIAS_VP" >> "$BASHRC"
  echo "Added 'vp' alias to $BASHRC"
fi

echo
echo "Done. Reload your shell:  source $BASHRC"
echo "Then try:                  vs"
