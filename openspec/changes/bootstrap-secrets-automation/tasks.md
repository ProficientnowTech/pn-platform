## 1. Bootstrap Architecture
- [x] 1.1 Audit current secrets (bootstrap/secrets, stacks/*/secrets) and classify per application. _Tracked in `docs/platform/security/secret-inventory.md`._
- [x] 1.2 Add a sealed-secrets install step to `platform/deploy.sh` (helm install outside Argo) and wait for controller ready.
- [x] 1.3 Build the bootstrap generator that reads committed SealedSecrets, renders transient Secrets + PushSecrets, and wire it into `platform/run.sh`/`deploy.sh`.
- [x] 1.4 Ensure deploy flow applies bootstrap secrets pre-Argo, applies PushSecrets after Vault is healthy, and cleans up plaintext artifacts.
- [x] 1.5 Populate SealedSecret templates for every application listed in `docs/platform/security/secret-inventory.md` so the generator covers the entire platform surface area.

## 2. Stack Integration
- [x] 2.1 Remove plaintext secrets from developer-platform/development-workloads charts; replace with ExternalSecret templates pointing to Vault paths.
- [x] 2.2 Add PushSecret/ExternalSecret wiring for ArgoCD repo creds + OIDC config.
- [x] 2.3 Ensure Crossplane/Vault/ESO/Keycloak charts expose the required KV mounts, policies, and auth roles.

## 3. Target Chart & Sync Waves
- [x] 3.1 Encode the requested stack order (infra → storage → security → monitoring → data-streaming → platform-data → developer-platform → development-workloads → application-infra → backup) in `platform/target-chart`.
- [x] 3.2 Introduce helper jobs/apps (vault seed, cleanup hooks) with correct sync waves and dependencies.

## 4. Documentation & Validation
- [x] 4.1 Extend `docs/platform/security/dev-workload-integration.md` with bootstrap diagrams, push/pull sequences, and runbooks.
- [x] 4.2 Update Crossplane example docs to highlight SealedSecret → PushSecret → Vault usage.
- [x] 4.3 `openspec validate bootstrap-secrets-automation --strict` and smoke-test the bootstrap pipeline.
