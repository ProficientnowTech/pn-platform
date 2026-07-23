```
RFC-CICD-0001                                                   Section 5
Category: Standards Track                                      Rationale
```

# 5. Rationale

[<-- Components](./04-components.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution -->](./06-evolution.md)

---

## 5.1 Workspace Strategy

### 5.1.1 CephFS Shared PVC

**Description**: Use a CephFS-backed PersistentVolumeClaim shared across all pipeline steps running as separate pods. Each step mounts the same PVC and operates on a shared filesystem.

**Why It Was Attractive**:

- Familiar Kubernetes-native storage model requiring no special tooling
- All steps see the same filesystem, simplifying data sharing between pods
- No artifact passing overhead between steps

**Why It Was Rejected**:

- The CephFS Metadata Server (MDS) is a single point of serialization for metadata-heavy operations
- `git clone` and `node_modules` resolution generate thousands of small-file metadata operations that saturate the MDS
- Observed git clone times exceeded ten minutes on CephFS, compared to seconds on local storage
- Pipeline duration became dominated by storage latency rather than build computation
- Violates Invariant 3 (Workspace Idempotency) in practice because residual files from previous PVC usage can influence subsequent runs unless explicit cleanup is performed

**Conclusion**: CephFS cannot sustain the I/O patterns of monorepo CI without architectural changes to Ceph (multiple active MDS, which introduces its own operational complexity). ContainerSet with emptyDir eliminates the storage bottleneck entirely by using node-local storage.

---

## 5.2 Rejected Pipeline Platforms

### 5.2.1 GitHub Actions

**Description**: Use GitHub Actions as the CI execution platform, with workflows defined in the repository's `.github/workflows/` directory.

**Why It Was Attractive**:

- Native integration with GitHub pull requests and status checks
- Large ecosystem of reusable actions
- No in-cluster CI infrastructure to operate
- Familiar to developers with prior GitHub experience

**Why It Was Rejected**:

- GitHub Actions runners execute outside the cluster and cannot reach in-cluster services (Harbor, Verdaccio, Ceph RGW S3) without exposing them to the public internet
- Exposing Harbor and Verdaccio externally increases the attack surface and requires additional network security infrastructure
- Self-hosted runners inside the cluster are possible but negate the simplicity benefit and introduce their own operational burden
- The Nx S3 remote cache targets Ceph RGW, which is accessible only within the cluster network
- Violates the design goal of unified in-cluster execution (Section 2.2.1)

**Conclusion**: The platform's dependency on in-cluster services makes external CI execution impractical without significant security trade-offs. Running CI within the cluster where it can natively access all required services is the coherent architectural choice.

### 5.2.2 Tekton Pipelines

**Description**: Use Tekton Pipelines as the CI execution engine, with Tekton Triggers for webhook ingestion and Tekton Tasks for individual build steps.

**Why It Was Attractive**:

- Kubernetes-native pipeline execution with CRD-based definitions
- Strong isolation between pipeline steps (each step runs in its own container)
- Active CNCF project with broad community adoption
- Existing organizational familiarity from prior evaluation

**Why It Was Rejected**:

- Tekton Pipelines lack native support for dynamic DAG generation at runtime; pipeline structure must be defined statically or through complex custom controllers
- The Nx project graph produces a variable set of tasks and dependency edges per changeset; expressing this as a Tekton Pipeline requires generating the Pipeline manifest externally and submitting it, which Argo Workflows supports natively through the Workflow-of-Workflows pattern
- Argo Workflows provides a richer UI for observing DAG execution, including real-time task status and log streaming
- Argo Events and Argo Workflows share a unified ecosystem, simplifying operational concerns (single set of CRDs, consistent API patterns, shared documentation)
- A formal evaluation through adversarial debate (documented separately) concluded that Argo Workflows better serves the dynamic DAG requirement
- No specific invariant violation; Tekton could technically satisfy the requirements but with greater operational complexity

**Conclusion**: Argo Workflows' native dynamic DAG generation aligns with the architecture's core requirement of translating the Nx task graph into execution plans at runtime. The unified Argo ecosystem reduces operational surface area compared to mixing Tekton with a separate event system.

---

## 5.3 Rejected Execution Models

### 5.3.1 withParam Fan-Out Instead of Workflow-of-Workflows

**Description**: Use Argo Workflows' `withParam` construct to fan out tasks based on a JSON list of affected projects, where each item in the list spawns an independent task pod.

**Why It Was Attractive**:

- Simpler workflow definition: a single template with `withParam` iteration
- No child workflow generation step required
- Native Argo feature with straightforward semantics
- Lower conceptual overhead for developers reading workflow definitions

**Why It Was Rejected**:

- `withParam` creates independent task instances with no inter-task dependency edges; all fanned-out tasks execute concurrently with no ordering guarantees
- The Nx project graph contains dependency edges between tasks (e.g., library build must complete before dependent service build); `withParam` cannot express these edges
- Workarounds such as serial execution within groups or multi-phase `withParam` fans do not faithfully represent the arbitrary DAG structure of the Nx task graph
- Violates Invariant 1 (Nx Graph Authority): the `withParam` model would require the CI system to flatten the dependency graph into ordered groups, introducing CI-specific ordering logic that duplicates and potentially contradicts Nx's dependency analysis

**Conclusion**: The Nx task graph is an arbitrary DAG, not a flat list. Only Argo's DAG task type, generated dynamically as a child workflow, can faithfully represent the dependency edges that Nx produces.

### 5.3.2 Single Monolithic Workflow

**Description**: Define a single large Argo Workflow that statically includes all possible pipeline steps for all services, with conditional execution based on changed files.

**Why It Was Attractive**:

- Single workflow definition to maintain
- No dynamic generation step
- All pipeline logic visible in one place

**Why It Was Rejected**:

- The workflow definition would need to enumerate all 22 projects and their dependency relationships statically
- Adding or removing a service requires modifying the workflow definition
- Conditional execution of static nodes does not scale: the workflow manifest grows linearly with the project count and quadratically with dependency edges
- Violates Invariant 1 (Nx Graph Authority): change detection and ordering logic would be duplicated in workflow conditionals rather than delegated to Nx

**Conclusion**: A static workflow cannot keep pace with a monorepo whose project graph evolves with every structural change. Dynamic generation from the Nx task graph ensures the pipeline always reflects the actual codebase structure.

---

## 5.4 Rejected Cache Strategies

### 5.4.1 Nx Cloud Instead of Self-Hosted S3 Cache

**Description**: Use Nx Cloud, the managed remote caching service provided by Nrwl, instead of self-hosting an S3-compatible cache backed by Ceph RGW.

**Why It Was Attractive**:

- Managed service with no operational burden for cache storage
- Includes distributed task execution capabilities beyond simple caching
- Official Nx integration with minimal configuration
- Cache analytics and insights provided by the service

**Why It Was Rejected**:

- CI workflows execute within the cluster; routing cache traffic to an external service introduces latency and external network dependency
- Organizational preference for self-hosted infrastructure to maintain control over data residency and availability
- Ceph RGW S3 is already operational within the cluster for other storage needs; reusing it for Nx cache adds no new infrastructure component
- External cache service is a single point of failure outside the organization's control
- CREEP vulnerability exists with any shared cache, but self-hosted infrastructure allows the read-only restriction for PR branches to be enforced at the S3 bucket policy level without depending on third-party access controls

**Conclusion**: Self-hosted S3 cache on existing Ceph RGW infrastructure provides equivalent caching functionality without introducing external dependencies or data residency concerns. The CREEP mitigation via bucket-level read-only policies is more directly enforceable on self-hosted infrastructure.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [<-- 4. Components](./04-components.md) | [Table of Contents](./00-index.md#table-of-contents) | [6. Evolution -->](./06-evolution.md) |

---

*End of Section 5 -- RFC-CICD-0001*
