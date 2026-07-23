# Secret Management Capability

## ADDED Requirements

### Requirement: Vault Deployment
The platform SHALL provide HashiCorp Vault in HA mode for centralized secret management.

#### Scenario: Deploy Vault HA
- **WHEN** Vault chart is deployed
- **THEN** 3 Vault replicas are running
- **AND** Vault is initialized and unsealed
- **AND** Raft storage backend is functioning

#### Scenario: Auto-unseal after restart
- **WHEN** a Vault pod is restarted
- **THEN** the pod auto-unseals using Kubernetes secrets
- **AND** the Vault instance rejoins the cluster

### Requirement: Kubernetes Authentication
The platform SHALL support Kubernetes-native authentication for Vault access.

#### Scenario: Configure Kubernetes auth
- **WHEN** Kubernetes auth method is enabled
- **THEN** pods can authenticate using ServiceAccount tokens
- **AND** roles map ServiceAccounts to policies

#### Scenario: Pod authenticates to Vault
- **WHEN** a pod with ServiceAccount token calls Vault
- **THEN** Vault validates the token
- **AND** returns secrets based on assigned policy

### Requirement: External Secrets Operator
The platform SHALL provide External Secrets Operator for syncing Vault secrets to Kubernetes Secrets.

#### Scenario: Deploy ESO
- **WHEN** External Secrets Operator chart is deployed
- **THEN** ESO controller pods are running
- **AND** ExternalSecret and SecretStore CRDs are registered

#### Scenario: Sync secret from Vault
- **WHEN** an ExternalSecret resource references a Vault path
- **THEN** ESO retrieves the secret from Vault
- **AND** creates a Kubernetes Secret with the data
- **AND** keeps the Secret updated when Vault changes

### Requirement: Cross-Cluster Secret Access
The platform SHALL support workload clusters accessing secrets from primary cluster Vault.

#### Scenario: Configure Vault auth for workload cluster
- **WHEN** a workload cluster is provisioned
- **THEN** Kubernetes auth is configured for the workload cluster
- **AND** workload cluster ServiceAccounts can authenticate

#### Scenario: Workload app accesses Vault secret
- **WHEN** an app in workload cluster creates ExternalSecret
- **THEN** ESO authenticates to primary cluster Vault
- **AND** syncs secret to workload cluster
- **AND** app can use the secret

### Requirement: Secret Hierarchy
The platform SHALL organize secrets in a hierarchical structure by purpose and environment.

#### Scenario: Store cluster credentials
- **WHEN** a cluster is provisioned
- **THEN** kubeconfig is stored at `secret/clusters/{env}/kubeconfig`
- **AND** cluster access is controlled by policy

#### Scenario: Store database credentials
- **WHEN** a database is provisioned
- **THEN** credentials are stored at `secret/database/{env}/{name}`
- **AND** applications can request access via policy
