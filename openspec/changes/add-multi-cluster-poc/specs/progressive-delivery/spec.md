# Progressive Delivery Capability

## ADDED Requirements

### Requirement: Kargo Deployment
The platform SHALL provide Kargo for stage-based progressive delivery and promotion workflows.

#### Scenario: Deploy Kargo
- **WHEN** Kargo chart is deployed
- **THEN** Kargo API server and controller are running
- **AND** Kargo UI is accessible
- **AND** Kargo CRDs are registered (Project, Stage, Freight)

#### Scenario: Authenticate with Keycloak
- **WHEN** Kargo is configured with Keycloak OIDC
- **THEN** users can login via SSO
- **AND** user permissions are enforced

### Requirement: Argo Rollouts Deployment
The platform SHALL provide Argo Rollouts for advanced deployment strategies.

#### Scenario: Deploy Argo Rollouts
- **WHEN** Argo Rollouts chart is deployed to primary cluster
- **THEN** Argo Rollouts controller is running
- **AND** Rollout CRD is registered

#### Scenario: Deploy to workload cluster
- **WHEN** Argo Rollouts is deployed to dev cluster
- **THEN** controller runs in dev cluster
- **AND** can manage Rollout resources

### Requirement: Stage-Based Promotion
The platform SHALL support defining stages for progressive delivery with promotion policies.

#### Scenario: Create Kargo Project
- **WHEN** a Kargo Project is created for demo app
- **THEN** Project is active in Kargo
- **AND** promotion credentials are configured

#### Scenario: Define dev stage
- **WHEN** a dev Stage is created
- **THEN** Stage points to dev cluster
- **AND** Stage monitors git repository for changes
- **AND** Stage is ready to receive promotions

#### Scenario: Promote to dev
- **WHEN** a user triggers promotion to dev stage
- **THEN** Kargo creates Freight resource
- **AND** Kargo updates target repository/branch
- **AND** ArgoCD syncs changes to dev cluster

### Requirement: Canary Deployment Strategy
The platform SHALL support canary deployments using Argo Rollouts.

#### Scenario: Deploy with canary strategy
- **WHEN** a Rollout resource with canary strategy is applied
- **THEN** initial deployment uses 100% stable version
- **AND** canary pod set is created but receives 0% traffic

#### Scenario: Canary promotion
- **WHEN** Rollout is updated with new image
- **THEN** canary pods deploy with new version
- **AND** traffic gradually shifts to canary (e.g., 20%, 50%, 80%)
- **AND** stable version remains available

#### Scenario: Canary rollback
- **WHEN** canary version has errors
- **THEN** Rollout can be aborted
- **AND** all traffic routes back to stable version
- **AND** canary pods are terminated

### Requirement: Automated Promotion
The platform SHALL support automated promotion policies based on success criteria.

#### Scenario: Configure auto-promotion
- **WHEN** a Stage has auto-promotion policy
- **THEN** successful deployments trigger next stage promotion
- **AND** failed deployments block promotion

#### Scenario: Manual approval gate
- **WHEN** a Stage requires manual approval
- **THEN** promotion waits for user approval
- **AND** approved promotions proceed
- **AND** rejected promotions are blocked

### Requirement: Freight Tracking
The platform SHALL track Freight (artifact versions) across stages and environments.

#### Scenario: Create Freight
- **WHEN** new commit is pushed to watched repository
- **THEN** Kargo detects change and creates Freight
- **AND** Freight contains commit SHA and metadata

#### Scenario: Freight promotion history
- **WHEN** Freight is promoted through stages
- **THEN** promotion history is recorded
- **AND** users can view which Freight is in which stage
- **AND** users can see promotion timeline
