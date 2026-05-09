# Roadmap

VaultMesh v0.1 is a pattern + reference implementation. The pieces below are not built yet; each is a viable PR.

## Near term — v0.2

### Lint as a CI job

A script that, run on `wiki/`, reports:

- **Orphan pages**: markdown files no other page links to (and that don't appear in `index.md`)
- **Broken wikilinks**: `[[apps/x/y]]` where the target file doesn't exist
- **Missing frontmatter**: pages without the required YAML header
- **Stale `updated:` dates**: pages whose `updated:` is older than N months (configurable)
- **Producer-only writes to integrations**: a consumer who edited anything outside the "Consumer notes" section
- **Direct writes to `wiki/decisions/`**: should always go through `proposed-adr/` first

Output: a report file plus an exit code. Wire it into GitHub Actions or any other CI.

### `index.md` regeneration

Right now `index.md` is described as "lint-generated" but the lint doesn't exist yet. Once lint lands, regenerate `index.md` from frontmatter (`type`, `status`, `owners`) on every push.

### A `vaultmesh init` command

A small CLI (Python, Go, or Bash — keep it dependency-light) that bootstraps a new vault from `template/` with sensible defaults, prompts for app names, and writes the per-app `CLAUDE.md` files for you.

## Mid term — v0.3+

### Ingest tooling

Karpathy's gist is rich on ingest. We currently leave `raw/` empty in production; the LLM works directly from wiki pages. To unlock the full pattern:

- Obsidian Web Clipper recipe / preset for VaultMesh
- A `vaultmesh ingest <url-or-file>` command that drops the source in `raw/`, prompts the LLM to write a summary page, log an entry, and update relevant cross-references
- Optional integration with [`qmd`](https://github.com/karpathy/qmd) (BM25 + vector hybrid search over markdown) so the LLM can find the right cross-references at scale

### Live activity dashboard

A static-site generator that reads `wiki/log.md` and produces:

- Timeline view of recent activity per server
- "What's hot this week" — files with the most edits
- Stale-page report (pages that haven't been `updated:` in ages)
- Integration health (every contract should have at least one log entry per quarter, or it's dead)

Could be a tiny SvelteKit / Astro / Next.js app, or even just a Python script that emits HTML.

### Alternative transports

Git is the obvious default but it's not the only option. PRs welcome for:

- **Syncthing**: works for offline-first servers, no central remote needed
- **S3 / Object storage**: useful when you don't want to run a git server
- **A tiny HTTP API**: think `vaultmesh-server` — receives diffs, fans out, holds an authoritative timeline

The `vs` / `vp` interface should remain the same; only the implementation changes.

### Multi-tenant variant

One VaultMesh repo, multiple isolated meshes (e.g., an agency managing several clients). Folder layout:

```
mesh-clientA/
  wiki/, raw/, CLAUDE.md
mesh-clientB/
  wiki/, raw/, CLAUDE.md
```

Per-mesh CLAUDE.md and per-mesh sync. Needs careful thinking about credential isolation (you don't want clientA's vault leaking into clientB's LLM context).

## Long term — research

### Cross-mesh federation

Two VaultMesh deployments that learn about each other through a shared *integrations* layer. Imagine two companies that have an API contract between them — the contract page lives in a federated mesh visible to both, while their internal wikis stay private.

### LLM-on-LLM lint

Use a smaller LLM as a watchdog: every commit to the vault triggers a review by a model that checks for contradictions with prior pages, dating violations, scope-of-ownership violations, etc. Findings filed as `proposed-adr/` for human review.

### "Why now?" auto-summarizer

A weekly job that reads the last 7 days of `log.md` and writes a `wiki/this-week.md` page summarizing the org's activity. Good for stand-ins and on-call rotations.

---

**The bias:** keep the core repo simple. Most items above belong as separate companion projects (`vaultmesh-lint`, `vaultmesh-dashboard`, `vaultmesh-ingest`) that compose with the core. Resist the temptation to bake everything into one binary.
