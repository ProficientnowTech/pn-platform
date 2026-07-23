## Why
- Security capabilities (Vault, Keycloak, Kyverno, Falco, Crossplane providers) are not yet covered by a single GitOps plan, leading to placeholder secrets, duplicated patterns, and missing policy/observability guardrails.
- The user explicitly requested a comprehensive, GitOps-first security architecture that leverages Vault as the source of truth, Crossplane for external dependencies, and reusable patterns from KubriX for Keycloak automation.

## What Changes
- Define a consolidated security capability in OpenSpec covering: Vault-managed secret lifecycle (bootstrap → Vault → ExternalSecrets), Crossplane-managed providers (Kafka, Temporal, OVH, Grafana, Harbor, PostgreSQL, Proxmox-BPG), Keycloak realm/client/flow automation, Kyverno policy baselines, Falco (with plugins) + Falco Talon, and network observability for Calico.
- Specify GitOps workflows for migrating placeholder secrets into Vault using the existing bootstrap renderer, then syncing downstream via ExternalSecrets without breaking dependent workloads.
- Describe ArgoCD ordering/health dependencies so security apps (Vault, ESO, Kyverno, Falco, Crossplane) start cleanly and avoid CRD timing issues.
- Capture non-goals and risks (e.g., Hubble is Cilium-only; propose Calico-friendly alternatives).

## Impact
- Specs: Adds a new security capability specification under `openspec/changes/add-security-gitops-architecture/specs/security/spec.md`.
- Code/Helm: Guides future updates to Vault, Crossplane, Keycloak, Kyverno, Falco, ESO, and provider charts/apps (to be implemented after approval).
- Operations: Establishes Vault as the authoritative secret store with GitOps automation; informs future sync/monitoring and policy posture.
