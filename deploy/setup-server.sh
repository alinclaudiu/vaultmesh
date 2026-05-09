#!/usr/bin/env bash
#
# setup-server.sh — bootstrap a server for a VaultMesh deployment
# Usage: bash setup-server.sh path/to/server-N.conf
#
# Idempotent + interactive: each step asks for confirmation and skips
# anything already done. Safe to re-run.

set -euo pipefail

# -------------------- output helpers --------------------
RED="$(printf '\033[0;31m')"
GREEN="$(printf '\033[0;32m')"
YELLOW="$(printf '\033[0;33m')"
BLUE="$(printf '\033[0;34m')"
BOLD="$(printf '\033[1m')"
NC="$(printf '\033[0m')"

info()  { printf "${BLUE}i${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}OK${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}!${NC}  %s\n" "$*"; }
err()   { printf "${RED}X${NC}  %s\n" "$*" >&2; }
step()  { printf "\n${BOLD}--- %s ---${NC}\n" "$*"; }

confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-Y}"
  local hint
  if [ "$default" = "Y" ]; then hint="Y/n"; else hint="y/N"; fi
  printf "${YELLOW}?${NC}  %s [%s] " "$prompt" "$hint"
  read -r answer
  [ -z "$answer" ] && answer="$default"
  case "$answer" in
    [yY]*) return 0 ;;
    *)     return 1 ;;
  esac
}

# -------------------- load config --------------------
if [ "${1:-}" = "" ]; then
  err "Usage: $0 path/to/server-N.conf"
  err "Example: $0 deploy/servers/server-2.conf"
  exit 1
fi

CONFIG_FILE="$1"
if [ ! -f "$CONFIG_FILE" ]; then
  err "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

# Validate config
for var in SERVER_ID SERVER_NAME REMOTE_GIT VAULT_PATH PACKAGE_PATH; do
  if [ -z "${!var:-}" ]; then
    err "Variable $var is not set in $CONFIG_FILE"
    exit 1
  fi
done

if [ -z "${APPS:-}" ] || [ "${#APPS[@]}" -eq 0 ]; then
  err "APPS array is empty in $CONFIG_FILE"
  exit 1
fi

# -------------------- banner --------------------
clear
cat << EOF
${BOLD}============================================================${NC}
  VaultMesh setup -- Server $SERVER_ID ($SERVER_NAME)
${BOLD}============================================================${NC}

Config:    $CONFIG_FILE
Hostname:  $(hostname)
User:      $(whoami)

Apps to configure:
EOF
for app_entry in "${APPS[@]}"; do
  app_name="${app_entry%%|*}"
  app_path="${app_entry##*|}"
  echo "  - $app_name -> $app_path"
done

echo
confirm "Look right? Continue?" || { info "Aborted."; exit 0; }

# -------------------- validate app paths --------------------
step "Validating app paths"
all_ok=true
for app_entry in "${APPS[@]}"; do
  app_name="${app_entry%%|*}"
  app_path="${app_entry##*|}"
  if [[ "$app_path" == FILL_IN* ]]; then
    err "Path for $app_name not filled in: $app_path"
    all_ok=false
  elif [ ! -d "$app_path" ]; then
    warn "Path for $app_name does not exist: $app_path"
    all_ok=false
  else
    ok "$app_name -> $app_path"
  fi
done

if ! $all_ok; then
  err "Fix the paths in $CONFIG_FILE and rerun."
  exit 1
fi

# -------------------- step 1: clone/pull vault --------------------
step "Step 1/7 -- Clone or update the vault"
if [ -d "$VAULT_PATH/.git" ]; then
  info "Vault already exists at $VAULT_PATH"
  if confirm "Pull latest?"; then
    cd "$VAULT_PATH"
    git pull --rebase --autostash
    ok "Vault updated"
  else
    warn "Skipped"
  fi
elif [ -e "$VAULT_PATH" ]; then
  err "$VAULT_PATH exists but is not a git repo. Resolve manually."
  exit 1
else
  info "Cloning vault from $REMOTE_GIT"
  if confirm "Continue with clone?"; then
    git clone "$REMOTE_GIT" "$VAULT_PATH"
    ok "Cloned to $VAULT_PATH"
  else
    warn "Skipped"
  fi
fi

# -------------------- step 2: write .server-id --------------------
step "Step 2/7 -- Mark server-id"
SERVER_ID_FILE="$VAULT_PATH/.server-id"
DESIRED_CONTENT="SERVER_ID=$SERVER_ID"
if [ -f "$SERVER_ID_FILE" ] && [ "$(cat "$SERVER_ID_FILE")" = "$DESIRED_CONTENT" ]; then
  ok ".server-id already set correctly ($DESIRED_CONTENT)"
else
  info "Writing $DESIRED_CONTENT to $SERVER_ID_FILE"
  if confirm "OK?"; then
    echo "$DESIRED_CONTENT" > "$SERVER_ID_FILE"
    ok "Written"
  else
    warn "Skipped"
  fi
fi

# -------------------- step 3: pre-commit hook --------------------
step "Step 3/7 -- Pre-commit hook"
HOOK_SRC="$PACKAGE_PATH/deploy/hooks/pre-commit"
HOOK_DST="$VAULT_PATH/.git/hooks/pre-commit"
if [ ! -f "$HOOK_SRC" ]; then
  err "Hook source not found: $HOOK_SRC"
  err "Check that VaultMesh is checked out at $PACKAGE_PATH"
  exit 1
fi

if [ -f "$HOOK_DST" ] && cmp -s "$HOOK_SRC" "$HOOK_DST"; then
  ok "Pre-commit hook already installed and identical"
else
  info "Installing hook from $HOOK_SRC to $HOOK_DST"
  if confirm "OK?"; then
    cp "$HOOK_SRC" "$HOOK_DST"
    chmod +x "$HOOK_DST"
    ok "Hook installed and executable"
  else
    warn "Skipped"
  fi
fi

# -------------------- step 4: per-app CLAUDE.md drop --------------------
step "Step 4/7 -- Drop CLAUDE.md into each app directory"
for app_entry in "${APPS[@]}"; do
  app_name="${app_entry%%|*}"
  app_path="${app_entry##*|}"
  CM_SRC="$PACKAGE_PATH/per-app-claude-md/$app_name.md"
  CM_DST="$app_path/CLAUDE.md"

  if [ ! -f "$CM_SRC" ]; then
    err "No per-app CLAUDE.md found for $app_name: $CM_SRC"
    info "Create it at $CM_SRC (use template/apps/_per-app-CLAUDE.md.example as a starting point)"
    continue
  fi

  if [ -f "$CM_DST" ] && cmp -s "$CM_SRC" "$CM_DST"; then
    ok "$app_name: CLAUDE.md already installed and identical"
  elif [ -f "$CM_DST" ]; then
    warn "$app_name: CLAUDE.md exists but differs"
    if confirm "  Overwrite (source = $CM_SRC)?"; then
      cp "$CM_SRC" "$CM_DST"
      ok "  Overwritten"
    else
      info "  Left unchanged"
    fi
  else
    info "$app_name: installing CLAUDE.md at $CM_DST"
    if confirm "  OK?"; then
      cp "$CM_SRC" "$CM_DST"
      ok "  Copied"
    fi
  fi
done

# -------------------- step 5: git config for vault --------------------
step "Step 5/7 -- Git config for vault"
cd "$VAULT_PATH"
current_name="$(git config user.name 2>/dev/null || echo '')"
current_email="$(git config user.email 2>/dev/null || echo '')"

if [ -n "$current_name" ] && [ -n "$current_email" ]; then
  ok "Git config already set: $current_name <$current_email>"
else
  info "Git config not yet set for this repo"
  read -r -p "Name for commits: " git_name
  read -r -p "Email for commits: " git_email
  if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    warn "Skipped (name or email empty)"
  else
    git config user.name "$git_name"
    git config user.email "$git_email"
    ok "Set: $git_name <$git_email>"
  fi
fi

# -------------------- step 6: install vs / vp scripts + aliases --------------------
step "Step 6/7 -- Install 'vs' (vault-sync) and 'vp' (vault-push)"

BASHRC="$HOME/.bashrc"

# --- vault-sync (pull) ---
SYNC_SCRIPT="$HOME/vault-sync"
SYNC_CONTENT='#!/usr/bin/env bash
# vault-sync -- pull the latest vault state from remote
# Usage: vs
set -e
VAULT='"$VAULT_PATH"'
cd "$VAULT" || { echo "Vault not found at $VAULT"; exit 1; }
echo "-> Syncing vault from $VAULT..."
git pull --rebase --autostash
echo "OK Done. Latest commit:"
git log --oneline -1
'

if [ -f "$SYNC_SCRIPT" ] && [ "$(cat "$SYNC_SCRIPT")" = "$SYNC_CONTENT" ]; then
  ok "vault-sync script already installed and identical"
else
  info "Installing script at $SYNC_SCRIPT"
  if confirm "OK?"; then
    printf '%s' "$SYNC_CONTENT" > "$SYNC_SCRIPT"
    chmod +x "$SYNC_SCRIPT"
    ok "Written and made executable"
  fi
fi

# --- vault-push (status -> commit -> push with confirmation) ---
PUSH_SCRIPT="$HOME/vault-push"
PUSH_CONTENT='#!/usr/bin/env bash
# vault-push -- show status, ask for confirmation, commit + push
# Usage: vp "commit message"
set -e
VAULT='"$VAULT_PATH"'
cd "$VAULT" || { echo "Vault not found at $VAULT"; exit 1; }

if [ "$#" -lt 1 ]; then
  echo "Usage: vp \"commit message\""
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
'

if [ -f "$PUSH_SCRIPT" ] && [ "$(cat "$PUSH_SCRIPT")" = "$PUSH_CONTENT" ]; then
  ok "vault-push script already installed and identical"
else
  info "Installing script at $PUSH_SCRIPT"
  if confirm "OK?"; then
    printf '%s' "$PUSH_CONTENT" > "$PUSH_SCRIPT"
    chmod +x "$PUSH_SCRIPT"
    ok "Written and made executable"
  fi
fi

# --- alias vs ---
ALIAS_VS="alias vs='$SYNC_SCRIPT'"
if grep -q "^alias vs=" "$BASHRC" 2>/dev/null; then
  existing="$(grep "^alias vs=" "$BASHRC" | head -1)"
  if [ "$existing" = "$ALIAS_VS" ]; then
    ok "Alias 'vs' already configured correctly"
  else
    warn "Alias 'vs' exists but differs -- replacing"
    if confirm "OK?"; then
      sed -i.bak "/^alias vs=/d" "$BASHRC"
      echo "$ALIAS_VS" >> "$BASHRC"
      ok "Replaced"
    fi
  fi
else
  info "Adding alias 'vs' to $BASHRC"
  if confirm "OK?"; then
    echo "$ALIAS_VS" >> "$BASHRC"
    ok "Added"
  fi
fi

# --- alias vp ---
ALIAS_VP="alias vp='$PUSH_SCRIPT'"
if grep -q "^alias vp=" "$BASHRC" 2>/dev/null; then
  existing="$(grep "^alias vp=" "$BASHRC" | head -1)"
  if [ "$existing" = "$ALIAS_VP" ]; then
    ok "Alias 'vp' already configured correctly"
  else
    warn "Alias 'vp' exists but differs -- replacing"
    if confirm "OK?"; then
      sed -i.bak "/^alias vp=/d" "$BASHRC"
      echo "$ALIAS_VP" >> "$BASHRC"
      ok "Replaced"
    fi
  fi
else
  info "Adding alias 'vp' to $BASHRC"
  if confirm "OK?"; then
    echo "$ALIAS_VP" >> "$BASHRC"
    ok "Added"
  fi
fi

# -------------------- step 7: summary --------------------
step "Step 7/7 -- Summary"
cat << EOF

${GREEN}${BOLD}Server $SERVER_ID ($SERVER_NAME) configured.${NC}

  Vault:        $VAULT_PATH
  Server ID:    $(cat "$SERVER_ID_FILE" 2>/dev/null || echo '(not set)')
  Hook:         $(test -x "$HOOK_DST" && echo "installed" || echo "MISSING")

  Apps:
EOF
for app_entry in "${APPS[@]}"; do
  app_name="${app_entry%%|*}"
  app_path="${app_entry##*|}"
  if [ -f "$app_path/CLAUDE.md" ]; then
    printf "    OK %s -> %s\n" "$app_name" "$app_path/CLAUDE.md"
  else
    printf "    -- %s -> CLAUDE.md missing\n" "$app_name"
  fi
done

cat << EOF

  vault-sync script: $(test -x "$SYNC_SCRIPT" && echo "installed" || echo "missing")
  vault-push script: $(test -x "$PUSH_SCRIPT" && echo "installed" || echo "missing")
  Alias 'vs':        $(grep -q "^alias vs=" "$BASHRC" && echo "configured" || echo "missing")
  Alias 'vp':        $(grep -q "^alias vp=" "$BASHRC" && echo "configured" || echo "missing")

${BOLD}How to use:${NC}
  source ~/.bashrc             # reload aliases (or open a new shell)
  vs                           # sync the vault (pull from central remote)
  vp "myapp: short message"    # show status, ask, commit + push
  # then start your editor / LLM agent in the app working directory;
  # the per-app CLAUDE.md will be picked up automatically.


EOF

ok "Done."
