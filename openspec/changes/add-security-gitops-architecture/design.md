## Context
- Security features (Vault, Crossplane providers, Keycloak automation, Kyverno, Falco, network observability) are fragmented and not described in a single GitOps-first plan.
- Placeholder secrets (e.g., Vault provider tokens) and CRD timing issues risk failed syncs.
- User wants Crossplane-heavy automation, reuse of KubriX Keycloak patterns, and end-to-end Vault-managed secrets without breaking existing bootstrap flow.

## Goals
- GitOps blueprint for security stack: Vault as source of truth, ExternalSecrets for consumption, Crossplane for external dependencies, ArgoCD ordering documented.
- Automated Keycloak realm/client/flow provisioning (GitHub/AzureAD OIDC, 2FA/OTP flows) via Crossplane.
- Add Crossplane providers: Kafka, Temporal, OVH, Grafana, Harbor, PostgreSQL, Proxmox-BPG with Vault-sourced credentials.
- Policy + runtime security: Kyverno baseline, Falco with plugins (k8saudit, github, k8smeta) and Falco Talon routing.
- Network observability for Calico (Hubble is Cilium-only) — choose Calico-friendly alternative.

## Non-Goals
- No direct implementation changes in this change set; only specification/design.
- No vendor lock to Cilium/Hubble; keep Calico-first.

## Decisions (initial)
- Vault-first secret flow: bootstrap renderer writes SealedSecret + PushSecret to Vault; ESO reads back for workloads.
- Crossplane becomes the provisioning plane for providers and Keycloak resources; credentials always sourced from Vault secrets.
- ArgoCD ordering must wait for CRDs (Vault, ESO, Crossplane, Kyverno, Falco) before dependent hooks/jobs run.
- Network observability: adopt NetObserv operator with FlowCollector (eBPF agents/flowlogs-pipeline) for Calico compatibility instead of Hubble (Cilium-only).
- Falco plugin set: include k8saudit, github, k8smeta, collector, kafka, and journald; route actions via Falco Talon.
- Keycloak flows: Browser = identity-first (AzureAD) + selective OTP (required for high-security apps: ArgoCD, Grafana, Harbor, Keycloak Admin; optional for standard apps: Backstage, Temporal UI, KubeVirt Manager, Kargo, Tekton Dashboard, Argo Rollouts, OneUptime, Verdaccio); Direct Grant = OTP conditional on client; Admin console = OTP required; Service accounts = client-credentials only. IdP: AzureAD for all users (developers and admins); GitHub IdP disabled.

## Risks / Trade-offs
- CRD readiness: need health/dependency checks to avoid wait-hook failures.
- Secret migration: must ensure existing apps are not broken when moving placeholders into Vault.
- Provider sprawl: multiple providers increase upgrade surface; pin versions and add health checks.
- Audit/identity drift: Keycloak automation must remain idempotent and Git-driven to avoid manual changes.

## Open Questions
- Any regulatory requirements (SOC2) that mandate specific audit retention for Falco/Kyverno/NetObserv events?
