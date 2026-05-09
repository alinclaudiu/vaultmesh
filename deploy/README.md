# Deploy — bootstrapping VaultMesh on a server

The `setup-server.sh` script is the only thing you should run on a new server. It is **idempotent**: running it again on a server that's already configured will detect what's done and skip those steps.

## Adding a new server

1. Create a config: `deploy/servers/server-N.conf` (copy `server-N.conf.example` as a starting point).
2. Edit it:
   - `SERVER_ID=N` — unique number per server (1, 2, 3, …)
   - `SERVER_NAME` — short descriptive label
   - `REMOTE_GIT` — your central git URL (the same URL on every server)
   - `VAULT_PATH` — where the vault lives on this server (typically `/home/<user>/vault`)
   - `PACKAGE_PATH` — where the VaultMesh checkout lives on this server
   - `APPS=(...)` — the apps that live on this server, with their real paths
3. Commit the config to your vault: `git add deploy/servers/server-N.conf && git commit && git push`. (Note: this commits *the config*, not server-specific secrets — there shouldn't be any in the config.)

## Running on a fresh server

```bash
# Assuming VaultMesh is checked out at $PACKAGE_PATH
cd $PACKAGE_PATH
bash deploy/setup-server.sh deploy/servers/server-N.conf
```

The script is interactive — it announces each step, asks for confirmation, and skips anything already done.

## Running again (re-sync / update)

Same command. Idempotency handles the rest.

## What the script does (7 steps)

1. **Clone or pull the vault** at `VAULT_PATH`.
2. **Write `.server-id`** so this server knows its own number.
3. **Install the pre-commit hook** that blocks secrets and enforces frontmatter.
4. **Drop a `CLAUDE.md` into each app's directory** so the LLM agent picks up per-app rules when started in that working directory.
5. **Configure `git user.name` / `user.email`** for the vault repo.
6. **Install `vs` and `vp` shell scripts and aliases** in `~/.bashrc`.
7. **Print a summary**.

## Troubleshooting

- **"Path for X does not exist"** → check `APPS=(...)` in your config; fill in the real path.
- **"Hook source does not exist"** → `PACKAGE_PATH` is wrong, or the hook file got moved.
- **"already exists and is not empty"** at clone time → the vault is already there; the script will fall through to a `git pull` next run.
- **`vs` or `vp` not found after running** → `source ~/.bashrc` or open a new shell.

## Security note

The `setup-server.sh` script writes to your `~/.bashrc`. Read it before running. If you're running it on a server you don't own, **don't**.
