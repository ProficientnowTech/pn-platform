# Project Context

## Purpose

**pn-infra** is a GitOps-driven Kubernetes platform infrastructure repository that deploys and manages a production-grade platform stack using ArgoCD. This repository represents the "Platform Layer" that sits on top of bare metal/VM infrastructure provisioned by the upstream infrastructure repository.

### Key Goals
- Provide a self-healing, declarative platform infrastructure
- Enable rapid application deployment with batteries-included services
- Maintain production-grade reliability with minimal operational overhead
- Support multi-tenancy with proper isolation and resource management
- Enable multi-cluster, multi-region deployments

## Tech Stack

### Core Infrastructure
- **Kubernetes**: v1.32.8 (deployed via Kubespray)
- **ArgoCD**: v8.6.3 (GitOps controller with self-management)
- **Helm**: v3.x (application packaging)

### Platform Stacks

The platform is organized into **12 modular stacks**, each responsible for a specific domain:

| Stack | Purpose | Key Components |
|-------|---------|----------------|
| **infrastructure** | Core K8s services | MetalLB, Ingress-Nginx, Cert-Manager, External-DNS, ArgoCD, Sealed-Secrets |
| **storage** | Distributed storage & operators | Rook-Ceph, Zalando PostgreSQL Operator, CloudNative-PG Operator |
| **security** | Secrets & identity | Vault, External Secrets, Keycloak, Crossplane |
| **platform-data** | Data services | PostgreSQL clusters, Redis, ClickHouse, MongoDB, RabbitMQ, Kafka, Debezium |
| **monitoring** | Observability | Prometheus, Grafana, Loki, Promtail, Tempo, Uptime-Kuma, Kubecost |
| **data-streaming** | Event streaming | Kafka/Strimzi, message brokers |
| **developer-platform** | Development tools | Harbor (registry), Backstage, Verdaccio, KubeVirt, ClusterAPI |
| **development-workloads** | CI/CD pipeline | Kargo, Tekton, Argo Rollouts |
| **application-infra** | Runtime infrastructure | Temporal |
| **backup-and-disaster-recovery** | Backup tooling | Velero |
| **ml-infra** | Machine learning | (planned) |
| **tenant-clusters** | Virtual clusters | vCluster for tenant isolation |

### Networking
- **Cilium**: Primary CNI
- **Kube-OVN**: Secondary CNI for advanced networking
- **ingress-nginx**: HTTP/HTTPS ingress controller
- **MetalLB**: LoadBalancer for bare metal
- **cert-manager**: TLS certificate automation
- **external-dns**: Automatic DNS record management

### Storage
- **Rook-Ceph**: Distributed storage (Block, Filesystem, Object)
- **Zalando PostgreSQL Operator**: PostgreSQL cluster management
- **CloudNative-PG Operator**: Alternative PostgreSQL operator

### Upstream Infrastructure

The Kubernetes cluster is provisioned by the upstream infrastructure repository which handles:
- **Proxmox VM creation** (Terraform)
- **OS configuration** (Ansible with 4 specialized agents)
- **Kubernetes deployment** (Kubespray in Docker)
- **Network segmentation** (VLANs: 106 mgmt, 105 internal, 107 public, 110 storage)

## Project Conventions

### Repository Structure

```
platform/
├── bootstrap/                    # ArgoCD & secret initialization
│   ├── scripts/                  # Automation scripts
│   │   ├── render-secrets.sh     # SecretSpec → SealedSecret renderer
│   │   ├── github-app-token.sh   # GitHub App token generation
│   │   ├── install-argo.sh       # ArgoCD deployment
│   │   └── install-sealed-secrets.sh
│   └── secrets/                  # Secret management
│       ├── specs/                # Declarative SecretSpec definitions
│       ├── chart/                # Helm chart for secret deployment
│       ├── .env.example          # Environment variable template
│       └── .generated/           # Generated manifests (gitignored)
│           ├── sealed/           # SealedSecret manifests
│           ├── push/             # PushSecret manifests (Vault sync)
│           └── state/            # Cached values for idempotency
├── environments/                 # Environment-specific configuration
│   └── development.yaml
├── hooks/                        # ArgoCD sync hooks
│   ├── validation/               # Pre-sync validation hooks
│   ├── health-checks/            # Post-sync health verification
│   └── notifications/            # Failure notification hooks
├── project-chart/                # ArgoCD AppProject governance
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/project.yaml
├── stack-orchestrator/           # Master orchestration chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-production.yaml
│   └── templates/stack-applications.yaml
├── stacks/                       # 12 modular platform stacks
│   ├── infrastructure/
│   ├── storage/
│   ├── security/
│   ├── platform-data/
│   ├── monitoring/
│   ├── data-streaming/
│   ├── developer-platform/
│   ├── development-workloads/
│   ├── application-infra/
│   ├── backup-and-disaster-recovery/
│   └── ml-infra/
├── tenant-clusters/              # Virtual Kubernetes clusters
│   ├── cluster-orchestrator/
│   └── clusters/
├── deploy.sh                     # Deployment engine
├── run.sh                        # Main orchestration entry point
├── validate.sh                   # Validation framework
└── reset.sh                      # Complete reset/cleanup
```

### Stack Structure Pattern

Each stack follows a consistent structure:

```
stacks/{stack-name}/
├── charts/                       # Individual Helm charts
│   └── {component}/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── target-chart/                 # Application factory
│   ├── Chart.yaml
│   ├── values.yaml               # Base configuration
│   ├── values-production.yaml    # Production environment
│   ├── values-staging.yaml
│   ├── values-development.yaml
│   └── templates/
│       ├── application.yaml      # ArgoCD Application generator
│       ├── _helpers.tpl
│       └── dependency-wait-hook.yaml
├── docs/                         # Stack documentation
└── examples/                     # Usage examples
```

### Deployment Pattern: Hierarchical Application Factory

The platform uses a **hierarchical application factory** pattern with three levels:

```
stack-orchestrator (Level 1)
    └─→ generates ArgoCD Applications for each stack
        └─→ stack target-chart (Level 2)
            └─→ generates ArgoCD Applications for each component
                └─→ component charts (Level 3)
                    └─→ deploys actual Kubernetes resources
```

1. **Stack-Orchestrator**: Master chart that deploys all enabled stacks
2. **Stack Target-Charts**: Per-stack charts that deploy stack components
3. **Component Charts**: Individual Helm charts for each service

**Benefits:**
- Modular, independently deployable stacks
- Environment-specific configuration at every level
- Consistent patterns across all stacks
- Easy to add/remove components without affecting other stacks

### Sync Wave Strategy

Applications deploy in ordered waves using ArgoCD sync wave annotations:

```
Wave -200: Storage operators (Rook-Ceph operator)
Wave -100: Storage clusters (Ceph cluster)
Wave  -30: Platform infrastructure (stack-orchestrator)
Wave  -10: Infrastructure stack (MetalLB, Ingress, Cert-Manager)
Wave   -5: Storage prerequisites
Wave    0: Core services (ArgoCD, monitoring base)
Wave    5: Health checks
Wave   10: Data streaming
Wave   20: Platform data (databases, KV stores)
Wave   30: Developer platform
Wave   40: Development workloads
Wave   50: Application infrastructure
Wave   60: Backup and disaster recovery
```

### Secret Management

The platform uses a **declarative secret management** approach:

#### SecretSpec Format
```yaml
apiVersion: platform.pnats.cloud/v1alpha1
kind: SecretSpec
metadata:
  name: my-app-secret
spec:
  namespace: my-app
  type: Opaque
  vault:
    path: secret/applications/my-app
  data:
    username:
      env: MY_APP_USER           # From environment variable
      cache: true
    password:
      generate:
        length: 32
        alphabet: alnum          # alnum, hex, url, base64
      hash:
        method: bcrypt           # bcrypt, sha512, apr1
      cache: true
```

#### Secret Pipeline
1. Define secrets in `bootstrap/secrets/specs/*.yaml`
2. Run `render-secrets.sh` to generate:
   - SealedSecret manifests (encrypted for Kubernetes)
   - PushSecret manifests (synced to Vault)
   - Cached state for idempotency
3. Deploy via Helm chart at `bootstrap/secrets/chart`

### Code Style & Conventions

#### YAML Formatting
- 2-space indentation
- Explicit string quotes for version numbers
- Comments for non-obvious configurations
- Inline comments for values that may need adjustment

#### Helm Values Organization
```yaml
# Global/controller configuration at top
# Resource limits and requests
# Service configuration
# Features and integrations
# Storage and persistence (if applicable)
# Ingress and networking (if applicable)
```

#### GitOps Annotations
- Use sync waves via `argocd.argoproj.io/sync-wave` annotations
- Add `argocd.argoproj.io/compare-options: IgnoreExtraneous` for generated resources
- Use `Replace=false` for resources that shouldn't be replaced (like ArgoCD itself)

### Architecture Patterns

#### Multi-Source Applications

All platform Helm charts use the multi-source pattern:

```yaml
sources:
  - repoURL: https://charts.example.com    # Upstream Helm chart
    chart: my-chart
    targetRevision: 1.2.3
    helm:
      releaseName: my-chart
      valueFiles:
        - $values/platform/stacks/my-stack/charts/my-chart/values.yaml
  - repoURL: https://github.com/ProficientnowTech/pn-infra.git
    targetRevision: v2
    ref: values
```

#### Multi-Cluster Architecture

The platform supports multi-region deployments:

```
On-Prem Cluster (Hyderabad) - Authority/Primary
├── Full platform stack
├── Primary databases with streaming replication
└── Write operations

Cloud Cluster (Contabo) - Edge/Cache
├── Read replicas
├── Caching layer
└── Regional traffic handling

Cloud Cluster (OVH) - Edge/Cache
├── Read replicas
├── Caching layer
└── Regional traffic handling
```

**Inter-cluster connectivity:**
- OVN-IC (Open Virtual Network Interconnect)
- WireGuard mesh for secure tunnels
- Cloudflare for global load balancing

#### Storage Architecture

**Block Storage (RBD)**: `ceph-block` StorageClass
- Use case: Database PVCs, stateful app volumes
- Backend: `replicapool` with 3-way replication

**Filesystem Storage (CephFS)**: `ceph-filesystem` StorageClass
- Use case: Shared ReadWriteMany volumes, logs
- Backend: `cephfs` with replicated metadata + data pools

**Object Storage (S3/Swift)**: `ceph-bucket` StorageClass
- Use case: Backups, media files, application object storage
- Backend: `objectstore` with RGW instances

#### TLS Certificate Management

All external services use automated TLS:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-production
tls:
  - secretName: <service>-tls
    hosts:
      - <service>.pnats.cloud
```

### Deployment Orchestration

#### Entry Points

| Script | Purpose |
|--------|---------|
| `run.sh` | Main orchestration entry point (validate, deploy, reset, status) |
| `validate.sh` | Validates tools, structure, and Helm templates |
| `deploy.sh` | Deployment engine with retry logic |
| `reset.sh` | Cleanup (light mode: apps only, full mode: everything including Ceph) |

#### Deployment Flow

```
run.sh (entry point)
│
├─→ run_validation()
│   └─→ validate.sh
│       ├─ Check tools (helm, kubectl, git, yq, jq)
│       ├─ Verify directory structure
│       ├─ Validate Helm templates for all stacks
│       └─ Check environment configuration
│
└─→ run_deployment()
    └─→ deploy.sh
        ├─ Load environment variables
        ├─ Check cluster connectivity
        ├─ Deploy External Secrets CRDs
        ├─ Configure ArgoCD credentials
        └─ Apply platform root Application
            └─ stack-orchestrator generates stack Applications
                └─ Each stack generates component Applications
                    └─ ArgoCD deploys in sync wave order
```

### ArgoCD Hooks

The platform uses ArgoCD hooks for validation and health checks:

**Pre-Sync Hooks (`hooks/validation/`):**
- Infrastructure validation (ArgoCD API, namespaces, CNI, ingress)
- Storage prerequisites validation

**Post-Sync Hooks (`hooks/health-checks/`):**
- Rook-Ceph cluster health verification
- Monitoring stack health checks

**On-Failure Hooks (`hooks/notifications/`):**
- Automated failure alerting and logging

### Testing Strategy

#### GitOps Validation
- ArgoCD health checks for all applications
- Sync status monitoring
- Pre-sync validation hooks

#### Storage Testing
- PVC creation and mounting tests
- Data persistence across pod restarts

#### Networking Testing
- Ingress connectivity tests
- TLS certificate validation
- DNS record propagation checks

### Git Workflow

#### Branching Strategy
- **main**: Production-deployed branch
- **v2**: Current development branch
- Feature branches for significant changes

#### Commit Conventions

```
fix(component): brief description

- Detailed explanation
- Why this change was needed
- Impact on system

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Commit prefixes:**
- `fix`: Bug fixes, corrections
- `feat`: New features, capabilities
- `chore`: Maintenance, dependencies
- `docs`: Documentation updates
- `refactor`: Code restructuring without behavior change

#### OpenSpec Change Management

For architectural changes, follow the OpenSpec workflow defined in `openspec/AGENTS.md`:

1. **Create proposal**: `openspec/changes/<change-id>/proposal.md`
2. **Plan implementation**: `openspec/changes/<change-id>/tasks.md`
3. **Document design**: `openspec/changes/<change-id>/design.md` (if complex)
4. **Define spec deltas**: `openspec/changes/<change-id>/specs/<capability>/spec.md`
5. **Implement and deploy**
6. **Archive after deployment**: Move to `changes/archive/YYYY-MM-DD-<change-id>/`

## Domain Context

### ATS Platform

This infrastructure supports an **Applicant Tracking System (ATS)** platform with:
- Multi-tenant SaaS architecture
- HR/recruiting workflow automation
- Compliance requirements (data retention, audit logging)
- API-driven integrations with external HR systems

### Operational Context

- **Team size**: Small (1-3 engineers)
- **Deployment cadence**: Frequent (multiple times per day)
- **Uptime requirements**: Production-grade with multi-region failover
- **Geographic scope**: Multi-region (Hyderabad primary, Contabo/OVH edge)
- **Cost optimization**: Critical (startup budget)

## Important Constraints

### Technical Constraints

- **Bare metal primary**: On-prem cluster with cloud edge clusters
- **VLAN-based networking**: 106 mgmt, 105 internal, 107 public, 110 storage
- **Multi-CNI**: Cilium + Kube-OVN for advanced networking
- **IPv4 only**: No IPv6 support configured

### Regulatory & Compliance

- **SOC 2 requirements** (future): 5+ year data retention for user/application data
- **Audit logging**: Comprehensive log retention required
- **Data sovereignty**: Primary data stored on-premise (India)

## External Dependencies

### DNS Provider
- **Provider**: Cloudflare
- **Domain**: `pnats.cloud`
- **Records managed by**: external-dns via Kubernetes Service/Ingress annotations

### Certificate Authority
- **Provider**: Let's Encrypt (production)
- **Challenge type**: HTTP-01 (via ingress-nginx)
- **Auto-renewal**: Managed by cert-manager

### Upstream Helm Repositories

Critical dependencies:
- `https://kubernetes.github.io/ingress-nginx` - ingress-nginx
- `https://charts.jetstack.io` - cert-manager
- `https://argoproj.github.io/argo-helm` - ArgoCD
- `https://charts.rook.io/release` - Rook-Ceph
- `https://kubernetes-sigs.github.io/external-dns/` - external-dns
- `https://grafana.github.io/helm-charts` - Grafana, Loki, Promtail, Tempo
- `https://prometheus-community.github.io/helm-charts` - Prometheus

### Physical Infrastructure

- **Hypervisor**: Proxmox VE
- **Network**: Sophos firewall, VLANs, BGP for MetalLB
- **Storage**: Distributed Ceph across nodes

## Quick Reference

### Get Cluster Status
```bash
kubectl get nodes
kubectl get applications -n argocd
kubectl get cephcluster -n rook-ceph
```

### Check Storage
```bash
kubectl get sc                              # StorageClasses
kubectl get pvc --all-namespaces            # Persistent Volume Claims
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph status
```

### Platform Operations
```bash
# Validate platform configuration
./platform/run.sh validate

# Deploy platform
./platform/run.sh deploy

# Check status
./platform/run.sh status

# Reset (light - apps only)
./platform/run.sh reset

# Reset (full - including storage)
./platform/run.sh reset --full
```

### Access Services
- **ArgoCD**: https://argocd.pnats.cloud
- **Grafana**: https://grafana.pnats.cloud
- **Keycloak**: https://keycloak.pnats.cloud
- **Harbor**: https://harbor.pnats.cloud

### Emergency Procedures

**ArgoCD out of sync:**
```bash
kubectl patch application <app> -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type=merge
```

**Rook-Ceph stuck resources:**
```bash
kubectl patch <resource> <name> -n rook-ceph \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

**Certificate renewal issues:**
```bash
kubectl describe certificate <cert-name> -n <namespace>
kubectl describe challenge --all-namespaces
```

**Force sync all applications:**
```bash
argocd app sync --all --force
```
