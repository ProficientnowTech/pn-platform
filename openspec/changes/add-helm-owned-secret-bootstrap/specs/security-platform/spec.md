## ADDED Requirements

### Requirement: Helm-Owned Bootstrap Secret Artifacts
Bootstrap secret rendering SHALL package all SealedSecret and PushSecret manifests into a dedicated Helm chart so Kubernetes ownership and pruning are handled by Helm instead of ad-hoc kubectl apply.

#### Scenario: Helm release owns rendered secrets
- **WHEN** bootstrap secrets are rendered from `platform/bootstrap/secrets/specs`
- **THEN** the manifests are written into the bootstrap secret chart and deployed via `helm upgrade --install`
- **AND** the resulting SealedSecret/PushSecret resources carry Helm release ownership for downstream tooling.

#### Scenario: Removed specs are pruned automatically
- **WHEN** a secret spec is deleted or renamed and the bootstrap renderer is rerun
- **THEN** the regenerated chart omits the old manifest
- **AND** the Helm upgrade removes the corresponding resources so stale secrets are not left in the cluster.
