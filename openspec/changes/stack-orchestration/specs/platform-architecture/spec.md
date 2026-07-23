## ADDED Requirements

### Requirement: Stack-Level Argo Applications
Each major platform stack MUST be represented by its own Argo Application managed by an app-of-app-of-app hierarchy so operators can inspect stack health independently.

#### Scenario: Infrastructure stack visibility
- **WHEN** an operator opens ArgoCD
- **THEN** they see a `platform-root` application that owns a `stack-orchestrator`
- **AND** under that orchestrator they see dedicated Applications such as `platform-infrastructure`, `platform-storage`, `platform-security`, etc.

### Requirement: Dependency-Gated Reconciliation
Stack Applications SHALL declare upstream dependencies via `platform.pnats.cloud/dependencies` and MUST run a PreSync hook that blocks reconciliation until all dependencies are `Synced` + `Healthy`.

#### Scenario: Security waits for infrastructure + storage
- **WHEN** ArgoCD tries to sync the `platform-security` Application
- **THEN** its PreSync hook job reads `platform.pnats.cloud/dependencies: ["platform-infrastructure","platform-storage"]`
- **AND** the job polls those Application CRs until both report `Synced/Healthy`, only then allowing Vault/ESO/Keycloak to reconcile.

### Requirement: Projects Before Stacks
`platform-root` MUST deploy the Argo Project definitions (project-chart) before creating stack Applications so RBAC and destinations exist ahead of time.

#### Scenario: Target chart references existing projects
- **WHEN** Argo applies `platform-root`
- **THEN** the project chart syncs (lower wave) defining `platform-*` projects
- **AND** the stack orchestrator Application is created only after those projects are available, preventing “project not found” errors.

### Requirement: Security Stack Enforces Secret Pipeline
The security stack SHALL include hooks that ensure Vault, PushSecrets, and ExternalSecrets complete before the Application reports Healthy, guaranteeing downstream stacks receive secrets.

#### Scenario: PushSecrets run before developer stacks
- **WHEN** `platform-security` finishes Vault deployment
- **THEN** a PostSync hook runs the PushSecret jobs, waits for them to seed Vault, and only after success does the Application transition to Healthy
- **AND** `platform-developer-platform` (which depends on `platform-security`) does not sync until that healthy state is reached.
