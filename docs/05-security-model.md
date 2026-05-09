# 05 — Security model

VaultMesh is a knowledge base, not a code repo, but it lives in git, gets pushed to a central remote, and is read by automated agents that have the keys to your kingdom. Treat it accordingly.

## Threat model

**What we're defending against:**

1. An LLM session writes a secret into a wiki page (because it pulled context from a config file and didn't filter it). On `vp`, that secret hits the remote and replicates to every server.
2. A human pastes a credential into a debugging page ("I tried this connection string and got X..."). Same outcome.
3. A misconfigured tool dumps a `.sql` file into the vault directory and someone runs `git add .`.
4. The remote git repo becomes public by accident (S3 bucket misconfigured, GitHub repo flipped from private to public, etc.).

**What we're explicitly not defending against:**

- A malicious insider with vault write access. If your engineer wants to leak secrets, no hook will save you. That's a personnel problem.
- Sophisticated steganography. The hook catches obvious patterns, not adversarial encodings.
- The LLM provider's data retention. Whatever you put in the LLM context is the LLM provider's problem; VaultMesh has no say.
- Compromise of the central git host. If your remote is breached, the whole vault is breached.

## Layer 1: prevention via convention

The schema (`CLAUDE.md`) explicitly forbids:

```
Never write to the vault:
- Passwords, tokens, API keys, connection strings
- Contents of .env, config/app.php, config/database.php, etc.
- Real customer data
- Production SQL dumps
- Anything that would be dangerous if the repo became public
```

The LLM reads this on session start. A well-tuned LLM respects it. This is your first line of defense and it catches 95% of cases.

But conventions get violated. So:

## Layer 2: the pre-commit hook

The `deploy/hooks/pre-commit` script runs on every commit. Four rules.

### Rule 1: forbidden filenames

```
*.env, .env, .env.*
*/config/app.php, */config/database.php, ...
*/settings.local.py, */local_settings.py
.htpasswd
id_rsa, id_ed25519, *.pem, *.key, *.p12
*.sql, *.dump, *.sql.gz
```

If the staged set contains any of these, **commit is rejected**. No override (other than `--no-verify`, which a human has to type explicitly).

### Rule 2: secret-pattern detection in content

The hook scans every staged text file for:

- **MySQL/Postgres connection strings with embedded passwords**: `mysql://user:pass@host/...`
- **Generic secret patterns**: `password|api_key|token = "..."` with at least 12 chars after the equals
- **AWS access keys**: `AKIA[A-Z0-9]{16}`
- **Bcrypt hashes**: `$2[ayb]$NN$<53chars>`
- **GitHub tokens**: `gh[pousr]_[A-Za-z0-9]{36+}`
- **Slack tokens**: `xox[abprs]-[A-Za-z0-9-]{20+}`

If a match is found, **commit is rejected**. The hook prints which pattern matched in which file (truncated to 3 lines so it doesn't echo the secret in full to the terminal).

False positives are filtered: matches that contain `example`, `placeholder`, `your_`, `xxx`, `<placeholder>`, `[example]`, `FILL_IN`, `TODO`, `REPLACE_ME` are ignored. Documentation that explains "API_KEY=YOUR_KEY_HERE" passes; documentation that paste-fails the actual key gets caught.

### Rule 3: frontmatter required on new wiki pages

Every newly added file under `wiki/*.md` (except `index.md`, `log.md`, `*/README.md`, and `*/proposed-adr/*`) must start with `---` (YAML frontmatter delimiter). Missing frontmatter produces a **warning**, not a rejection — frontmatter discipline is important but a warning is enough nudge in practice.

### Rule 4: structural bounds

Anything outside the allowed paths produces a warning:

```
Allowed: wiki/, raw/, _templates/, deploy/, scripts/, docs/,
         CLAUDE.md, README.md, CHANGELOG.md, ROADMAP.md,
         CONTRIBUTING.md, LICENSE, ATTRIBUTION.md,
         .gitignore, .gitattributes, .server-id.example
Forbidden: .server-id (it's per-server, must not be committed)
Warning:   anything else
```

### How to override (intentionally)

```bash
git commit --no-verify -m "..."
```

That's an explicit, loud bypass. The convention is: if you do this, you must also write a one-line note in the commit message saying *why* (e.g., "no-verify: false positive on bcrypt-shaped string in test fixture"). The next reviewer (or `git log`) sees the bypass and the reason.

## Layer 3: the human at `vp`

Before push, `vp` shows `git status --short` and asks for explicit confirmation. The human reviewing the diff is the last and best line of defense. Pre-commit hooks catch patterns; humans catch nuance.

The schema enforces this verbally:

> Never run `vp` without explicit user confirmation in chat.

If your LLM agent auto-confirms, fix the prompt. The discipline is more important than the convenience.

## Blast radius if it fails anyway

Suppose, despite everything, a secret lands in the wiki and gets pushed. Now what?

1. **The secret is in git history forever.** Force-push won't fix it (and we explicitly disallow force-push). Anyone who has cloned the vault has a copy.
2. **The actual fix is to rotate the secret.** Treat it as compromised. Generate a new one. Update the relevant `.env` files on production.
3. **Add a corrective entry to `log.md`** noting that the secret was leaked and rotated. Don't try to "scrub" the history — that's a security theater move that often makes things worse.
4. **Consider what allowed it through.** Was the convention violated? Did the hook miss a pattern? Add the pattern to the hook (PR welcome).

The realistic outcome of a leak is "we rotate the secret, we tighten the hook, we move on." The realistic *cost* is the rotation itself plus a brief audit. Not catastrophic — but not free either, which is why the three layers exist.

## What about the central git remote?

The remote is your single point of failure for confidentiality. Two recommendations:

1. **Don't use a public git host for VaultMesh.** Even if you trust the host, configuration accidents flip private to public. Run your own git server (a tiny VM with `gitea` or `gogs` or even raw `ssh+git`) on infrastructure you control.
2. **Mirror to a backup target.** Either another remote (`git remote add backup ...`) or a periodic clone-and-tar to S3/object-storage. The vault is small (megabytes); backups are cheap.

The reference deployment uses a private internal git host on a server inside the same VPN. Your topology may differ.

## What about LLM context retention?

If you pay an LLM provider, your prompts and responses may be retained for some period (varies by provider and plan). VaultMesh sends wiki pages and CLAUDE.md content into the LLM context on every session. If those pages contain anything sensitive, the LLM provider has it.

**Implications:**

- The schema's "never write secrets to the vault" rule is, transitively, a "never expose secrets to the LLM" rule. Same boundary.
- If you're regulated (GDPR, HIPAA, SOC 2, etc.), check your LLM provider's data agreement before committing real (anonymized but still personal) data into the vault.
- Anonymize aggressively. The fictional case study in `examples/case-study-ecommerce/` shows what fully-fictional looks like; aim for that level of synthetic detail in any wiki page that could conceivably be sensitive.

## A final word

Security is not a feature you bolt on — it's a property of how the whole system behaves under stress. VaultMesh's three layers (convention, hook, human) are deliberately overlapping. None of them is sufficient on its own. Together they make accidental leakage rare and recoverable.

If you find a gap, file an issue. If you find a leak in your own deployment, rotate, tighten, log, move on. **Don't shame the engineer who tripped the hook** — the hook tripping correctly is the system working as designed.
