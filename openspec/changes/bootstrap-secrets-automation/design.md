## Context
- Secrets currently come from interactive prompts (Cloudflare token, SSH key) and static `*.secret` files inside charts.
- Vault/ESO/Crossplane stacks exist but apps can’t wait for Vault because their secrets aren’t populated yet.
- KubriX solves this by generating bootstrap Kubernetes Secrets + PushSecrets that copy the values into Vault once the cluster is ready. We’ll adopt that pattern with one encrypted source: **SealedSecrets**.

## Goals
- Zero manual secret entry during bootstrap.
- Vault becomes the single source of truth after bootstrap; External Secrets feeds workloads.
- Stack deployment order honours infra → storage → security → …
- ArgoCD itself is first-class: repo creds + Keycloak OIDC config exist on day one even if Keycloak isn’t live yet.

## Approach
1. **Install SealedSecrets Controller Before ArgoCD**
   - Extend `platform/deploy.sh` to install the Bitnami sealed-secrets chart (or kubeseal controller) immediately, outside of ArgoCD sync waves. This guarantees the controller and keypair exist before any bootstrap rendering.
2. **Bootstrap Generator**
   - Inputs: SealedSecret manifests committed under `platform/bootstrap/secrets/` (encrypted with the controller’s public key) plus metadata describing namespaces and Vault paths.
   - Outputs: for each entry, render a temporary namespace `Secret` and a matching `PushSecret` CR. Generator runs as part of `platform/run.sh`/`deploy.sh` before Argo sync.
3. **Run/Deploy Flow**
   - `platform/run.sh` invokes the generator, checks prerequisites, and fails fast if required SealedSecrets are missing.
   - `platform/deploy.sh` steps:
     1. Install sealed-secrets controller.
     2. Apply generated bootstrap Secrets so ArgoCD (and other early components) have credentials immediately.
     3. Install ArgoCD (existing script).
     4. Sync target chart waves. Once the security stack (Crossplane → Vault → ESO → Keycloak) is healthy, apply PushSecrets so Vault is seeded. After success, delete PushSecrets and plaintext bootstrap Secrets; ExternalSecrets (already defined in each chart) become the only source.
4. **Stack Charts**
   - All charts (ArgoCD, security, developer-platform, workloads) consume secrets via ExternalSecrets referencing Vault paths seeded above.
   - Security charts publish the necessary KV mounts, policies, and auth roles via Crossplane. ArgoCD Helm values include OIDC/repo settings pointing to these secrets.
5. **Sync Waves**
   - Negative waves: infrastructure and config apps (ingress, cert-manager, etc.).
   - Storage waves: rook/zalando/redis.
   - Security waves: Crossplane, Vault, ESO, Keycloak, Argocd self-management.
   - PushSecret helper resources scheduled immediately after Vault is healthy; ExternalSecrets follow; workloads last.
6. **Docs/Examples**
   - Expand `docs/platform/security/dev-workload-integration.md` with diagrams for the new pipeline and operator runbooks.
   - Crossplane examples mention PushSecrets and SealedSecret-driven bootstrap.

## Alternatives Considered
- Manual `vault kv put`: rejected.
- Git-only Vault CRs (no bootstrap secrets): requires privileged automation and still leaves workloads without initial values.
- SealedSecrets via ArgoCD wave: rejected because Argo itself needs secrets; installing the controller via script removes this chicken/egg problem.

## Risks & Mitigation
- Controller not ready: script waits for sealed-secrets CRDs/pods before rendering secrets.
- Secret leakage: SealedSecrets remain encrypted at rest; generated plaintext files live in a gitignored directory and are cleaned after deployment.
- Longer bootstrap time: acceptable; additional steps run once.

## Rollout Plan
1. Install sealed-secrets controller from `platform/deploy.sh` before any Argo work.
2. Implement generator + script scaffolding using SealedSecrets inputs.
3. Migrate ArgoCD + a pilot stack to PushSecret flow; validate end-to-end.
4. Update remaining stacks; remove legacy secrets.
5. Refresh documentation; run `openspec validate` and integration tests.
