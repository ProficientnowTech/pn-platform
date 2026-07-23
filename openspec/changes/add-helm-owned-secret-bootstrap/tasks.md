## 1. Helm Ownership Flow
- [x] 1.1 Scaffold Helm chart for bootstrap secret artifacts and ensure generated manifests are packaged safely.
- [x] 1.2 Update secret rendering script to emit manifests into the chart and deploy them via `helm upgrade --install` (no direct `kubectl apply`).
- [x] 1.3 Wire deploy/run helpers and documentation to the Helm-managed bootstrap flow.

## 2. Validation
- [x] 2.1 `openspec validate add-helm-owned-secret-bootstrap --strict`
- [x] 2.2 Smoke-check chart templating with sample render output.
