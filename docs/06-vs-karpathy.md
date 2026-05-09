# 06 — VaultMesh vs Karpathy's LLM Wiki

A side-by-side. Read [Karpathy's gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) first if you haven't — VaultMesh assumes that pattern as its base.

## What we kept (verbatim)

- **The three-layer architecture**: `raw/` (immutable sources) + `wiki/` (LLM-distilled markdown) + the schema document (`CLAUDE.md`).
- **The operations vocabulary**: Ingest / Query / Lint as the core verbs the LLM performs against the wiki.
- **`index.md`** as a content catalog with one-line summaries.
- **`log.md`** as an append-only chronological journal.
- **The maintenance argument**: humans curate sources and ask questions, the LLM does the bookkeeping.
- **Frontmatter on every wiki page** (Karpathy mentions this lightly; we make it required).
- **Wikilinks** (`[[apps/x/y]]`) — Obsidian-style internal references.

## What we added

| Addition | Why | Where it lives |
|---|---|---|
| **Per-app `CLAUDE.md`** | Each LLM session is scoped to one app; it should see only its own rules | Dropped into each app's working directory by `setup-server.sh` |
| **Scoped ownership rules** | Multi-author wikis need write boundaries to be conflict-free | Encoded in both schema files |
| **`integrations/` folder** | Inter-app contracts need first-class pages with explicit producer/consumer ownership | New top-level wiki folder |
| **`flows/` folder** | Cross-app journeys need a navigation layer above per-app pages | New top-level wiki folder |
| **ADR proposal stage** | Org-wide decisions deserve a deliberation gate, not unilateral writes | `apps/{app}/proposed-adr/` → `decisions/` after human promotion |
| **`infrastructure/`** | Per-server documentation (what runs where) | New top-level wiki folder |
| **`shared/`** | Cross-cutting docs that don't belong to one app | New top-level wiki folder |
| **Multi-server git protocol** | Karpathy assumes a single Obsidian vault on one device | `vs` and `vp` shell aliases + central git remote |
| **`log.md` as message bus** | The append-only log carries inter-server awareness | New semantic role for an existing artifact |
| **Pre-commit hook** | A wiki replicated to N servers and edited by LLM agents needs a security boundary | `deploy/hooks/pre-commit` |
| **`setup-server.sh`** | New-server onboarding should be a single command | `deploy/setup-server.sh` |
| **`.server-id`** | Servers need to know their own number for log entries | Per-server file (gitignored) |

## The key conceptual moves

Three small ideas, none of which Karpathy's gist needs but all of which an organizational deployment does:

### 1. Ownership × append-only ⇒ conflict-free

Karpathy's pattern has one author (the LLM, on behalf of the user). Conflicts are impossible by construction. VaultMesh has N authors (one LLM session per server, plus humans). Conflicts are *possible*. The fix is two design choices that together make them *near-impossible*:

- **Scoped ownership**: each app writes to its own folder. Different files, no conflict.
- **Append-only writes** to `log.md`: two simultaneous appends rebase cleanly by timestamp.

This is the piece we're proudest of. It's not new — append-only logs are a 50-year-old idea in distributed systems — but the *combination* with per-folder ownership makes a multi-author markdown wiki actually work without a coordination layer.

### 2. The integration page

Karpathy describes cross-references as informal ("the LLM creates them as it goes"). In an organization, the contract between two services is the *most load-bearing* piece of knowledge. It deserves:

- A canonical filename (`NN-producer--consumer--subject.md`) so anyone can find it.
- An explicit owner (the producer).
- A "Consumer notes" section the consumer can write to without stepping on the producer.
- A "Breaking changes log" the producer maintains as the contract evolves.

This is just **putting structure on what was implicit**. But the structure changes how engineers think about cross-app changes — they look for the contract page first, write the breaking-change entry, then change code.

### 3. Two-aliases discipline

`vs` (sync, no confirmation, run autonomously by the agent at session start) and `vp` (push, requires explicit human confirmation) sound trivial. They're the entire human-in-the-loop story.

The reason `vs` is allowed without confirmation: it's read-only and idempotent. Worst case it fails on a network blip and the agent retries.

The reason `vp` requires confirmation: every push is an organizational broadcast. The next time anyone, anywhere, runs `vs`, they pull what you pushed. That deserves a human glance at the diff.

In Karpathy's single-user model, neither distinction matters. In a mesh, they're load-bearing.

## What's the same that you might think is different

A few things that look like additions but are really just *naming* what Karpathy already implies:

- **Strict frontmatter.** Karpathy mentions Dataview / metadata casually. We just turned it into a rule and added a hook check.
- **Wikilinks.** Karpathy's pattern works in Obsidian, where wikilinks are native. We just wrote down the convention.
- **The `apps/` folder.** Karpathy mentions "entity pages." `apps/{app}/README.md` is just an entity page where the entity is a service.

## What we're not (yet) carrying forward from Karpathy

Karpathy's gist mentions tools we haven't built into VaultMesh:

| Karpathy mentions | VaultMesh status |
|---|---|
| Obsidian Web Clipper for ingestion | Roadmap — useful for the `raw/` half |
| `qmd` for hybrid BM25+vector search | Roadmap — useful at scale |
| Marp for slide generation | Out of scope; use it externally if you want |
| Dataview plugin queries | Works in Obsidian if you choose; not assumed |
| Graph view | Works in Obsidian; not built into VaultMesh |
| Lint operation (orphans, contradictions, stale claims) | **Roadmap, biggest open piece** — see [ROADMAP.md](../ROADMAP.md) |

The `lint` operation is the most-mentioned-least-implemented part of Karpathy's gist, and ours is no exception. It's the next major piece we want to ship.

## Should you use VaultMesh or just Karpathy's pattern?

| Your situation | Use |
|---|---|
| One service, one server, one user | **Karpathy's pattern**, vanilla. VaultMesh is overkill. |
| Personal knowledge base, research notes, reading companion | **Karpathy's pattern.** Multi-server doesn't help you. |
| Small org (2–10 services, 2–6 servers), team of 1–5 engineers, LLM agents involved | **VaultMesh.** This is the sweet spot. |
| Mid-size org (10–30 services, 5–15 servers) | **VaultMesh, but read [ROADMAP](../ROADMAP.md) first.** Lint becomes important. |
| Large org (30+ services) | **Probably not VaultMesh as-is.** Sharding the mesh is on the roadmap; without it, the log gets noisy. |

## The credit

Everything VaultMesh adds is *additive* over Karpathy's pattern. We didn't replace anything. The original gist is a beautiful, deliberately abstract starting point; VaultMesh is one specific, opinionated way to instantiate it for a particular context (small engineering org, multi-server, LLM-driven). Other instantiations are absolutely possible and likely better for other contexts.

Read both. Pick what fits. Tell us how it went.
