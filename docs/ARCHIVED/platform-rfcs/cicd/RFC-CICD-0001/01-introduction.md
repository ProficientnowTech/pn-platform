```
RFC-CICD-0001                                                   Section 1
Category: Standards Track                                   Introduction
```

# 1. Introduction

[<-- Index](./00-index.md) | [Index](./00-index.md#table-of-contents) | [Next: Requirements -->](./02-requirements.md)

---

## 1.1 Background and Context

### 1.1.1 Scope of This RFC

This RFC addresses the architecture of continuous integration and continuous delivery pipelines for the pnow-ats-v2 monorepo. When a developer opens a pull request or merges code to the main branch, this RFC governs how changes are detected, validated, built into container images, and delivered to the cluster through GitOps.

This RFC does **not** address:

- How applications are tested (unit, integration, or end-to-end testing strategy)
- How production deployments are promoted or gated
- How webhook endpoints are secured at the network layer
- How Python services outside Nx management are built or deployed

These concerns represent distinct architectural challenges addressed by separate specifications or operational documentation.

### 1.1.2 The Monorepo CI Challenge

Large-scale monorepo CI presents a coordination problem that grows with the number of projects and their interdependencies. The pnow-ats-v2 repository contains 22 Nx-managed TypeScript projects: 7 NestJS backend services, 1 Next.js frontend application, 8 shared libraries (7 of which are published to an in-cluster Verdaccio registry as scoped packages), and additional supporting projects. Each backend service and the frontend produce a Docker image from one of 22 Dockerfiles. Shared libraries carry transitive dependency relationships that constrain build ordering.

The architectural challenge is not merely running builds in parallel. It is determining which projects are affected by a given changeset, computing the correct build order that respects inter-project dependencies, and executing only the necessary work while maintaining correctness guarantees. A naive approach that rebuilds everything on every change wastes compute resources and extends feedback cycles. A careless optimization that skips dependencies produces broken images.

### 1.1.3 The Infrastructure Context

The platform operates on bare-metal Kubernetes across 12 nodes. Storage is provided by Rook-Ceph. The container registry is an in-cluster Harbor instance. The npm package registry is an in-cluster Verdaccio instance serving scoped packages under the `@pnats` namespace. Secret management is centralized in HashiCorp Vault with distribution through External Secrets Operator. The deployment model follows GitOps through ArgoCD, which reconciles cluster state from a separate infrastructure repository (pn-infra).

This infrastructure context constrains CI architectural choices in ways that differ from cloud-hosted environments. The CI system MUST operate entirely within the cluster to reach internal services such as Harbor, Verdaccio, and Ceph-backed S3 storage. External CI services cannot access these resources without exposing them to the public internet.

---

## 1.2 Current State Analysis

### 1.2.1 Absence of Unified CI

The repository lacks a production CI/CD pipeline integrated with the monorepo's dependency graph. Previous iterations explored GitHub Actions and Tekton Pipelines, but neither progressed to a stable, production-ready state. As a result, builds and deployments involve manual intervention or ad-hoc scripts that do not account for inter-project dependencies.

### 1.2.2 Nx Without CI Integration

Nx manages the TypeScript project graph and provides local development capabilities including task caching and affected-project detection. However, the CI environment does not leverage these capabilities. The `nx affected` command, which identifies projects impacted by a changeset, is not integrated into any automated pipeline. Local Nx caches are not shared across CI runs, meaning every pipeline execution pays the full cost of all computations.

### 1.2.3 Storage Bottleneck

Early CI prototypes used CephFS shared volumes (PersistentVolumeClaims backed by the CephFS CSI driver) to share workspace data between pipeline steps running as separate pods. The single Ceph Metadata Server became a bottleneck under the I/O patterns characteristic of `git clone` and `node_modules` resolution. Operations that complete in seconds on local storage regularly exceeded ten minutes on CephFS, rendering the pipeline impractical.

### 1.2.4 Shared Library Publishing Gap

Shared libraries under the `@pnats` scope carry `workspace:*` version specifiers during development. These specifiers enable Nx and pnpm to resolve packages from the local workspace. However, Docker builds execute outside the monorepo workspace context. A Docker build that encounters a `workspace:*` dependency in a lock file cannot resolve it because the workspace protocol is meaningless inside an isolated build container. The current state lacks an automated mechanism to publish shared libraries to Verdaccio and rewrite workspace references before Docker image construction.

---

## 1.3 Operational Challenges

### 1.3.1 The Fan-Out Coordination Problem

When a merge to main affects multiple services, their Docker images must be built in parallel to minimize total pipeline duration. However, each service may depend on shared libraries that must be built and published first. The coordination challenge is twofold: shared libraries must complete before any dependent Docker build begins, and independent Docker builds must proceed in parallel to avoid serializing work that has no ordering constraint.

Existing ad-hoc approaches either serialize all builds (correct but slow) or parallelize naively (fast but risk consuming stale library versions).

### 1.3.2 Cache Invalidation Across Runs

Without a shared remote cache, every CI run recomputes all Nx tasks from scratch. In a monorepo with 22 projects, this means linting, type-checking, and building projects that have not changed since the last run. The absence of cross-run caching transforms a potentially incremental operation into a full rebuild, extending pipeline duration in proportion to the total project count rather than the changeset size.

### 1.3.3 Deployment Coordination

After Docker images are built and pushed, the corresponding image tags must be committed to the infrastructure repository so that ArgoCD detects the change and reconciles the deployment. This step must occur atomically for a given pipeline run: either all image tags from a single merge are committed, or none are. Partial updates would create inconsistent deployments where some services reflect the new code while others remain on the previous version.

### 1.3.4 Failure Isolation

A build failure in one service should not prevent independent services from completing their builds. If Service A and Service B share no dependencies and Service A's Docker build fails, Service B's image should still be built, pushed, and delivered. The current absence of structured pipelines means that any failure typically halts all subsequent work.

---

## 1.4 Motivation for This Architecture

### 1.4.1 Nx as the Single Source of Build Truth

The Nx project graph already encodes the complete dependency structure of the monorepo. Rather than duplicating this knowledge in pipeline configuration, this architecture delegates all change-detection and ordering decisions to Nx. The CI system consumes the Nx task graph and translates it into execution plans. This approach ensures that CI ordering is always consistent with the actual dependency relationships in the codebase.

### 1.4.2 Argo Workflows for Dynamic DAG Execution

Argo Workflows provides the capability to generate workflow DAGs at runtime. This is essential because the set of affected projects varies with every changeset. A static pipeline definition cannot express conditional execution based on a dynamic dependency graph. Argo Workflows enables a pattern where an initial step analyzes the changeset, generates an Argo Workflow manifest representing only the affected tasks, and submits it for execution. The Argo controller then schedules tasks in dependency order with maximum parallelism.

### 1.4.3 Eliminating CephFS from the Critical Path

This architecture replaces CephFS-backed shared volumes with two mechanisms: ContainerSet pods with emptyDir volumes for sequential steps that share a filesystem, and S3 artifact passing for data transfer between independent pods. The ContainerSet approach places sequential steps (clone, install, build) in a single pod where they share an emptyDir volume backed by local storage. The S3 artifact approach transfers build context to Kaniko pods through Ceph RGW object storage, which does not suffer from the metadata server bottleneck that affects CephFS.

### 1.4.4 GitOps-Only Deployment

The CI pipeline MUST NOT mutate cluster state directly. All deployment changes flow through Git commits to the infrastructure repository, where ArgoCD detects changes and reconciles the cluster. This model preserves the auditability and rollback capabilities of GitOps while ensuring that CI pipelines cannot bypass the deployment review process.

### 1.4.5 Unified In-Cluster Execution

By running all CI workloads within the cluster, the architecture eliminates the need to expose internal services (Harbor, Verdaccio, Ceph S3) to external networks. The CI system authenticates to these services using in-cluster credentials managed through Vault and ExternalSecrets. This unification reduces the attack surface and simplifies network policy management.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [<-- Index](./00-index.md) | [Table of Contents](./00-index.md#table-of-contents) | [2. Requirements -->](./02-requirements.md) |

---

*End of Section 1 -- RFC-CICD-0001*
