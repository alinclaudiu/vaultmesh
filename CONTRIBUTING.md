# Contributing to VaultMesh

VaultMesh is more pattern than software. There are three kinds of contribution we'd love:

## 1. Adoption stories

If you fork VaultMesh and run it on your own ecosystem, **tell us how it went** — even a one-paragraph issue with "I tried this for an org of N services and these three things broke" is gold. The pattern improves through contact with reality.

Open an issue tagged `adoption-story` with:

- Your topology (apps × servers, roughly)
- What worked unchanged
- What you had to modify
- What you'd want to see in v0.2

## 2. Documentation patches

The `docs/` deep-dives, the `examples/case-study-ecommerce/` scenario, and the README itself are the primary product. PRs that:

- Clarify a confusing passage
- Fix a broken wikilink in the case study
- Add a missing edge case to the security model
- Translate the README to another language

…are very welcome.

## 3. Code & tooling

The repo ships shell scripts, a pre-commit hook, and Mermaid diagrams. PRs that:

- Add a `lint` operation (orphan / contradiction / frontmatter validator) — this is the **biggest open piece**, see [ROADMAP.md](ROADMAP.md)
- Port `setup-server.sh` to other shells / OSes
- Add an alternative transport (Syncthing, S3, a tiny HTTP API) so VaultMesh works without git
- Build a minimal "live activity" dashboard that parses `log.md`

…are how this becomes a tool, not just a pattern.

## How to PR

1. Fork the repo
2. Branch off `main`: `git checkout -b your-thing`
3. Keep changes focused — one PR per concept
4. If your change affects the pattern (not just code), add a brief note to `CHANGELOG.md`
5. Open the PR with a description that tells the **why** before the **what**

We're not strict about commit format, but conventional commits (`docs: ...`, `feat: ...`, `fix: ...`) make changelogs easier.

## What we won't merge (lightly)

- **New dependencies in `setup-server.sh` or the pre-commit hook.** The bootstrap should run on a fresh Debian box with stock bash + git.
- **Real-name examples.** All examples must use the fictional `webstore / admin / inventory / pos / aggregator` ecosystem (or invent new fictional ones). We don't carry real org details into this repo, ever.
- **Schemas that change the YAML frontmatter contract** without a migration note. Existing vaults need to keep working.

## Code of conduct

Be useful, be brief, be kind. If something feels off in an interaction, flag it to the maintainers.
