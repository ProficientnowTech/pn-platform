```
RFC-CICD-0001                                                   Section 6
Category: Standards Track                                      Evolution
```

# 6. Evolution

[<-- Rationale](./05-rationale.md) | [Index](./00-index.md#table-of-contents) | [Next: Glossary -->](./appendix-a-glossary.md)

---

## 6.1 Anticipated Extensions

### 6.1.1 Python Service Integration

The 11 Python services currently outside Nx management represent the most likely extension to this architecture. If these services are brought under Nx's project graph (via an Nx Python plugin or manual project registration), the existing DAG generator and Kaniko fan-out mechanisms apply without architectural change. The DAG generator already translates arbitrary Nx task graphs; adding Python projects to that graph extends coverage without modifying the translation logic.

If Python services remain outside Nx, a parallel pipeline path with its own change-detection mechanism would be required. This path would operate independently of the Nx-driven pipeline and would not share the DAG generation or caching infrastructure.

### 6.1.2 Multi-Environment Promotion

The current architecture delivers image tags to a single target within the infrastructure repository. A future extension MAY introduce multi-environment promotion where the GitOps updater writes image tags to environment-specific paths (staging, production) based on promotion rules. The GitOps updater component (Section 4.8) is designed to accept target path configuration, making it extensible to multiple environments without architectural change.

### 6.1.3 Test Result Aggregation

The current architecture executes test targets through the Nx task graph but does not aggregate or persist test results beyond Argo Workflows' native log capture. A future extension MAY introduce a test result collector that extracts structured test output (JUnit XML, coverage reports) from workflow artifacts and publishes them to a reporting service.

### 6.1.4 Artifact Attestation

Supply chain security frameworks (SLSA, Sigstore) MAY require image provenance attestation in future. The Kaniko build step produces images that are pushed directly to Harbor. An attestation extension would add a post-build step that signs the image manifest and attaches provenance metadata. The fan-out architecture accommodates this as an additional DAG node dependent on the corresponding Kaniko task.

---

## 6.2 Extension Points

The architecture provides the following extension points where new capabilities can be added without modifying existing components.

| Extension Point | Mechanism | Constraint |
|-----------------|-----------|------------|
| New Nx targets | Add targets to project.json; the DAG generator includes them automatically | Target MUST be registered in Nx project configuration |
| New service types | Add entries to service-config.mjs; the DAG generator maps them to Dockerfiles | Service MUST have a corresponding Dockerfile |
| Additional Sensors | New Argo Events Sensors can subscribe to the same EventBus | Sensor MUST NOT duplicate existing trigger conditions |
| Post-build steps | Additional DAG nodes can depend on Kaniko task completion | Steps MUST NOT mutate cluster state directly (Invariant 2) |
| Notification channels | Additional webhook targets in the notification step | Notification failure MUST NOT affect pipeline outcome |

---

## 6.3 Deprecation Paths

### 6.3.1 Workspace Reference Rewriting

The `workspace:*` rewriting step exists because pnpm's workspace protocol is not resolvable outside the monorepo context. If a future version of the package tooling or Docker build process natively supports workspace resolution (for example, through multi-stage builds that include the full workspace), the rewriting step MAY be removed. Removal would simplify the post-merge flow by eliminating the step between library publishing and Docker context preparation.

### 6.3.2 S3 Artifact Passing

S3 artifact passing between the ContainerSet and Kaniko pods is a workaround for the inability to share an emptyDir volume across pods. If a future Argo Workflows feature or Kubernetes storage mechanism enables efficient cross-pod volume sharing without the CephFS bottleneck, S3 artifact passing MAY be replaced with direct volume sharing. The architecture does not depend on S3 artifact passing as a semantic concept; it depends on the ability to transfer build context from the preparation phase to the build phase.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [<-- 5. Rationale](./05-rationale.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix A: Glossary -->](./appendix-a-glossary.md) |

---

*End of Section 6 -- RFC-CICD-0001*
