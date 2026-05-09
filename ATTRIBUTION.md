# Attribution

VaultMesh is an extension of two prior ideas. We owe both, and want to be loud about it.

## Andrej Karpathy — *LLM Wiki* (2025)

The core three-layer pattern (raw sources / wiki / schema), the operations vocabulary (Ingest / Query / Lint), the append-only `log.md`, the "LLMs eliminate maintenance burden" framing, and the `index.md` as content catalog — all come from Karpathy's gist:

> https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

Karpathy framed it as a *personal* knowledge system. VaultMesh inherits the framing intact and extends it from one user × one wiki to N servers × M applications × one shared wiki, by adding ownership scoping, producer/consumer contracts, and a multi-server git protocol.

If anything in VaultMesh feels familiar from that gist, it is — and the credit is Karpathy's.

## Vannevar Bush — *As We May Think* (1945)

Bush's *Memex* — a personal device for storing, cross-linking, and re-finding knowledge through associative trails — is the philosophical ancestor of every wiki, every hyperlink, and every personal knowledge graph since. Karpathy himself nods to it in his gist. VaultMesh is, at heart, a *Memex for organizations*: trails between documents, but the trails are git commits and the librarians are LLMs.

> https://www.theatlantic.com/magazine/archive/1945/07/as-we-may-think/303881/

## Other influences

- **Obsidian** — the wikilinks syntax (`[[apps/x/y]]`) and the local-first markdown-vault model.
- **Architecture Decision Records** (Michael Nygard, 2011) — the ADR shape (Context / Decision / Alternatives / Consequences). VaultMesh adds a *proposed → promoted* workflow on top.
- **Conventional Commits** — the discipline of structured, parseable commit messages, applied here to log entries instead.
- **Git** — for being the right answer when the question is "how do I sync structured text across N machines without a server?"

## What we contribute

If anything in VaultMesh is novel, it is the *combination* — specifically:

1. The argument that **scoped ownership + append-only writes** make a multi-author wiki conflict-free.
2. The framing of the append-only log as a **distributed message bus** between servers/agents.
3. The producer/consumer contract page, with the "Consumer notes" and "Breaking changes log" sections, as a stable place for inter-app coordination.
4. The pre-commit hook as a security boundary inside a knowledge base — not just a code repo.
5. The ADR proposal stage (`apps/{app}/proposed-adr/`) as a deliberation gate before global decisions.

These are small ideas individually. Together they're what makes Karpathy's pattern survive contact with a real organization.
