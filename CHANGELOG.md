# Changelog

All notable changes to VaultMesh are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] — 2026-05-08

Initial public release. Pattern + reference implementation, extracted and sanitized from a working production deployment (5+ apps × 4 servers, several months of operation).

### Added

- **Pattern documentation** in `docs/`:
  - `01-concept.md` — why a distributed LLM Wiki
  - `02-architecture.md` — three layers + N-server topology
  - `03-ownership-model.md` — scoped writes, producer/consumer contracts, ADR workflow
  - `04-sync-protocol.md` — `vs` / `vp` mechanics, conflict avoidance
  - `05-security-model.md` — pre-commit hook, secret patterns
  - `06-vs-karpathy.md` — side-by-side with the original LLM Wiki gist
  - `07-adoption-guide.md` — bring this to your org in one day
- **Mermaid diagrams** in `docs/diagrams/`: three-layer, topology, sync-sequence, ownership-matrix
- **Drop-in template** in `template/`: root `CLAUDE.md`, per-app schema example, frontmatter templates for app / integration / flow / ADR pages
- **Bootstrap tooling** in `deploy/`: `setup-server.sh` (idempotent, 7-step), per-server config example, `pre-commit` security hook
- **Shell aliases** in `scripts/`: `vault-sync.sh` (`vs`), `vault-push.sh` (`vp`), `install-aliases.sh`
- **Full case study** in `examples/case-study-ecommerce/`: fictional 5-app / 3-server e-commerce ecosystem with ~15 wiki pages, ~20 log entries, 3 integration contracts, 2 cross-app flows, 1 ADR, 1 debugging page, 1 runbook

### Known limitations

- No `lint` operation yet — orphan/contradiction/frontmatter validation is on the roadmap
- `index.md` regeneration is currently manual
- No ingest tooling beyond what Karpathy's gist describes (use Obsidian Web Clipper for now)
- Git is the only sync transport; alternatives (Syncthing, S3, HTTP) are roadmap items
