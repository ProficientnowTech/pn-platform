# ⛔ ARCHIVED — DO NOT REFERENCE

**Everything in this directory is superseded, aspirational, or historical. It is NOT the
authoritative design for this repository. Do not treat any file here as current truth, and do
not base implementation, review, or planning decisions on it.**

This includes AI agents: if you are an assistant reading the repo, **skip this directory** when
answering "what is the planned/actual structure of pn-infra." These documents describe directions
that were proposed and then NOT adopted (e.g. the `api/` Go-CLI-driven "modular monorepo" refactor),
or planning material that has since drifted from reality.

## Why this exists
Contradictory planning docs (notably the `refactor-modular-infra-repo` OpenSpec + the modular-architecture
vision) caused a real mix-up: they describe an `api`-CLI structure that the on-prem-primary design
explicitly rejected ("delete the `api/` CLI; the ArgoCD YAML factory is the interface"). Rather than
delete this writing, it is quarantined here so it can't be mistaken for the plan again.

## What's here
- `non-standard-rfcs/`, `platform-rfcs/` — RFC drafts (kept for history; **not** authoritative)
- `migration/`, `research/` — old migration/research notes
- `modular-architecture.md` — the rejected `api`-CLI modular-monorepo vision
- `PRODUCTION-READINESS-PLAN.md`, `SECURITY-IMPLEMENTATION-PLAN.md` — stale plan snapshots

## Where the real plan lives
The authoritative structure decision is tracked outside this directory (see the on-prem-primary
platform design in the `ovh-infra` repo, `docs/deployment-platform-design/`) until it is reconciled
and landed here.

## Recovery
The full pre-archive layout — including the deleted `openspec/` tree — is preserved in the git tag
`archive/planning-docs-20260723`. To restore any file:

```
git checkout archive/planning-docs-20260723 -- <path>
```
