## Why
Bootstrap secrets are applied directly with `kubectl`, so the generated SealedSecrets/PushSecrets are not owned by Helm. Downstream processes that expect Helm ownership require manual fixes and make the bootstrap flow fragile.

## What Changes
- Add a custom Helm chart that packages all rendered bootstrap secret artifacts so they are owned by a dedicated Helm release.
- Update the secret rendering script to target the chart outputs and deploy via `helm upgrade --install` instead of raw `kubectl apply`.
- Clean up docs and helper scripts so the bootstrap flow consistently uses the Helm-managed path.

## Impact
- Scripts: `platform/bootstrap/scripts/render-secrets.sh`, `platform/deploy.sh`, docs.
- New chart under `platform/bootstrap/secrets/` for Helm-managed secret artifacts.
- Requires re-rendering bootstrap secrets through the updated flow.
