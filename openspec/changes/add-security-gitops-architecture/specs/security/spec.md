## ADDED Requirements
### Requirement: GitOps Security Architecture Baseline
The platform SHALL define a GitOps-managed security stack with ordered ArgoCD applications (Vault → External Secrets Operator → Crossplane → policy/runtime security) and explicit CRD readiness checks so hooks and jobs never run before their CRDs exist.

#### Scenario: Security stack syncs safely
- **WHEN** the security applications are applied via ArgoCD
- **THEN** CRDs are installed and confirmed ready before dependent hooks/jobs run, and app ordering prevents wait-hook failures or Unknown health states.

### Requirement: Vault-Managed Secret Lifecycle
The platform SHALL manage all sensitive data through a bootstrap → Vault → ExternalSecret lifecycle so placeholder secrets are migrated to Vault without breaking existing workloads, and Vault remains the source of truth for Crossplane providers and applications.

#### Scenario: Bootstrap secret promotion
- **WHEN** the bootstrap renderer runs with required environment variables
- **THEN** it creates SealedSecrets for immediate use, PushSecrets to Vault, and ExternalSecrets later republish Vault data into workload namespaces with no manual secret edits.

### Requirement: Identity and Access Automation with Keycloak
The platform SHALL provision Keycloak realms, clients (OIDC), authentication flows (selective OTP/2FA), and roles via GitOps using Crossplane resources patterned after KubriX, with credentials sourced from Vault. Baseline flows: Browser = identity-first (AzureAD) + selective OTP (required for high-security apps: ArgoCD, Grafana, Harbor, Keycloak Admin; optional for standard apps: Backstage, Temporal UI, KubeVirt Manager, Kargo, Tekton Dashboard, Argo Rollouts, OneUptime, Verdaccio); Direct Grant = OTP conditional on client; Service accounts = client-credentials only; Admin console = OTP required. AzureAD brokered IdP provides SSO for all users (developers and admins); GitHub IdP is disabled.

#### Scenario: Git-driven realm/client provisioning
- **WHEN** realm, client, and flow definitions are committed (including GitHub/AzureAD IdPs and OTP/2FA flows)
- **THEN** Crossplane applies them idempotently to Keycloak using Vault-sourced credentials, producing healthy ArgoCD sync/health for the Keycloak app.

#### Scenario: App-to-flow assignment
- **WHEN** OIDC clients for ArgoCD, Grafana, Backstage, Verdaccio (oauth2-proxy), Harbor, Tekton Dashboard, Argo Rollouts, Kargo, OneUptime are reconciled
- **THEN** developer-facing apps (ArgoCD, Grafana, Backstage, Verdaccio, Harbor, Kargo, Tekton, Rollouts, OneUptime) are bound to GitHub IdP with OTP on interactive logins, and admin/workforce apps can also use AzureAD IdP; service-account usage remains client-credentials only.

### Requirement: Crossplane Provider Onboarding
The platform SHALL onboard and manage the following Crossplane providers with pinned versions and Vault-sourced credentials: Kafka, Temporal, OVH, Grafana, Harbor, PostgreSQL, and Proxmox-BPG, with GitOps-managed ProviderConfigs and compositions.

#### Scenario: Provider credentials from Vault
- **WHEN** a provider is installed and configured
- **THEN** its ProviderConfig pulls credentials from Vault via ExternalSecrets, and dependent managed resources reconcile successfully without embedding secrets in Git.

### Requirement: Policy and Runtime Security
The platform SHALL enforce baseline Kyverno policies (e.g., image provenance, privilege/drop, namespace safeguards) and deploy Falco with plugins (k8saudit, github, k8smeta, collector, kafka, journald) plus Falco Talon for action routing, all managed by ArgoCD.

#### Scenario: Kyverno + Falco enforcement
- **WHEN** policies and Falco rules are applied
- **THEN** Kyverno blocks or mutates non-compliant resources, Falco ingests Kubernetes/audit/GitHub events and node/system logs via collector/kafka/journald plugins, and Talon routes security actions/alerts without manual intervention.

### Requirement: Network Observability for Calico
The platform SHALL provide Calico-compatible network observability using the NetObserv operator (FlowCollector with eBPF agents/flowlogs-pipeline) for flow logs/metrics and policy visibility, and integrate it into the security monitoring pipeline.

#### Scenario: Calico observability enabled
- **WHEN** the NetObserv operator is deployed with FlowCollector agents on Calico nodes
- **THEN** flow-level visibility for Calico workloads is available, required CRDs are installed before use, and ArgoCD reports Healthy/ Synced status.
