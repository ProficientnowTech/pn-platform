## ADDED Requirements

### Requirement: Vault GitOps Sources Developer Secrets
Developer-platform and development-workloads stacks SHALL source every Kubernetes Secret via Vault GitOps managed by Crossplane and External Secrets.

#### Scenario: Backstage pulls OIDC secret from Vault
- **WHEN** ArgoCD syncs the developer-platform stack
- **THEN** Crossplane ensures the Backstage OIDC + GitHub credentials exist under `secret/data/applications/developer-platform/backstage/app`
- **AND** External Secrets Operator populates the `backstage-secrets` Kubernetes Secret before the Backstage deployment starts.

#### Scenario: Harbor admin password rotates via GitOps
- **WHEN** the admin password in `platform/stacks/security/charts/crossplane/values.yaml` changes and Crossplane reconciles the Vault `KVSecretV2`
- **THEN** the Harbor ExternalSecret refreshes and updates `harbor-core-secrets`
- **AND** the Harbor pods consume the rotated password without manual kubectl edits.

### Requirement: Keycloak Federates Azure AD and Enforces Tool RBAC
Keycloak SHALL federate Azure AD identities, issue OIDC tokens for every developer tool (Harbor, Verdaccio, Backstage, Kargo, Tekton, Argo Rollouts), and expose group-based RBAC so operators can allow/deny per-tool actions (e.g., push to registry A only).

#### Scenario: Restrict Harbor push to Registry A
- **WHEN** a user lacks membership in the `harbor-registry-a-push` Keycloak group
- **THEN** Harbor OIDC login succeeds but the user cannot push images to Registry A
- **AND** adding the user to the group immediately grants push rights across all Harbor endpoints linked to that project.

#### Scenario: Verdaccio requires Keycloak login
- **WHEN** a developer accesses `npm.pnats.cloud`
- **THEN** oauth2-proxy enforces Keycloak authentication (federated with Azure AD)
- **AND** only users in `verdaccio-publishers` or `verdaccio-readers` proceed to Verdaccio, ensuring authenticated npm publish/install operations.
