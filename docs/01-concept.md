# 01 — Concept: why a distributed LLM Wiki

## The shape of the problem

A small engineering organization grows like this:

1. One service. One repo. One developer. Everything is in someone's head.
2. Three services. Two devs. The first wiki page gets written. It's about the deploy script. Nobody reads it.
3. Seven services on four servers. Five devs, two of them rotating. The CTO has the only complete mental model. When she goes on vacation, releases stop.
4. The wiki is now 200 pages of partial truth, last updated 18 months ago, and nobody trusts it.

The pattern is universal. **The wiki dies because maintaining it is bookkeeping**, and bookkeeping is the thing engineers will avoid forever in favor of shipping the next thing.

Andrej Karpathy's [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) gist points at the obvious move: an LLM doesn't mind bookkeeping. Give it a markdown wiki, a schema (`CLAUDE.md`), and a workflow (Ingest / Query / Lint), and it will keep the wiki current as long as humans keep feeding it sources and asking real questions.

That works for one user with one wiki.

## Where Karpathy's pattern stops short

Karpathy's framing is **personal**. One human, one LLM, one knowledge base. That's enough for research deep-dives, reading companions, hobby docs. The gist itself says it's deliberately abstract — "instantiate a version that fits your needs."

When you try to use that framing for a small engineering org, four problems show up:

1. **Multiple authors, multiple agents.** Three engineers each running Claude Code on different servers, all writing to "the wiki" — who owns what page? Who resolves conflicts? Karpathy doesn't have to answer this.

2. **Inter-app contracts.** When App A talks to App B, the contract between them is critical knowledge that isn't quite "App A docs" or "App B docs." Karpathy's pattern relies on cross-references — useful but informal. An organization needs the contract to be a *first-class artifact* with explicit producer/consumer ownership and a breaking-changes log.

3. **Sync.** A single Obsidian vault on one laptop syncs trivially. Five devs on four servers, each running an LLM that wants to update the wiki, *do not*. You need a real sync protocol with some discipline around when to pull, when to push, and what "push" requires of a human.

4. **Security.** A personal wiki on a personal device can hold whatever its owner is comfortable with. An organizational wiki replicated to multiple servers and edited by automated agents is a tasty target for an accidental `cat .env >> wiki/random-page.md`. You need a security boundary inside the wiki itself.

## The VaultMesh thesis

Solve those four problems with as little new machinery as possible:

1. **Scoped ownership.** Each app owns `wiki/apps/{itself}/**`. No app modifies another app's pages. Boundaries are encoded in each app's `CLAUDE.md`, so the LLM agent sees them at session start.

2. **Producer/consumer contracts.** A folder `wiki/integrations/` with files named `NN-producer--consumer--subject.md`. The producer owns the contract. The consumer writes only in the "Consumer notes" section. The breaking-changes log is producer-maintained.

3. **Git as the sync protocol.** A central git remote, every server has a clone, two shell aliases (`vs` for sync, `vp` for push) wrap `git pull --rebase --autostash` and `git status / commit / push` with discipline. The append-only `log.md` becomes a distributed message bus.

4. **Pre-commit hook as security boundary.** A hook that refuses commits containing recognizable secrets, paths matching common credential files, missing frontmatter, or files outside the vault structure.

Together these turn Karpathy's pattern from a *personal knowledge tool* into the *nervous system of a small org*.

## What you get for the trouble

The thing you didn't have before: **every server's awareness of what every other server has been doing**, on demand, as a side effect of the LLM session you were going to run anyway.

When an engineer (or LLM session) starts working on Server 4, the very first action is `vs`. That pulls the log. The log says: yesterday on Server 2, the `inventory` team changed the schema of the daily-sales contract; here's the breaking-changes log entry. Tomorrow on Server 1, the `webstore` team is freezing deploys for the holiday weekend. Last week on Server 3, the `aggregator` team finally killed the legacy OrderQueue.

None of that came from a standup, a Slack thread, or a 1:1. It came from `cat wiki/log.md | head -50`.

## The "consciousness" framing — and its limits

We use "consciousness" as a metaphor: the mesh has consciousness in the sense that any one node can see the recent state of every other node without having to ask. It's a *shared, eventually-consistent, append-only journal*, plus structured pages that the journal's entries reference.

It is **not**:

- Real-time. The mesh is as fresh as the last `vs`.
- A replacement for synchronous communication. If a server is on fire right now, you don't write a wiki page; you call someone.
- Infinitely scalable. We've run this comfortably with 5+ apps and 4 servers. Past 30 servers or 50 apps, you'd want to reconsider — the log gets noisy and the producer/consumer matrix becomes hard to navigate. Lint helps, sharding might too. We haven't needed to find out yet.

## Who this is for

You're a good fit if:

- You run **2–10 services** on **2–6 servers**.
- You're comfortable with **git** as a transport. You don't want to operate a wiki server.
- You have **at least one LLM agent** in your workflow (Claude Code, Cursor, Aider, anything that can read CLAUDE.md and write markdown). VaultMesh assumes the LLM does the bookkeeping — without it the pattern still works, but the maintenance burden is on humans, and you're back to wikis-that-die.
- You're willing to invest **one day** to set it up and a **few minutes per session** to follow the discipline (`vs` at start, log entry at end, `vp` with confirmation).

You're a poor fit if:

- You have **one app on one server**. Use Karpathy's original pattern; the multi-server machinery is overhead you don't need.
- You have **30+ services**. The log will overwhelm you. Wait for v0.2 with sharding.
- Your team **won't follow conventions**. The whole pattern depends on people writing log entries. If you can't get that discipline, the wiki goes stale and the metaphor breaks.

## Where to next

- **[02 — Architecture](02-architecture.md)** — the three layers, multi-server topology, how `log.md` works as a message bus.
- **[03 — Ownership model](03-ownership-model.md)** — how scoped writes and producer/consumer contracts make conflicts impossible.
- **[04 — Sync protocol](04-sync-protocol.md)** — the `vs` / `vp` mechanics in detail.
- **[06 — vs Karpathy](06-vs-karpathy.md)** — exactly what we kept and what we added.
