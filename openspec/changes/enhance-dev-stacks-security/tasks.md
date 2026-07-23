## 1. Planning & Specs
- [ ] 1.1 Review security stack docs and Azure AD integration guidance.
- [ ] 1.2 Draft design covering Vault GitOps, Keycloak RBAC, and app wiring (this change).
- [ ] 1.3 Create/modify spec deltas if required once base specs exist.

## 2. Vault & External Secrets
- [ ] 2.1 Extend Crossplane Vault templates with per-stack mounts, policies, and auth roles.
- [ ] 2.2 Define KV secrets (GitOps) for each application credential and wire them into ExternalSecret manifests.
- [ ] 2.3 Remove committed Secrets/SealedSecrets from charts and replace with ESO consumption.

## 3. Keycloak & Azure AD Federation
- [ ] 3.1 Configure Azure AD IdP + mappers, group hierarchy, and Crossplane-managed clients for all tooling.
- [ ] 3.2 Ensure client secrets flow into Vault KV paths consumed by ESO.
- [ ] 3.3 Document/automate group-to-application RBAC bindings (Harbor scopes, Verdaccio publish rights, etc.).

## 4. Application Updates
- [ ] 4.1 Backstage: Vault/ESO secret loading, OIDC tweaks, developer resources.
- [ ] 4.2 Harbor: enable OIDC auth, Vault S3/admin credentials, per-registry RBAC via Keycloak groups.
- [ ] 4.3 Verdaccio: add oauth2-proxy/Keycloak auth, enforce publish/view groups.
- [ ] 4.4 Kargo, Tekton, Argo Rollouts: switch to Keycloak auth, remove static secrets.
- [ ] 4.5 Ensure target-chart values and sync waves deploy ESO + auth sidecars before workloads.

## 5. Validation & Docs
- [ ] 5.1 Define verification steps (Argo sync, Vault status, ESO readiness, Keycloak login tests).
- [ ] 5.2 Update READMEs/runbooks for onboarding/offboarding and new auth flows.
- [ ] 5.3 Run `openspec validate enhance-dev-stacks-security --strict`.
