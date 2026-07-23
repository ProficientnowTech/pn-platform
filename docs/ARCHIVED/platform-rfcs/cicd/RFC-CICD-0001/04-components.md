```
RFC-CICD-0001                                                   Section 4
Category: Standards Track                                     Components
```

# 4. Components

[<-- Architecture](./03-architecture.md) | [Index](./00-index.md#table-of-contents) | [Next: Rationale -->](./05-rationale.md)

---

## 4.1 Argo Events Layer

### 4.1.1 EventBus

The EventBus provides durable message transport between EventSources and Sensors using NATS JetStream.

| Aspect | Description |
|--------|-------------|
| Responsibility | Durable, ordered delivery of events from EventSources to Sensors |
| Technology | NATS JetStream (deployed as the Argo Events EventBus) |
| Durability | Messages persist until acknowledged by all subscribed Sensors |
| Failure mode | If the EventBus is unavailable, events queue at the EventSource and are delivered when connectivity resumes |
| Recovery | NATS JetStream replays unacknowledged messages after pod restart |

### 4.1.2 EventSource

The EventSource receives GitHub webhook payloads and normalizes them into the Argo Events event format.

| Aspect | Description |
|--------|-------------|
| Responsibility | Receive GitHub webhooks, validate HMAC signatures, emit normalized events |
| Inbound interface | HTTPS endpoint exposed via Kubernetes Service |
| Outbound interface | Events published to the EventBus |
| Authentication | Webhook secret (HMAC-SHA256) sourced from Vault |
| Failure mode | Invalid HMAC signatures are rejected; malformed payloads are dropped |
| Recovery | Stateless; pod restart resumes listening without data loss |

### 4.1.3 Sensor

The Sensor evaluates event payloads against filter criteria and triggers workflow submissions.

| Aspect | Description |
|--------|-------------|
| Responsibility | Filter events by type (PR vs. push), branch, and action; submit parameterized workflows |
| Inbound interface | Events from EventBus matching subscription filters |
| Outbound interface | Workflow submission to Argo Workflows API |
| Event discrimination | PR events trigger the PR validation template; push events to main trigger the post-merge template |
| Failure mode | If workflow submission fails, the Sensor retries with backoff |
| Recovery | Unprocessed events remain in the EventBus until the Sensor acknowledges them |

---

## 4.2 Argo Workflows Engine

### 4.2.1 WorkflowTemplates

The system defines two primary WorkflowTemplates corresponding to the two pipeline flows described in Section 3.

| Template | Trigger | Purpose |
|----------|---------|---------|
| PR Validation | Pull request open/synchronize | Lint, test, and build affected projects without producing deployable artifacts |
| Post-Merge Build | Push to main branch | Build shared libraries, publish to Verdaccio, build Docker images, deliver via GitOps |

Both templates begin with a ContainerSet pod that performs workspace preparation (fetch/clone directly from GitHub via HTTPS + PAT, install dependencies, generate the DAG). The ContainerSet mounts a RWO block storage PVC that retains the git working tree, pnpm store, and Nx local cache between runs. A mutex ensures only one workflow accesses the PVC at a time. This approach eliminates cross-pod data transfer for the preparation phase while providing warm-start performance from persistent caches. Warm-start git fetches from GitHub complete in seconds (only delta refs are transferred).

### 4.2.2 ContainerSet Execution Model

| Aspect | Description |
|--------|-------------|
| Responsibility | Execute sequential workspace preparation steps within a single pod |
| Storage | RWO block storage PVC (StorageClass: app-blk-hdd-repl) for the workspace, retaining git clone, pnpm store, and Nx local cache between runs. Not CephFS -- block storage provides consistent I/O without metadata server overhead |
| Concurrency | A mutex ensures only one workflow mounts the PVC at a time. Subsequent workflows queue until the mutex is released |
| Warm start | When the PVC already contains data from a previous run, git fetch from GitHub completes in seconds (only delta refs) and pnpm install reuses the cached store via hard links on the same block filesystem |
| Cold start | On a fresh PVC, a full clone from GitHub is required (one-time cost, amortized over all subsequent warm-start fetches) |
| Containers | Multiple containers within one pod, each executing a step sequentially |
| Failure mode | Any container failure halts subsequent containers; the pod reports failure. The PVC retains its data for the next run |
| Recovery | Workflow retry policy governs whether the entire ContainerSet is re-executed. Because workspace data persists on the PVC, retries benefit from the same warm-start behavior |

This eliminates the CephFS metadata server bottleneck identified in Section 1.2.3. The RWO block PVC provides local-storage-class I/O performance for sequential preparation steps, while the mutex serialization is acceptable because the preparation phase is inherently sequential. Kaniko fan-out pods use emptyDir and receive their build context via S3 artifact passing, so they are not constrained by the mutex.

### 4.2.3 Child Workflow (Workflow-of-Workflows)

For the PR validation flow, the ContainerSet generates and submits a child workflow containing a dynamic DAG of lint, test, and build tasks. For the post-merge flow, the child workflow contains a Kaniko fan-out DAG.

| Aspect | Description |
|--------|-------------|
| Responsibility | Execute the dynamic task DAG generated from the Nx project graph |
| Generation | The DAG generator produces a complete Workflow manifest at runtime |
| Submission | The parent workflow submits the child workflow and monitors its completion |
| Parallelism | Independent tasks execute concurrently; dependent tasks wait for predecessors |
| Failure mode | Individual task failure does not halt independent tasks (Invariant 5) |
| Recovery | Failed tasks may be retried per the retry policy; the parent workflow reports aggregate status |

---

## 4.3 Nx Build Orchestration

### 4.3.1 Affected Detection

| Aspect | Description |
|--------|-------------|
| Responsibility | Determine which projects are impacted by a changeset |
| Mechanism | `nx affected` compares the current HEAD against the base commit (merge base for PRs, previous commit for main) |
| Output | List of affected project names and their dependency relationships |
| Authority | Sole source of change-detection truth (Invariant 1) |

### 4.3.2 Task Graph

| Aspect | Description |
|--------|-------------|
| Responsibility | Produce an ordered graph of tasks (lint, test, build) for affected projects |
| Mechanism | Nx generates a task graph with dependency edges derived from the project graph |
| Output | JSON representation of tasks and their dependencies |
| Consumption | The DAG generator consumes this graph to produce an Argo Workflow DAG |

### 4.3.3 S3 Remote Cache

| Aspect | Description |
|--------|-------------|
| Responsibility | Store and retrieve Nx task outputs across CI runs |
| Technology | @nx/s3-cache plugin targeting Ceph RGW Object Storage |
| Storage provisioning | ObjectBucketClaim via Rook-Ceph OBC |
| Read mode | All branches read from the cache |
| Write mode | Only the main branch writes to the cache |
| Cache key | Derived from task inputs (source files, dependencies, configuration) by Nx |
| Failure mode | Cache miss results in full task execution; cache unavailability does not block builds |
| CREEP mitigation | PR branches operate in read-only mode to prevent cache poisoning |

The read-only restriction for PR branches prevents a compromised or buggy PR from writing malicious cache entries that would be consumed by subsequent main-branch builds. This addresses the CREEP (Cache Read-Execute-Evade-Poison) attack vector.

---

## 4.4 DAG Generator

| Aspect | Description |
|--------|-------------|
| Responsibility | Translate the Nx task graph into an Argo Workflow DAG manifest |
| Input | Nx task graph (JSON) and service configuration metadata |
| Output | Argo Workflow manifest with DAG tasks and dependency edges |
| Authority | Nx task graph determines structure; the generator performs format translation only |
| Service metadata | service-config.mjs provides the mapping from project names to Dockerfiles and build arguments |
| Failure mode | If the Nx task graph is empty (no affected projects), the generator produces a no-op workflow |
| Recovery | Deterministic: the same input always produces the same output |

The DAG generator does not make ordering decisions. It translates the dependency edges from the Nx task graph into the `dependencies` field of Argo DAG tasks. The Argo Workflow controller then schedules tasks in dependency order with maximum parallelism.

---

## 4.5 Kaniko Image Builder

| Aspect | Description |
|--------|-------------|
| Responsibility | Build Docker images inside the cluster without a Docker daemon |
| Execution | Each affected service spawns a separate Kaniko pod |
| Build context | Received via S3 artifact from the ContainerSet pod |
| Registry destination | Harbor (in-cluster container registry) |
| Cache layer | Kaniko cache repo in Harbor for layer deduplication |
| Image tagging | Git commit SHA as the image tag for traceability |
| Credentials | Harbor registry credentials sourced from Vault |
| Failure mode | Individual Kaniko pod failure does not affect other concurrent Kaniko pods (Invariant 5) |
| Recovery | Failed builds may be retried per the workflow retry policy |

Kaniko operates without Docker daemon access, running as an unprivileged container. Each Kaniko pod receives its build context (Dockerfile, source code, compiled artifacts) through S3 artifact passing. This decouples the build context preparation (which occurs in the ContainerSet pod) from the image construction (which occurs in parallel Kaniko pods).

---

## 4.6 Verdaccio Package Registry

| Aspect | Description |
|--------|-------------|
| Responsibility | Host published `@pnats` scoped packages for consumption during Docker builds |
| Inbound interface | pnpm publish from the ContainerSet pod |
| Outbound interface | pnpm install from Kaniko build contexts |
| Publish ordering | Shared libraries MUST be published before any dependent Docker build begins |
| Version resolution | `workspace:*` references are rewritten to concrete published versions |
| Credentials | npm auth token sourced from Vault |
| Failure mode | Publish failure halts all downstream Docker builds that depend on the failed package |
| Recovery | Republishing is idempotent; the same version can be published if the previous attempt partially failed |

The workspace reference rewriting step transforms the monorepo's internal `workspace:*` protocol references into version-pinned references that Verdaccio can resolve. This step executes after library publishing and before Docker build context preparation.

---

## 4.7 Harbor Container Registry

| Aspect | Description |
|--------|-------------|
| Responsibility | Store container images produced by CI, serve images to the cluster for deployment |
| Inbound interface | Docker registry API v2 (image push from Kaniko) |
| Outbound interface | Docker registry API v2 (image pull from kubelet) |
| Image lifecycle | Governed by Harbor's retention policies (outside this RFC's scope) |
| Vulnerability scanning | Harbor's integrated scanner evaluates images post-push (outside this RFC's scope) |
| Failure mode | Registry unavailability prevents image push; the Kaniko pod reports failure |
| Recovery | Kaniko retries push operations per its built-in retry mechanism |

---

## 4.8 GitOps Updater

| Aspect | Description |
|--------|-------------|
| Responsibility | Commit new image tags to the pn-infra repository after all images in a pipeline run are built |
| Input | Image tags and digests collected from completed Kaniko pods |
| Output | A Git commit to the pn-infra repository updating image references |
| Atomicity | All image tags from a single pipeline run are committed in a single commit |
| Authentication | SSH deploy key sourced from Vault |
| Failure mode | If the Git push fails (merge conflict, authentication failure), the workflow reports failure |
| Recovery | The commit is retried with a fresh clone of the target branch to resolve potential conflicts |

The GitOps updater enforces Invariant 2 by ensuring that the only cluster-state-modifying action is a Git commit. The CI pipeline never interacts with the Kubernetes API to create, modify, or delete workloads.

---

## 4.9 Notification Dispatcher

| Aspect | Description |
|--------|-------------|
| Responsibility | Notify the development team of pipeline completion status |
| Mechanism | Slack webhook invocation |
| Trigger | Pipeline completion (success or failure) |
| Content | Pipeline name, commit SHA, affected services, duration, and status |
| Failure mode | Notification failure does not affect pipeline outcome; notifications are fire-and-forget |
| Recovery | No retry; notification failures are logged but do not block the pipeline |

---

## 4.10 Secret Bootstrap Pattern (Generate-Push-Pull)

Some CI secrets are not sourced from an external system -- they are random values that must be generated once (auth tokens, encryption keys) and then treated as stable credentials. The Generate-Push-Pull pattern addresses this by creating the secret inside the cluster, seeding it to Vault, and then treating Vault as the ongoing source of truth.

| Aspect | Description |
|--------|-------------|
| Responsibility | Bootstrap randomly generated secrets into Vault without manual intervention or storing values in Git |
| Mechanism | Three ESO resources execute in sync-wave order: a Password Generator creates a random value (one-time), a PushSecret seeds that value to Vault (one-time), and an ExternalSecret pulls from Vault on an ongoing basis |
| Ordering | ArgoCD sync waves enforce sequencing: generate (wave -6) before push (wave -5) before pull (wave -4) |
| Source of truth | Vault. After the initial seed, the PushSecret and generator become inert; only the ExternalSecret remains active |
| First deploy | The generator creates a random value, PushSecret seeds Vault, ExternalSecret pulls from Vault into a Kubernetes Secret |
| Subsequent deploys | The generator is idempotent (refreshInterval: 0), PushSecret finds Vault already populated, ExternalSecret continues pulling from Vault. The secret value does not change |
| Namespace wipe recovery | The ExternalSecret recreates the Kubernetes Secret from Vault. The generator does not regenerate because the PushSecret detects the Vault path already exists |
| Failure mode | If any sync wave fails, ArgoCD halts at that wave. Dependent resources (workflow pods, services) are not created until secrets are available |
| Recovery | Retry the ArgoCD sync. The pattern is idempotent: re-running any step does not alter the value already stored in Vault |

This pattern satisfies Invariant 4 (Vault Secret Authority) because the generated value reaches Vault within the same sync operation and all subsequent consumption is via ExternalSecrets. It avoids manual `vault kv put` commands (which violate GitOps), storing secrets in Git (even encrypted), circular dependencies between generators and Vault, and token regeneration on redeploy (which would break dependent services).

The nx-cache-server auth token is the reference implementation of this pattern within the CI stack.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [<-- 3. Architecture](./03-architecture.md) | [Table of Contents](./00-index.md#table-of-contents) | [5. Rationale -->](./05-rationale.md) |

---

*End of Section 4 -- RFC-CICD-0001*
