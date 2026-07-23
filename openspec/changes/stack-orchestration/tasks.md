## 1. Stack App Structure
- [ ] 1.1 Create stack-specific target-chart directories (infrastructure, storage, security, monitoring, data-streaming, platform-data, developer-platform, development-workloads, application-infra, backup) or reuse existing ones.
- [ ] 1.2 Build a “stack orchestrator” chart that renders Argo Applications for each stack with the correct repo path, destination, syncOptions, and dependency annotations.
- [ ] 1.3 Update `platform-root` so it syncs `project-chart` first, then the orchestrator, ensuring Projects exist before the stack apps.

## 2. Dependency Hooks
- [ ] 2.1 Standardize `platform.pnats.cloud/dependencies` annotations across stack apps (JSON array of upstream Application names).
- [ ] 2.2 Add a `PreSync` hook Job (shared template) that reads those annotations, queries Argo Application CRs, and blocks until dependencies are `Synced` + `Healthy`.
- [ ] 2.3 Integrate hook templates into each stack’s target chart and ensure failures surface clearly in Argo.

## 3. Secret Pipeline Alignment
- [ ] 3.1 Ensure security stack hooks gate Vault/PushSecrets/ExternalSecrets so downstream stacks only reconcile after secrets exist.
- [ ] 3.2 Document how PushSecrets, ExternalSecrets, and workload charts align with the new stack Apps.

## 4. Documentation & Validation
- [ ] 4.1 Update architecture docs describing the app-of-app-of-app layout, dependency annotations, and hook behavior.
- [ ] 4.2 `openspec validate stack-orchestration --strict` and test a full reconcile to confirm stacks wait correctly.
