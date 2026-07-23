## Why
ArgoCD currently applies every application in one giant target chart with sync waves, but there is no enforcement that “stack A must be healthy before stack B starts.” Dependencies (e.g., Vault needing ingress/cert-manager/rook storage) can race, leading to blocked or failing deployments. We need a deterministic, Argo-native orchestration layer that understands stack dependencies and blocks reconciliation until prerequisites are healthy.

## What Changes
- Introduce a stack orchestrator chart that renders one Argo Application per platform stack (infrastructure → storage → security → … backup) and captures dependencies via annotations.
- Add dependency-aware PreSync hooks: each stack application runs a lightweight job that polls the upstream stack Applications and only proceeds once they are `Synced` + `Healthy`.
- Update stack target-charts to include these hooks, expand `platform.pnats.cloud/dependencies` annotations, and ensure PushSecret/ExternalSecret helpers run in the correct sync wave.
- Document the app-of-app-of-app layout and dependency rules so operators know where to inspect stack health.

## Impact
- ArgoCD structure changes: `platform-root` now deploys `project-chart` first, then the stack orchestrator, which in turn deploys each stack Application.
- Stack charts gain hook jobs and standardized dependency annotations.
- Scripts no longer gate stack sequencing; Argo handles it declaratively.
