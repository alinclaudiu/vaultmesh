# Vault — your-org-name ecosystem

Knowledge base for the [your-org] ecosystem: N applications across M servers, documented following the [VaultMesh](https://github.com/your-org/vaultmesh) pattern (a multi-server extension of [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)).

## Structure

- `CLAUDE.md` — global rules every LLM session must follow
- `raw/` — source material (articles, PDFs, transcripts, exports). Immutable.
- `wiki/` — distilled knowledge (apps, integrations, flows, infrastructure, shared, decisions)
- `_templates/` — page templates

## Setup on a new server

See `<vaultmesh-checkout>/deploy/README.md`. In short:

```bash
bash <vaultmesh-checkout>/deploy/setup-server.sh deploy/servers/server-N.conf
```

## How each app contributes

Every app has a `CLAUDE.md` in its production working directory. That file declares what an LLM session running from that directory may write to in the vault.

The general rule:

- Each app writes to `wiki/apps/{itself}/`
- Contributes to `wiki/integrations/` only where it's a producer (full ownership) or a consumer (the "Consumer notes" section only)
- Reads anything in the vault
- Never touches secrets, configs, or production data

## Conventions

See the root `CLAUDE.md` for the full set.
