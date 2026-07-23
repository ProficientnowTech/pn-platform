## Why
Developer-platform and development-workloads stacks currently embed credentials directly in Git and rely on anonymous/weak auth paths (e.g., Verdaccio). We need consistent Vault-backed secrets, Keycloak + Azure AD federated access control, and GitOps automation so teams can enforce fine-grained permissions (e.g., limit Harbor registry push per user) and deliver a fully equipped Backstage portal.

## What Changes
- GitOps-manage Vault mounts, KV data, policies, and Kubernetes auth roles for developer and workloads stacks; External Secrets Operator becomes the sole path for Kubernetes secrets.
- Expand Keycloak configuration (Crossplane) to federate Azure AD, create app-specific clients, scopes, and group hierarchies, and surface claims that downstream tools consume for RBAC (Harbor, Verdaccio, Kargo, Tekton, Argo Rollouts, Backstage).
- Update each application chart/values to remove static secrets, consume ExternalSecrets, and enforce OIDC (oauth2-proxy where needed). Verdaccio gains mandatory authentication. Harbor enforces per-registry roles via Keycloak groups.
- Enrich Backstage so developers see the tools/templates they need, and ensure SSO plus secret loading works from Vault.

## Impact
- Affected specs: security stack (Crossplane/Vault/Keycloak), developer-platform stack, development-workloads stack.
- Affected code: `platform/stacks/security/charts/*`, `platform/stacks/developer-platform/**`, `platform/stacks/development-workloads/**`, plus new Vault/Keycloak resources.
