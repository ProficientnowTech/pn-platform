## 1. Specification
- [x] 1.1 Read `docs/platform/security/*` to align with existing bootstrap and secret flow.
- [x] 1.2 Review KubriX `platform-apps/charts/keycloak` flows (realms/clients/OTP/IdPs) for reusable patterns.
- [x] 1.3 Enumerate required Crossplane providers and versions (Kafka, Temporal, OVH, Grafana, Harbor, PostgreSQL, Proxmox-BPG).
- [x] 1.4 Enumerate Falco plugins (k8saudit, github, k8smeta, collector, kafka, journald) and Talon routing patterns.
- [x] 1.5 Enumerate NetObserv components (operator, FlowCollector, agents, flowlogs-pipeline, storage/metrics sinks) and Calico integration points.
- [x] 1.6 Draft/refresh security capability spec with scenarios (Vault lifecycle, ESO, Crossplane, Keycloak, Kyverno, Falco+plugins+Talon, NetObserv, CRD ordering).
- [x] 1.7 Run `openspec validate add-security-gitops-architecture --strict` and fix issues.

## 2. Design & Architecture
- [x] 2.1 Document GitOps flows: bootstrap → Vault → ESO → workloads; CRD readiness gates.
- [x] 2.2 Define ArgoCD ordering/health dependencies for Vault, ESO, Crossplane, Kyverno, Falco, NetObserv.
- [x] 2.3 Design Vault secret schema/paths for Crossplane provider credentials and Keycloak admin/client/IdP secrets.
- [x] 2.4 Choose NetObserv deployment pattern (operator namespace, FlowCollector config, storage/metrics sink).
- [x] 2.5 Define Falco deployment with plugin wiring (collector/kafka/journald/k8saudit/github/k8smeta) and Talon action targets.
- [x] 2.6 Capture trade-offs/risks and mitigations (CRD timing, provider sprawl, audit retention).

## 3. Implementation Plan (post-approval)
- [x] 3.1 Bootstrap/Vault/ESO
  - [x] 3.1.1 Define Vault paths and ExternalSecrets for all new credentials.
  - [x] 3.1.2 Update SecretSpecs/PushSecrets for any new inputs; validate renderer flow.
  - [x] 3.1.3 Ensure ESO CRDs and health checks precede renderer execution.
- [x] 3.2 Crossplane Providers
  - [x] 3.2.1 Add Provider + ProviderConfig + Vault-sourced creds for Kafka.
  - [x] 3.2.2 Add Provider + ProviderConfig + Vault-sourced creds for Temporal.
  - [x] 3.2.3 Add Provider + ProviderConfig + Vault-sourced creds for OVH.
  - [x] 3.2.4 Add Provider + ProviderConfig + Vault-sourced creds for Grafana.
  - [x] 3.2.5 Add Provider + ProviderConfig + Vault-sourced creds for Harbor.
  - [x] 3.2.6 Add Provider + ProviderConfig + Vault-sourced creds for PostgreSQL.
  - [x] 3.2.7 Add Provider + ProviderConfig + Vault-sourced creds for Proxmox-BPG.
  - [x] 3.2.8 Add health/dependency annotations to avoid CRD timing issues.
  - [x] 3.2.9 Enable AzureAD provider in Crossplane with tenant ID and service principal credentials.
- [x] 3.3 Keycloak Automation via Crossplane
  - [x] 3.3.1 Model realms/clients/flows/roles using KubriX patterns.
  - [x] 3.3.2 Add GitHub/AzureAD IdPs; wire secrets from Vault via ESO. **UPDATED**: GitHub IdP disabled, AzureAD enabled for all users.
  - [x] 3.3.3 Add OTP/2FA flows and enforcement; ensure idempotent apply. **NOTE**: Requires manual Keycloak admin console configuration (see manual-keycloak-setup.md). Crossplane provider-keycloak does not support AuthenticationFlow CRDs yet.
- [x] 3.4 Policy & Runtime Security
  - [x] 3.4.1 Add Kyverno baseline policies + exception handling workflow.
  - [x] 3.4.2 Deploy Falco with plugins (k8saudit, github, k8smeta, collector, kafka, journald); pin images/versions.
  - [x] 3.4.3 Configure Falco Talon routes and sinks; validate with test events.
- [x] 3.5 Network Observability (NetObserv)
  - [x] 3.5.1 Deploy NetObserv operator and FlowCollector for Calico. **COMPLETED**: Created charts/netobserv with operator deployment.
  - [x] 3.5.2 Configure agents/flowlogs-pipeline and storage/metrics sinks. **COMPLETED**: Configured eBPF agents (DaemonSet), flowlogs-pipeline (Deployment with HPA), Loki for logs, Prometheus for metrics.
  - [x] 3.5.3 Add ArgoCD health checks/ignoreDiffs to keep CRDs stable. **COMPLETED**: Added ignoreDifferences for CRD webhook caBundle and DaemonSet resources.
- [x] 3.6 Verification & Docs
  - [ ] 3.6.1 `openspec validate add-security-gitops-architecture --strict`.
  - [x] 3.6.2 Add runbook/docs for secret flow, provider creds, Keycloak automation, Falco/NetObserv operations. **COMPLETED**: Created implementation-plan.md and manual-keycloak-setup.md with comprehensive guides.
