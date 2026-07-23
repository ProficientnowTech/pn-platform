## Context

RFC-PLATARCH-0001 was created by consolidating preliminary RFC documents (P1-P4). During review, terminology confusion was identified: "Platform Applications" was interpreted as tenant business workloads, but the platform/ directory actually contains platform services (Keycloak, Vault, etc.) that serve tenants.

The RFC's capability-based orchestration model is sound and should be preserved. The revision focuses on correcting terminology, clarifying categorization, and ensuring the RFC remains an informative design document rather than an implementation specification.

### Stakeholders

- Platform team: Owns the RFC and implementation
- Tenant application developers: Consume platform capabilities
- Security/compliance: Validates governance model

### Constraints

- Preserve the existing capability-based DAG model
- RFC is informative/design, NOT implementation specification
- No phases, layers, or hierarchical deployment ordering
- Categories must provide clear binary decision for base chart usage

## Goals / Non-Goals

### Goals

1. Correct terminology confusion around "Platform Applications"
2. Define binary categorization: Infrastructure Providers vs Platform Consumers
3. Clarify DAG-based dependency resolution model
4. Establish base chart boundary with clear inclusion/exclusion criteria
5. Ensure RFC scope remains informative/design

### Non-Goals

- Specifying implementation details (deferred to RFC-DEPLOY-0001)
- Defining deployment ordering or phases
- Prescribing specific orchestration mechanisms
- Changing the fundamental capability model

## Decisions

### Decision 1: Binary Component Categorization

**What**: Define two primary categories that determine base chart usage.

**Categories**:

| Category | Uses Base Chart | Definition |
|----------|-----------------|------------|
| **Infrastructure Provider** | NO | Components that PROVIDE capabilities consumed by base chart templates |
| **Platform Consumer** | YES | Components that CONSUME capabilities provided by Infrastructure Providers |

**Infrastructure Providers** (DO NOT use base chart):

| Component | Provides | Why No Base Chart |
|-----------|----------|-------------------|
| cert-manager | TLS certificates | Base chart may have Certificate templates |
| Crossplane | XRDs, Compositions, Claims | Base chart has Crossplane resource templates |
| Vault | Secret storage | Base chart has ExternalSecret templates |
| External Secrets Operator | Secret sync | Base chart has ExternalSecret templates |
| Keycloak | OIDC authentication | Base chart has Keycloak client templates |
| Zalando PostgreSQL Operator | PostgreSQL clusters | Base chart has PostgreSQL claim templates |
| Strimzi | Kafka clusters | Base chart has Kafka topic templates |
| CloudNative-PG | PostgreSQL clusters | Base chart has PostgreSQL claim templates |
| Rook-Ceph | Storage classes | Base chart may have PVC templates |
| MetalLB | LoadBalancer IPs | Foundational, no consumer dependencies |
| ingress-nginx | Ingress routing | Foundational, no consumer dependencies |
| External-DNS | DNS records | Foundational, no consumer dependencies |
| ArgoCD | GitOps deployment | Foundational, deploys everything else |

**Platform Consumers** (MUST use base chart):

| Component | Consumes | Why Base Chart Required |
|-----------|----------|------------------------|
| Backstage | Keycloak OIDC, PostgreSQL, secrets | Needs all platform integrations |
| Harbor | Keycloak OIDC, storage, secrets | Needs all platform integrations |
| Grafana | Keycloak OIDC, secrets | Needs SSO and secret injection |
| Loki | Storage, secrets | Needs storage and credentials |
| Tempo | Storage, secrets | Needs storage and credentials |
| PostgreSQL instances | Zalando operator | Created via base chart templates |
| Kafka clusters | Strimzi operator | Created via base chart templates |
| Tenant applications | All of the above | Full platform integration |

**Decision Criteria** (binary test):
```
Does this component PROVIDE a capability that base chart templates consume?
├── YES → Infrastructure Provider (no base chart)
└── NO  → Platform Consumer (must use base chart)
```

**Why**:
- Eliminates circular dependency: base chart templates depend on Infrastructure Providers
- If Infrastructure Providers used base chart → circular dependency
- Clear binary decision removes ambiguity

### Decision 2: DAG-Based Capability Resolution

**What**: Clarify that capability-based orchestration uses Directed Acyclic Graph (DAG) resolution, not sequential phases.

**Model**:

```
Component A                    Component B
├── provides: [cap-x]          ├── provides: [cap-y]
└── requires: []               └── requires: [cap-x]

Component C
├── provides: [cap-z]
└── requires: [cap-x, cap-y]
```

Dependency graph (DAG):
```
A ──provides cap-x──► B ──provides cap-y──► C
                      │                     ▲
                      └─────────────────────┘
                        (C also requires cap-x)
```

**DAG Properties**:
- **Directed**: Dependencies flow from provider to consumer
- **Acyclic**: Circular dependencies are invalid and MUST be rejected at declaration time

**Resolution Rules**:
1. A component deploys when ALL its required capabilities are satisfied
2. A capability is satisfied when its provider is ready
3. Components with no requirements can deploy immediately
4. Components with satisfied requirements can deploy concurrently
5. No global ordering—purely local dependency satisfaction
6. Cycles MUST be detected and rejected before deployment begins

**Why**: DAG-based resolution:
- Maximizes parallelism (no waiting for "phases" to complete)
- Is deterministic (same graph = same eventual state)
- Is resilient (failed components don't block unrelated components)
- Matches the natural structure of capability dependencies

**What the RFC should describe**:
- The model: capabilities, providers, consumers, contracts
- The invariants: satisfaction before deployment, single provider per capability
- The properties: determinism, idempotency, eventual consistency

**What the RFC should NOT describe**:
- Specific orchestration implementation (deferred to RFC-DEPLOY-0001)
- Polling intervals, retry logic, health check mechanisms
- Specific tools or technologies for orchestration

### Decision 3: Base Chart as Library Chart

**What**: Define the canonical base chart as a Helm library chart for Platform Consumers only.

**Scope**: Base chart is used by Platform Consumers, NOT Infrastructure Providers.

**Base Chart Provides**:

| Template Category | Templates | Consumes Capability From |
|-------------------|-----------|--------------------------|
| **Secrets** | ExternalSecret, SecretStore ref | Vault, ESO |
| **Identity** | Keycloak client, OIDC config | Keycloak |
| **Database** | PostgreSQL claim, pooler config | Zalando Operator |
| **Messaging** | Kafka topic, user | Strimzi |
| **Storage** | PVC with storage class | Rook-Ceph |
| **Certificates** | Certificate, Issuer ref | cert-manager |
| **Infrastructure** | Crossplane XR claims | Crossplane |
| **Observability** | ServiceMonitor, PrometheusRule | Prometheus Operator |
| **Networking** | NetworkPolicy, Ingress | ingress-nginx, Cilium |
| **Common** | RBAC, PDB, HPA, labels, annotations | - |

**Why Infrastructure Providers Cannot Use Base Chart**:

```
If Keycloak used base chart:
  base-chart/templates/keycloak-client.yaml depends on → Keycloak
  Keycloak uses base-chart → Keycloak depends on → base-chart
  CYCLE: Keycloak → base-chart → Keycloak
```

**Wrapper Chart Pattern** (for Platform Consumers):

```yaml
# platform/stacks/developer-platform/charts/backstage/Chart.yaml
dependencies:
  - name: backstage
    version: "x.y.z"
    repository: "https://backstage.github.io/charts"
  - name: platform-base
    version: "1.x"
    repository: "file://../../../lib/platform-base"
```

Wrapper chart adds via base chart templates:
- ExternalSecret for Backstage credentials
- Keycloak client for SSO
- PostgreSQL claim for Backstage database
- NetworkPolicy for namespace isolation

### Decision 4: Terminology Corrections

**What**: Rename and clarify terms to eliminate confusion.

| Old Term | New Term | Reason |
|----------|----------|--------|
| Platform Application | Platform Consumer | Clarifies these consume platform capabilities |
| (implicit) | Infrastructure Provider | Explicit category for capability providers |
| (implicit) | Tenant Application | Subset of Platform Consumer owned by tenants |
| Layer | Category | Categories don't imply ordering |
| Phase | (removed) | No phases in the model |

### Decision 5: RFC Scope as Informative Design

**What**: Ensure RFC-PLATARCH-0001 remains an informative design RFC.

**In Scope** (this RFC):
- Architecture model and concepts
- Binary categorization and decision criteria
- Capability model: providers, consumers, contracts, satisfaction
- Base chart scope and boundaries (conceptual)
- Governance principles: ownership, isolation, lifecycle

**Out of Scope** (other RFCs):
- Orchestration implementation → RFC-DEPLOY-0001
- Base chart implementation (labels, templates, enforcement) → Future RFC
- Secret lifecycle → RFC-SECOPS-0001
- Human authentication → RFC-IAM-0001
- Service identity → RFC-WORKLOAD-IDENTITY-0001
- Network security → RFC-TENANT-SECURITY-0001
- Privileged access → RFC-PAM-0001
- Developer portal → RFC-DEVELOPER-PLATFORM-0001

## Risks / Trade-offs

### Risk 1: Misclassification
- **Risk**: Component incorrectly classified as Platform Consumer when it's an Infrastructure Provider
- **Mitigation**: Binary test is clear: "Does base chart depend on this component's capability?" If yes → Infrastructure Provider

### Risk 2: Base Chart Scope Creep
- **Risk**: Base chart templates grow to include capabilities not yet provided
- **Mitigation**: Base chart templates MUST only consume capabilities from existing Infrastructure Providers

## Migration Plan

### Step 1: Terminology Updates
1. Replace "Platform Application" with appropriate category term
2. Add "Infrastructure Provider" and "Platform Consumer" definitions
3. Remove any "phase" or "layer" terminology implying order

### Step 2: Binary Categorization
1. Document the binary decision criteria
2. List all current components with their category
3. Validate no circular dependencies exist

### Step 3: Base Chart Boundary
1. Document which components are Infrastructure Providers
2. Document which components MUST use base chart
3. Add rationale for each classification

### Rollback

RFC changes are documentation-only. Rollback via git revert if issues discovered.

## Open Questions

1. **Sub-categories**: Should Infrastructure Providers have sub-categories (operators vs services)?
   - Recommendation: Optional label, not required for binary decision

2. **Tenant infrastructure ownership**: When tenant provisions a database via base chart claim, who owns it?
   - Recommendation: Tenant owns the claim; platform owns the operator

3. **New capability addition**: When adding new Infrastructure Provider, how to update base chart?
   - Recommendation: Add templates to base chart AFTER provider is deployed and stable
