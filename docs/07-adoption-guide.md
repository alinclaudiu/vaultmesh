# 07 — Adoption guide: bring this to your org in one day

A practical playbook. You start the morning with no vault and finish the day with one running across your servers, your apps documented at a stub level, and the team able to add to it.

## Hour 0–1: decide if this fits

Re-read [01 — Concept](01-concept.md) under the heading "Who this is for." Be honest. Three checks:

- **Number of services / servers.** 2–10 / 2–6 is the sweet spot. Outside that, adapt or don't bother.
- **LLM in the loop.** If your team isn't using Claude Code, Cursor, Aider, or similar, the pattern still works but the maintenance burden is on humans. You'll be back to wikis-that-die in three months.
- **Discipline tolerance.** Will your team write a log entry at the end of every session? If you can't get that, the wiki goes stale fast.

If two of three are "no," **do not adopt VaultMesh today.** Try Karpathy's plain pattern in a single repo first. Come back when you outgrow it.

## Hour 1–2: design your topology

Open a scratch document. Answer:

1. **What are your apps?** List them. For each: what is its role in one sentence?
2. **What server does each run on?** Number the servers (1, 2, 3, …). Group apps by server.
3. **What integrations exist between apps?** For each integration, who's the producer and who's the consumer? What's the subject (e.g., "orders", "product catalog", "daily sales")?
4. **What flows exist that traverse multiple apps?** A flow is a journey — "customer places an order and it eventually ships." List 2–4 of these.

Output: a table.

```
Apps:
  α (storefront, server 1)
  β (admin, server 1)
  γ (inventory, server 2)
  δ (POS, server 3)
  ε (aggregator, server 2)

Integrations:
  01 — γ → δ : product catalog
  02 — δ → γ : daily sales
  03 — α → β : new orders
  ...

Flows:
  customer-order-lifecycle
  end-of-day-reconciliation
  product-catalog-sync
```

This table is the seed of your wiki.

## Hour 2–3: bootstrap the vault repo

```bash
# 1. Clone VaultMesh
git clone https://github.com/your-org/vaultmesh.git ~/vaultmesh

# 2. Initialize your vault from the template
cp -r ~/vaultmesh/template ~/my-vault
cd ~/my-vault

# 3. Edit CLAUDE.md to match your topology
$EDITOR CLAUDE.md
# - List your apps and their servers
# - Adjust ownership rules if you need exceptions
# - Update the path conventions to your file layout

# 4. Set up a central git remote you control
# (your own gitea/gogs/private GitHub, NOT a public host)
git init
git add .
git commit -m "init: vault seeded from VaultMesh template"
git remote add origin <your-central-git-url>
git push -u origin main
```

You now have an empty vault on a central remote.

## Hour 3–4: write per-app CLAUDE.md files

In the VaultMesh checkout, you'll add files like:

```
~/vaultmesh/per-app-claude-md/
├── α.md          # rules for sessions started in α's working directory
├── β.md
├── γ.md
├── δ.md
└── ε.md
```

Use `template/apps/_per-app-CLAUDE.md.example` as a starting point. For each app, fill in:

- Allowed writes (`wiki/apps/{this-app}/**`, plus integrations where this app is producer/consumer)
- Forbidden writes (everything else)
- Local quirks (this app's particular conventions, recurring failure modes, stakeholders)

These files are short — typically 50–100 lines each. Plan ~10 minutes per app.

## Hour 4–5: bootstrap each server

On each server, install VaultMesh and run the setup:

```bash
# On Server 1
git clone https://github.com/your-org/vaultmesh.git ~/vaultmesh
cd ~/vaultmesh

# Create a per-server config
cp deploy/servers/server-N.conf.example deploy/servers/server-1.conf
$EDITOR deploy/servers/server-1.conf
# - Set SERVER_ID=1
# - Set REMOTE_GIT to your central git URL
# - Set VAULT_PATH to ~/vault (or wherever you want)
# - Set PACKAGE_PATH to the VaultMesh checkout location
# - Fill APPS=("α|/path/to/α" "β|/path/to/β")

# Run setup
bash deploy/setup-server.sh deploy/servers/server-1.conf
```

The script clones the vault, marks the server, installs the pre-commit hook, drops per-app CLAUDE.md files into each app's working directory, configures git identity, and adds `vs` / `vp` aliases to your shell.

Repeat on each server with the appropriate `server-N.conf`. Total time: ~10 minutes per server once the script is familiar.

## Hour 5–7: seed the wiki

Now the human work. On any one server (probably the one with the most apps you know best):

```bash
vs   # pull, get the empty initial state
```

Then, for each app, create a stub `apps/{app}/README.md`:

```bash
cd ~/vault/wiki/apps
mkdir α
$EDITOR α/README.md
```

Use `_templates/app.md` as a starting point. Fill in:
- Role and responsibility (the one-sentence answer from Hour 1)
- Stack (framework, language, database)
- Server number
- One-liner per main module (don't write the module pages yet — just list them)

For each integration in your table, create a stub:

```bash
cd ~/vault/wiki/integrations
$EDITOR 01-γ--δ--product-catalog.md
```

Use `_templates/integration.md`. Fill in just transport, frequency, and a one-paragraph "what flows" — leave schema details for later.

For each flow, create a stub similarly.

Aim for **stubs, not finished pages**. The point is to have the structure in place. Pages get filled in over the next weeks as you do real work and the LLM pulls from your sessions.

```bash
vp "init: seed vault with stubs for $(ls apps/) apps and $(ls integrations/ | wc -l) integrations"
```

## Hour 7–8: convert your team

Tell each engineer:

1. Pull the latest dotfiles / shell config so they get `vs` and `vp`.
2. Their app's working directory now has a `CLAUDE.md`. Their LLM agent will pick it up automatically next time they start a session there.
3. The discipline:
   - **Start of session**: run `vs`. Check `head -20 wiki/log.md`. Now you know what changed.
   - **During session**: when the LLM offers to write a wiki page, let it.
   - **End of session**: have the LLM (or you) write a log entry. Then `vp "..."` with explicit confirmation of the diff.

A 5-minute live demo is worth more than any documentation here. Walk one engineer through it; they'll teach the rest.

## Hour 8: the first real session

Pick a real task — a bug you're investigating, a feature you're shipping, a refactor you've been putting off. Start a session. Run `vs`. Work. End with `vp`.

What you'll notice:

- The first session feels awkward. The discipline feels like overhead.
- The third session feels normal. The log is a useful start-of-day primer.
- The tenth session feels indispensable. You catch something on Server 4 that you'd have missed because Server 2 logged it yesterday.

That's the point at which you can declare success.

## Common pitfalls

**Skipping `vs`.** The whole pattern depends on it. If the team starts skipping, the wiki goes stale fast. Make `vs` part of the start-of-session ritual, like checking Slack.

**Auto-confirming `vp`.** Some teams configure the LLM to auto-approve. Don't. The diff review is the cheap insurance against everything from secret leaks to wrong-tone wiki pages.

**Writing pages without log entries.** A page change without a log entry is invisible to the rest of the mesh. Always log.

**Treating the wiki as canonical when the code disagrees.** The code is authoritative. The wiki documents the *understanding* of the code. When they conflict, fix the wiki to match the code, not the other way around.

**Filling in the case study you don't run.** Don't write fictional pages because the template suggests it. Stubs are fine. The wiki grows from real work.

## After day one

Two things to do in the first week:

1. **Establish a log-reading habit.** Five minutes at the start of each work day, scan the new log entries from yesterday. You'll catch things and the team will start writing log entries that are *informative* rather than *minimal* (because they know someone's reading them).

2. **Schedule a 30-minute lint pass at week's end.** Manually skim `wiki/index.md` (you'll need to update it by hand for now), look for stubs that should be filled in, look for orphans. The lint operation will eventually automate this; until then, do it once a week and it's enough.

That's it. Your org now runs on a VaultMesh. Welcome.
