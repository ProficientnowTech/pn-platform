## Why
Secrets today depend on manual `kubectl` prompts (`run.sh`, `deploy.sh`) or static plaintext manifests committed under each chart. This breaks GitOps, forces humans to touch Vault, and prevents a clean end-to-end bootstrap. We need the kubriX-style flow where encrypted bootstrap values seed Kubernetes once, PushSecrets mirror them into Vault, and External Secrets takes over with no operator intervention.

## What Changes
- Add a reusable bootstrap secret generator (SealedSecret/SOPS → `Secret` + `PushSecret`) and wire it into `platform/run.sh`/`deploy.sh` so Argo apps never wait on manual input.
- Update stack charts (ArgoCD, security, developer platforms, workloads) to consume Vault via External Secrets only; bootstrap secrets disappear after PushSecrets sync.
- Ensure Argocd gets repo credentials + Keycloak OIDC config at install time even before Keycloak is live. Wire ArgoCD into vault bootstrap as a first-class secret consumer.
- Document the new bootstrap → Vault → ExternalSecret pipeline (diagrams + instructions) and align target-chart waves with the 10-stack order so dependencies (Vault, ESO, Crossplane) settle before workloads.

## Impact
- Scripts: `platform/run.sh`, `platform/deploy.sh`, new bootstrap tooling, docs.
- Charts/stacks: ArgoCD, security (Crossplane/Vault/ESO/Keycloak), developer-platform, development-workloads, infra secrets.
- Requires all environments to store sensitive defaults as encrypted artifacts (SealedSecrets or `.env` templates) committed to Git.
