## Context
Developer-platform and development-workloads stacks currently embed secrets in Git and expose dashboards without strong authentication. The security stack already supplies Crossplane, Vault, External Secrets, and Keycloak, but downstream stacks are not wired into that control plane. We must align them, bring Azure AD identities through Keycloak, and deliver granular RBAC (e.g., per-Harbor registry). Verdaccio also lacks authentication entirely.

## Goals / Non-Goals
- Goals: Vault-as-source-of-truth, GitOps-managed Keycloak clients/groups, Azure AD federation, OIDC for every developer tool, Verdaccio auth, enriched Backstage experience.
- Non-Goals: Replacing ArgoCD, changing base cluster networking, or rewriting app-specific business logic.

## Decisions
1. **Vault GitOps**: Use Crossplane provider-vault to define mounts/policies/kv pairs for each stack. ESO fetches secrets per-namespace. Secrets exit Git.
2. **Keycloak Federation**: Configure Azure AD as IdP; Keycloak remains central RBAC authority. Group hierarchy encodes privileges (harbor-registry-a-push, verdaccio-publishers, etc.).
3. **OIDC Everywhere**: Use native OIDC where available (Harbor, Kargo, Backstage). Use oauth2-proxy for Verdaccio/Tekton/Argo Rollouts if they lack first-class integration. Proxy/client secrets stored in Vault.
4. **Backstage Enhancements**: Add templates/catalog entries and surface documentation links for all developer workflows; rely on Keycloak OIDC for authentication.
5. **Argo Sync Order**: Introduce sync-wave annotations so Crossplane resources (Vault/Keycloak) materialize before ESO, and ESO before workloads relying on the secrets.

## Alternatives Considered
- **Direct Azure AD integration per app**: Rejected; Keycloak already centralizes auth and policies, and Crossplane automation exists there.
- **SealedSecrets**: Rejected; does not satisfy rotation/audit and still stores ciphertext in Git.
- **Different proxy (Dex/Istio)**: oauth2-proxy is simple and aligns with existing ingress patterns.

## Risks / Trade-offs
- Increased complexity in Argo sync ordering; mitigated via explicit sync waves and documentation.
- Dependence on Vault availability; mitigated by ESO cache and existing HA Vault deployment.
- Azure AD claim mapping nuances; need thorough testing to ensure group claims flow correctly.

## Migration Plan
1. Deploy new Vault mounts/policies (no app impact yet).
2. Deploy ExternalSecrets referencing new Vault paths; validate secrets populate existing K8s names.
3. Switch charts to remove embedded secrets and rely on ExternalSecrets.
4. Enable Keycloak clients/groups and integrate Azure AD IdP; test with pilot users.
5. Flip application auth configurations to OIDC/Keycloak.
6. Decommission old secrets/SealedSecrets.

## Open Questions
- Should Verdaccio use oauth2-proxy or native plugin? (defaulting to oauth2-proxy unless requirements change.)
- Do we need per-team namespaces for Harbor registries? (Current plan uses group-based project mappings.)
