```
RFC-CICD-0001                                                   Section 2
Category: Standards Track                                   Requirements
```

# 2. Requirements

[<-- Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture -->](./03-architecture.md)

---

## 2.1 Problem Restatement

The pnow-ats-v2 monorepo requires an automated CI/CD pipeline that can:

- Detect which projects are affected by a given changeset
- Compute the correct build order respecting inter-project dependencies
- Execute affected tasks in parallel where dependencies allow
- Build Docker images only for affected services
- Publish shared libraries before dependent Docker builds consume them
- Deliver image tags to the cluster through GitOps without direct state mutation
- Share build caches across CI runs to avoid redundant computation

The solution MUST operate entirely within the bare-metal Kubernetes cluster to access in-cluster services (Harbor, Verdaccio, Ceph S3) without exposing them externally.

---

## 2.2 Design Goals

### 2.2.1 Unified CI/CD on Argo Workflows

All build, validation, and delivery tasks execute on Argo Workflows within the cluster. No external CI service (including GitHub Actions) participates in build or test execution. GitHub serves only as the source code host and webhook origin.

### 2.2.2 Nx-Driven Change Detection

The Nx `affected` command determines which projects require action for a given changeset. The CI system does not maintain its own change-detection logic. All affected-project computation is delegated to Nx.

### 2.2.3 Shared Remote Cache

Nx task results are cached in S3-compatible object storage (Ceph RGW) and shared across CI runs. Subsequent runs that encounter unchanged inputs reuse cached outputs, reducing pipeline duration to a function of changeset size rather than total project count.

### 2.2.4 Parallel Execution via Project Graph

The Nx project graph defines the maximum parallelism available for a given set of affected tasks. The CI system translates this graph into an Argo Workflow DAG that preserves dependency edges while scheduling independent tasks concurrently.

### 2.2.5 Selective Docker Builds

Docker images are built only for services that are affected by the changeset. A change to a shared library triggers Docker builds for all services that depend on that library, but services with no transitive dependency on the changed code are not rebuilt.

### 2.2.6 GitOps Deployment Model

After Docker images are built and pushed to Harbor, the CI pipeline commits the new image tags to the infrastructure repository. ArgoCD detects the commit and reconciles the cluster state. The CI pipeline itself does not interact with the Kubernetes API to modify workloads.

### 2.2.7 Shared Library Publishing

Shared libraries under the `@pnats` scope are built and published to Verdaccio before any Docker build begins. The `workspace:*` version specifiers in package manifests are rewritten to concrete versions that Verdaccio can resolve. This ensures Docker builds can install dependencies without access to the monorepo workspace.

---

## 2.3 Non-Goals

### 2.3.1 Application Testing Strategy

This architecture does NOT define which tests are run, how they are structured, or what coverage targets are enforced. Testing strategy is an application-level concern. The CI pipeline executes whatever Nx targets are configured for affected projects; the choice of targets is outside this RFC's scope.

### 2.3.2 Production Promotion and Gating

This architecture does NOT define how deployments are promoted between environments or what approval gates govern production releases. The pipeline delivers image tags to the infrastructure repository; subsequent promotion workflows are a deployment operations concern.

### 2.3.3 Event Gateway and Security Sensors

This architecture does NOT define how webhook endpoints are protected at the network layer, how event payloads are validated beyond Argo Events' native capabilities, or how security monitoring integrates with the CI pipeline.

### 2.3.4 Python Service CI

The 11 Python services that operate outside Nx management are NOT covered by this architecture. These services do not participate in the Nx project graph and require a separate CI strategy.

---

## 2.4 Architectural Invariants

### Invariant 1 -- Nx Graph Authority

The Nx project graph MUST be the sole authority for change detection and build ordering within the CI pipeline.

The CI system MUST NOT maintain independent logic for determining which projects are affected by a changeset or in what order they should be built. All such decisions are derived from Nx commands operating on the project graph. This invariant ensures that CI ordering is always consistent with the actual dependency relationships declared in the codebase. Violation would create divergence between local developer experience and CI behavior, producing builds that succeed locally but fail in CI or vice versa.

### Invariant 2 -- GitOps-Only Deployment

The CI pipeline MUST NOT mutate cluster state directly. All deployment changes MUST flow through Git commits to the infrastructure repository, where ArgoCD reconciles the desired state.

Direct cluster mutation from CI would bypass the audit trail, peer review, and rollback mechanisms that GitOps provides. Violation would create deployments that cannot be traced to a specific Git commit and cannot be rolled back through Git revert.

### Invariant 3 -- Workspace Idempotency

The CI workspace MUST be idempotent. Repeated execution of a pipeline against the same commit MUST produce identical artifacts without requiring manual cleanup of prior state.

Each pipeline run operates in an ephemeral workspace (emptyDir volume) that is created fresh and destroyed on completion. No persistent state from previous runs influences the current execution. Violation would introduce non-deterministic builds that depend on residual filesystem state.

### Invariant 4 -- Vault Secret Authority

All secrets consumed by CI workflows MUST be sourced from HashiCorp Vault via ExternalSecrets Operator.

The CI system MUST NOT embed credentials in workflow definitions, environment variables outside the ExternalSecrets chain, or any storage mechanism that bypasses Vault's access control and audit logging. Violation would create unaudited credential access paths.

### Invariant 5 -- Independent Failure Isolation

A failure in one service's build MUST NOT prevent independent services from completing their builds.

When the Argo Workflow DAG contains tasks with no dependency relationship, a failure in one task MUST NOT halt execution of the other. Only tasks that depend on a failed task (directly or transitively) are prevented from executing. Violation would cause a single flaky build to block delivery of all services in a changeset.

---

## 2.5 Success Criteria

| Criterion | Metric | Target |
|-----------|--------|--------|
| Change detection accuracy | Affected services match actual dependency graph | 100% agreement with Nx output |
| Build ordering correctness | No service builds before its dependencies | Zero ordering violations |
| Cache hit rate for unchanged projects | Nx cache hits on unmodified projects | Cache hit on all unmodified projects |
| Failure isolation | Independent service builds complete despite sibling failures | Zero collateral failures |
| Deployment traceability | Every deployed image traceable to a Git commit in both repositories | 100% traceability |
| Workspace cleanliness | No residual state between pipeline runs | Zero persistent artifacts |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [<-- 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture -->](./03-architecture.md) |

---

*End of Section 2 -- RFC-CICD-0001*
