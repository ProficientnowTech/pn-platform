```
RFC-CICD-0001                                                  Appendix A
Category: Standards Track                                       Glossary
```

# Appendix A: Glossary

[<-- Evolution](./06-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: References -->](./appendix-b-references.md)

---

## A.1 Term Definitions

**Affected Project**
A project within the Nx project graph that is determined to require action based on changed files in a given commit or pull request. As used in this RFC, "affected" refers exclusively to the output of `nx affected` and includes both directly modified projects and projects with transitive dependencies on modified code.

**Argo Events**
A Kubernetes-native event-driven automation framework that provides EventSources, EventBus, and Sensors for ingesting external events and triggering workflows. As used in this RFC, Argo Events serves as the webhook ingestion and event routing layer.

**Argo Workflows**
A Kubernetes-native workflow engine that executes directed acyclic graphs of tasks as pods. As used in this RFC, Argo Workflows serves as the pipeline orchestration engine.

**Build Context**
The set of files required by Kaniko to construct a Docker image, including the Dockerfile, source code, and compiled artifacts. As used in this RFC, the build context is prepared in the ContainerSet pod and transferred to Kaniko pods via S3 artifacts.

**ContainerSet**
An Argo Workflows pod type that runs multiple containers sequentially within a single pod, sharing volumes. As used in this RFC, the ContainerSet hosts the workspace preparation phase (clone, install, DAG generation).

**CREEP**
Cache Read-Execute-Evade-Poison. An attack vector where a compromised CI run writes malicious cache entries that are consumed by subsequent builds. As used in this RFC, CREEP is mitigated by restricting PR branches to read-only cache access.

**DAG (Directed Acyclic Graph)**
A graph structure where edges have direction and no cycles exist. As used in this RFC, DAG refers to both the Nx task graph (which defines build ordering) and the Argo Workflow DAG (which defines pod execution ordering).

**DAG Generator**
The component (generate-argo-dag.mjs) that translates the Nx task graph into an Argo Workflow manifest. The generator performs format translation without making ordering decisions.

**emptyDir**
A Kubernetes volume type that provides ephemeral storage backed by the node's local disk. The volume exists for the lifetime of the pod and is deleted when the pod terminates. As used in this RFC, emptyDir volumes provide workspace storage for ContainerSet pods.

**EventBus**
The Argo Events message transport layer. As used in this RFC, the EventBus uses NATS JetStream for durable, ordered event delivery between EventSources and Sensors.

**EventSource**
An Argo Events component that receives external events (such as GitHub webhooks) and publishes them to the EventBus.

**ExternalSecrets Operator**
A Kubernetes operator that synchronizes secrets from external secret management systems (such as Vault) into Kubernetes Secret objects.

**GitOps**
An operational model where the desired state of infrastructure and applications is declared in Git repositories, and a reconciliation agent (ArgoCD) ensures the cluster matches the declared state.

**GitOps Updater**
The CI pipeline component that commits updated image tags to the pn-infra infrastructure repository after Docker images are built and pushed.

**Harbor**
An open-source container registry that provides image storage, replication, and vulnerability scanning. As used in this RFC, Harbor is the in-cluster destination for all Docker images produced by CI.

**Kaniko**
A tool for building Docker images inside a container without requiring a Docker daemon. As used in this RFC, Kaniko executes as individual pods in the Argo Workflow fan-out phase.

**NATS JetStream**
A persistence layer for NATS that provides at-least-once delivery, message replay, and stream-based consumption. As used in this RFC, NATS JetStream backs the Argo Events EventBus.

**Nx**
A build orchestration tool for monorepos that provides project graph analysis, affected-project detection, task caching, and dependency-ordered task execution.

**Nx Project Graph**
The dependency graph that Nx computes from project configurations, import analysis, and explicit dependency declarations. The project graph determines which projects are affected by a changeset and the order in which tasks must execute.

**Nx Task Graph**
A graph of individual tasks (lint, test, build) derived from the project graph for a set of affected projects. Each node represents a specific task for a specific project, and edges represent task-level dependencies.

**ObjectBucketClaim (OBC)**
A Kubernetes resource that provisions an S3-compatible bucket through a storage operator. As used in this RFC, OBCs provision Ceph RGW buckets for Nx cache storage.

**Sensor**
An Argo Events component that subscribes to EventBus events, evaluates filter criteria, and triggers actions (such as submitting Argo Workflows).

**service-config.mjs**
A configuration module in the pnow-ats-v2 repository that maps service names to their Dockerfiles, build arguments, and deployment metadata. The DAG generator consumes this configuration to produce correct Kaniko build parameters.

**Verdaccio**
A lightweight npm registry. As used in this RFC, Verdaccio is the in-cluster registry for `@pnats` scoped shared libraries published during CI.

**Workflow-of-Workflows**
An Argo Workflows pattern where a parent workflow generates and submits a child workflow at runtime. The parent monitors the child's completion and reports aggregate status.

**Workspace Protocol**
The pnpm convention of using `workspace:*` version specifiers in package.json to indicate that a dependency should be resolved from the local monorepo workspace rather than a registry.

---

## A.2 Diagram Index

| Diagram | Type | Section |
|---------|------|---------|
| System Overview | flowchart | 3.1 |
| Trust Boundaries | flowchart | 3.3 |
| PR Validation Flow | sequenceDiagram | 3.4 |
| Post-Merge Build Flow | sequenceDiagram | 3.5 |

---

*End of Appendix A -- RFC-CICD-0001*
