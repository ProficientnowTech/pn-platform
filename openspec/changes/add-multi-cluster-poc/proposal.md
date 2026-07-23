# Multi-Cluster Platform PoC Proposal

## Why

The current platform infrastructure lacks the capability to provision isolated Kubernetes clusters per environment, manage secrets centrally, and provide self-service infrastructure provisioning. This limits our ability to:

1. Provide strong environment isolation for dev, staging, UAT, preprod, production, and sandbox
2. Enable developers to self-service infrastructure requests without manual intervention
3. Manage secrets and credentials consistently across multiple clusters
4. Leverage existing bare metal capacity efficiently with virtual clusters

## What Changes

This proposal introduces a **minimal viable proof of concept** for a multi-cluster platform that demonstrates:

### Core Capabilities

1. **Cluster Provisioning (ClusterAPI + KubeVirt)**
   - Deploy ClusterAPI with KubeVirt infrastructure provider
   - Provision one proof-of-concept workload cluster (dev environment)
   - Configure Kube-OVN CNI for live migration support
   - Deploy KCCM for LoadBalancer services in workload clusters

2. **Secret Management (Vault + External Secrets Operator)**
   - Deploy Vault in HA mode with Raft storage
   - Configure Kubernetes authentication for primary cluster
   - Deploy External Secrets Operator in primary cluster
   - Demonstrate cross-cluster secret access pattern

3. **Identity & Access Management (Keycloak)**
   - Deploy Keycloak for centralized authentication
   - Configure OIDC integration with ArgoCD
   - Set up user authentication for platform services
   - Create initial realm and client configurations

4. **Infrastructure as Code (Crossplane)**
   - Deploy Crossplane with required providers (Kubernetes, Helm, SQL)
   - Create Kubernetes Cluster XRD and Composition for ClusterAPI
   - Create Database XRD and Composition for PostgreSQL
   - Provision dev cluster via Crossplane claim

5. **Developer Portal (Backstage)**
   - Deploy minimal Backstage instance
   - Configure authentication with Keycloak
   - Create software template for cluster provisioning
   - Create software template for database provisioning

### Integration Points

- **ArgoCD**: Manage both primary and workload cluster applications
- **Vault**: Store kubeconfigs, database credentials, and application secrets
- **Keycloak**: Single sign-on for ArgoCD, Backstage, and future services
- **Crossplane**: Provision clusters and databases declaratively via GitOps

## Impact

### New Capabilities Added

- `cluster-provisioning`: ClusterAPI + KubeVirt cluster lifecycle management
- `secret-management`: Vault + ESO centralized secret distribution
- `identity-access`: Keycloak-based authentication and authorization
- `developer-portal`: Backstage self-service infrastructure provisioning

### Affected Components

- **Platform target-chart**: Add new applications (Vault, Keycloak, Crossplane, ClusterAPI, Backstage)
- **Platform charts**: New chart configurations for all new components
- **Documentation**: Complete setup and usage guides in `v0.2.0/platform/docs/ci-cd/`
- **Infrastructure topology**: Changes from single-cluster to multi-cluster architecture

### Breaking Changes

None - this is additive to existing platform infrastructure.

### Dependencies

- **Kubernetes**: v1.31+ (current: v1.32.8) ✅
- **Storage**: CephFS with ReadWriteMany support for VM live migration ✅
- **MetalLB**: For LoadBalancer services (already deployed) ✅
- **cert-manager**: For TLS certificates (already deployed) ✅
- **external-dns**: For automatic DNS records (already deployed) ✅

### Success Criteria

The PoC is successful when:

1. ✅ A dev Kubernetes cluster is provisioned via Crossplane claim
2. ✅ The dev cluster is reachable and running workloads
3. ✅ Vault stores and distributes secrets to both clusters
4. ✅ Keycloak authenticates users for ArgoCD and Backstage
5. ✅ Backstage can create cluster provisioning PRs via software templates
6. ✅ A demo application in dev cluster accesses shared PostgreSQL via Vault-managed credentials
7. ✅ All components are deployed via GitOps (ArgoCD)

### Out of Scope (Phase 2)

- Production-grade cluster configurations
- Multiple environment clusters (only dev for PoC)
- Advanced Keycloak realm configuration (RBAC, groups)
- Kargo progressive delivery integration
- Comprehensive monitoring and observability
- Disaster recovery and backup automation
- Multi-tenancy and resource quotas
