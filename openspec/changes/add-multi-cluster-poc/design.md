# Multi-Cluster Platform PoC Design

## Context

Building a proof-of-concept multi-cluster platform on bare metal infrastructure to demonstrate environment isolation, centralized secrets, self-service provisioning, and progressive delivery.

**Constraints:**
- Bare metal infrastructure (no cloud provider)
- PoC scope: 1 dev cluster
- Existing: ArgoCD, MetalLB, cert-manager, external-dns, Ceph storage

## Goals / Non-Goals

### Goals
- ✅ Provision virtual Kubernetes cluster (dev) using ClusterAPI + KubeVirt
- ✅ Kube-OVN CNI for live migration support
- ✅ Centralized secret management with Vault + ESO
- ✅ SSO via Keycloak
- ✅ Self-service via Backstage
- ✅ Progressive delivery with Kargo
- ✅ Demo app showing cross-cluster secrets and progressive deployment

### Non-Goals
- ❌ Multiple environment clusters (only dev for PoC)
- ❌ Production-grade HA configurations
- ❌ Disaster recovery and backups

## Key Decisions

### Decision 1: Use Kube-OVN CNI
**Chosen:** Deploy Kube-OVN for workload cluster CNI
**Rationale:** Enables VM live migration, persistent pod IPs, required for production-like PoC

### Decision 2: Vault with Auto-Unseal
**Chosen:** Vault with Kubernetes-based auto-unseal
**Rationale:** Operational simplicity, avoids manual unsealing after restarts

### Decision 3: Dev Cluster Uses Primary Ceph Storage
**Chosen:** Dev cluster VMs use primary cluster Ceph via hostPath/network
**Rationale:** Simpler setup, unified storage management

### Decision 4: Include Kargo for Progressive Delivery
**Chosen:** Deploy Kargo alongside ArgoCD and Argo Rollouts
**Rationale:** Demonstrate complete GitOps pipeline with stage-based promotion

## Architecture

### Component Layout

```
Primary Cluster
├── Vault (sync wave 300)
├── External Secrets Operator (310)
├── Keycloak (320)
├── Kube-OVN (330)
├── KubeVirt + CDI (340)
├── ClusterAPI (350)
├── Crossplane (360)
├── Kargo (370)
├── Argo Rollouts (380)
├── Backstage (390)
├── PostgreSQL Shared (400)
└── Dev Cluster Claim (410)

Dev Cluster (workload)
├── Kube-OVN CNI
├── ingress-nginx
├── cert-manager
├── external-dns
├── External Secrets Operator
├── Argo Rollouts
└── Demo App
```

### Sync Wave Strategy

```
300: Vault
310: External Secrets Operator
320: Keycloak
330: Kube-OVN
340: KubeVirt + CDI
350: ClusterAPI
360: Crossplane + Providers
370: Kargo
380: Argo Rollouts
390: Backstage
400: Shared PostgreSQL
410: Crossplane Config (XRDs)
420: Dev Cluster Claim
```

## Implementation Phases

### Phase 1: Foundation
Deploy Vault, ESO, Keycloak. Verify secret distribution and SSO.

### Phase 2: Network and Virtualization
Deploy Kube-OVN, KubeVirt, ClusterAPI. Verify VM provisioning.

### Phase 3: Infrastructure as Code
Deploy Crossplane, create XRDs and compositions.

### Phase 4: Progressive Delivery
Deploy Kargo and Argo Rollouts integration.

### Phase 5: Self-Service Portal
Deploy Backstage with templates.

### Phase 6: Dev Cluster and Demo
Provision dev cluster, deploy demo app with Kargo-managed progressive deployment.

## Risks

1. **Kube-OVN Complexity**: Mitigate with minimal config, test thoroughly
2. **VM Storage Performance**: Use Ceph RBD for better performance
3. **Kargo Learning Curve**: Follow official examples, keep stages simple
