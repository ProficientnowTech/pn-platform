## Context
- Existing deployment relies on a single target chart with sync waves, but Argo does not block the next wave until the previous application is healthy.
- Complex dependencies (e.g., Vault needs ingress/cert-manager and rook storage) can fail if stacks reconcile simultaneously.
- We want an Argo-native orchestration: app-of-app-of-app hierarchy plus dependency-aware hooks, with no imperative script sequencing.

## Goals
- Each major stack (infrastructure, storage, security, monitoring, data-streaming, platform-data, developer-platform, development-workloads, application-infra, backup/DR) is represented by its own Argo Application.
- Stack Applications declare dependencies on upstream stacks and refuse to reconcile until those stacks are `Synced` + `Healthy`.
- `platform-root` deploys Argo Projects first, then the stack orchestrator, ensuring RBAC boundaries exist before stacks deploy.
- Hooks and annotations are standardized and documented.

## Approach
1. **Stack Orchestrator Chart**
   - Helm chart defining one Argo Application per stack, referencing `platform/stacks/<stack>/target-chart`.
   - Applications carry metadata:
     ```yaml
     metadata:
       annotations:
         platform.pnats.cloud/dependencies: '["platform-infrastructure","platform-storage"]'
         platform.pnats.cloud/stack-order: "300"
     ```
   - `platform-root` Helm chart lists `project-chart` first (lower sync wave), then the orchestrator Application (higher wave) so Projects exist before stacks.

2. **Dependency Hooks**
   - Shared `PreSync` hook Job (packaged as a Helm template or helper chart) that:
     - Reads the Application’s dependency annotation.
     - Uses `kubectl` (or the Argo API) to poll `applications.argoproj.io` CRs and verify each dependency is `status.sync.status == Synced` and `status.health.status == Healthy`.
     - Retries with exponential backoff; fails if dependencies fail, causing Argo to stop this stack until the operator investigates.
   - Hooks live inside each stack target chart; they run automatically whenever Argo reconciles that stack Application.

3. **Secret Pipeline Alignment**
   - Security stack includes additional hooks to ensure Vault + PushSecrets + ExternalSecrets complete before the Application reports Healthy; downstream stacks depend on the security stack, so they won’t start until secrets are live.
   - Developer stacks continue to define sync waves for intra-stack ordering, but cross-stack ordering is now controlled by the dependency hooks.

4. **Visibility & Management**
   - Argo UI shows hierarchy: `platform-root` → `stack-orchestrator` → individual stack Applications → component apps.
   - Operators can inspect a single stack Application to see all constituent workloads and their status.

## Alternatives Considered
- Script-based orchestration (original approach): rejected per requirement; we want Argo to manage everything once bootstrap finishes.
- Kustomize overlays per stack without hooks: still race conditions when upstream stacks are unhealthy.
- Custom controller outside Argo: more moving parts; sticking with Argo hooks keeps everything declarative.

## Risks & Mitigations
- Hook job fails due to API access: ensure service account has permission to read Application CRs (cluster-scoped RBAC added via stack charts).
- Cyclic dependencies: detect by validating annotations (optional lint step) or documentation guidelines.
- Longer reconciliation times: acceptable; hooks only run when dependencies change or a stack syncs.

## Rollout Plan
1. Scaffold stack target charts (if not already) and the stack orchestrator chart.
2. Add dependency annotations + hook templates to each stack chart.
3. Update `platform-root` to deploy `project-chart` (wave -10) then stack orchestrator (wave 0).
4. Document the dependency annotation format and hook behaviour; update runbooks.
5. Test by triggering stack syncs out of order and confirm hooks block reconciliation until prerequisites are healthy.
