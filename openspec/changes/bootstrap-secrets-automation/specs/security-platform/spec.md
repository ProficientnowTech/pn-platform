## ADDED Requirements

### Requirement: Automated Secret Bootstrap Pipeline
Platform deployments SHALL generate bootstrap Kubernetes Secrets and corresponding PushSecret resources from encrypted templates so that secrets are available before Vault is healthy, and Vault automatically becomes the source of truth without manual intervention.

#### Scenario: Bootstrap secrets applied before stacks
- **WHEN** the platform bootstrap scripts run (run/deploy entrypoints)
- **THEN** they render namespace-scoped Secrets for every application from encrypted templates
- **AND** apply those Secrets prior to syncing the ArgoCD stack order so workloads can start immediately.

#### Scenario: PushSecrets seed Vault automatically
- **WHEN** the Vault application reaches a healthy state
- **THEN** PushSecret resources write the bootstrap values into the corresponding Vault KV paths
- **AND** after successful writes, the PushSecrets are deleted so External Secrets becomes the only writer.

### Requirement: Vault-Sourced Application Secrets
All platform applications (including ArgoCD, Crossplane, security stack, developer-platform, and development-workloads) MUST consume their credentials via External Secrets backed by Vault, with no plaintext secrets committed in their charts.

#### Scenario: ArgoCD repo + OIDC config from Vault
- **WHEN** ArgoCD installs
- **THEN** its Git repository credentials and Keycloak OIDC client configuration are delivered via External Secrets reading from Vault paths populated by the bootstrap pipeline
- **AND** the configuration remains present even if Keycloak isn’t reachable yet, so OIDC works automatically once Keycloak is online.

#### Scenario: Developer workloads receive secrets post-ESO sync
- **WHEN** External Secrets Operator syncs a developer workload namespace (e.g., Backstage, Harbor, Verdaccio, Kargo)
- **THEN** it reads the Vault path seeded by PushSecrets and creates the Kubernetes Secret before the workload helm chart reconciles
- **AND** no `kubectl create secret` or manual vault login is required during bootstrap or rotation.

### Requirement: Ordered Stack Deployment with Secret Dependencies
The target chart MUST enforce the 10-stack deployment order (infrastructure → storage → security → monitoring → data-streaming → platform-data → developer-platform → development-workloads → application-infra → backup/DR) with sync waves that ensure bootstrap secrets, Vault, PushSecrets, and External Secrets run before dependent workloads.

#### Scenario: Vault precedes PushSecret waves
- **WHEN** ArgoCD syncs the platform root Application
- **THEN** the security stack (Crossplane, Vault, ESO, Keycloak) deploys before any PushSecret or workload that depends on Vault
- **AND** PushSecret helper apps/jobs run only after Vault is healthy, ensuring successful writes.

#### Scenario: Workloads wait for ExternalSecret readiness
- **WHEN** a workload chart (e.g., developer-platform) reaches its sync wave
- **THEN** its namespace already contains the ExternalSecret and resulting Secret marked Ready
- **AND** ArgoCD does not mark the Application Healthy until the ExternalSecret status is true, preventing crash loops due to missing credentials.
