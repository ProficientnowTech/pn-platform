# Vault Secret Flow Architecture

This document explains how secrets flow through the platform, focusing on the integration between Vault, External Secrets Operator (ESO), and Crossplane.

## Overview

The platform uses a GitOps-driven secret management system where:
- **Vault** stores secrets securely
- **External Secrets Operator (ESO)** syncs secrets between Kubernetes and Vault
- **Crossplane Vault Provider** manages Vault configuration (policies, roles) declaratively

## The Players

| Component | Role | Analogy |
|-----------|------|---------|
| **Vault** | Central secret storage | A secure safe |
| **ESO (External Secrets Operator)** | Moves secrets between K8s and Vault | A courier service |
| **Crossplane Vault Provider** | Configures Vault itself via K8s manifests | A locksmith who can change safe permissions |
| **PushSecret** | ESO resource that pushes K8s secrets TO Vault | Outbound courier |
| **ExternalSecret** | ESO resource that pulls secrets FROM Vault | Inbound courier |

## High-Level Architecture

```mermaid
flowchart TB
    subgraph "Kubernetes Cluster"
        subgraph "platform-data namespace"
            PG[PostgreSQL Operator]
            PGSecret[K8s Secret<br/>postgres credentials]
            Push[PushSecret]
        end

        subgraph "external-secrets namespace"
            ESO[External Secrets<br/>Operator]
        end

        subgraph "temporal namespace"
            ExtSecret[ExternalSecret]
            TempSecret[K8s Secret<br/>temporal-postgres-secret]
            Temporal[Temporal Pods]
        end

        subgraph "crossplane-system namespace"
            Crossplane[Crossplane<br/>Vault Provider]
            AdminToken[vault-admin-token<br/>Secret]
        end

        subgraph "vault namespace"
            VaultPods[Vault Pods]
            VaultInit[vault-init<br/>Secret]
            TokenSync[root-token-sync<br/>Job]
        end
    end

    subgraph "Vault Storage"
        VaultSecrets[(Vault KV Store)]
        VaultPolicy[Vault Policies]
    end

    PG -->|creates| PGSecret
    PGSecret -->|watched by| Push
    Push -->|uses| ESO
    ESO -->|writes to| VaultSecrets

    ExtSecret -->|uses| ESO
    ESO -->|reads from| VaultSecrets
    ESO -->|creates| TempSecret
    TempSecret -->|mounted by| Temporal

    Crossplane -->|manages| VaultPolicy
    Crossplane -->|authenticates via| AdminToken

    VaultInit -->|read by| TokenSync
    TokenSync -->|creates| AdminToken

    VaultPolicy -->|grants access to| VaultSecrets
```

## The Secret Journey: PostgreSQL to Temporal

This is the complete flow of how database credentials get from PostgreSQL operator to Temporal.

```mermaid
sequenceDiagram
    participant PGOp as PostgreSQL Operator
    participant K8s1 as K8s Secret<br/>(platform-data)
    participant Push as PushSecret
    participant ESO as External Secrets Operator
    participant Vault as Vault
    participant Ext as ExternalSecret
    participant K8s2 as K8s Secret<br/>(temporal)
    participant App as Temporal Pods

    Note over PGOp,App: Phase 1: Credential Generation
    PGOp->>K8s1: Creates secret with<br/>username & password

    Note over PGOp,App: Phase 2: Push to Vault
    Push->>K8s1: Watches for changes
    Push->>ESO: Requests push to Vault
    ESO->>Vault: PUT secret/platform-data/postgres/temporal
    Vault-->>ESO: 200 OK (if policy allows)

    Note over PGOp,App: Phase 3: Pull from Vault
    Ext->>ESO: Requests secret from Vault
    ESO->>Vault: GET secret/platform-data/postgres/temporal
    Vault-->>ESO: Returns credentials
    ESO->>K8s2: Creates/updates secret

    Note over PGOp,App: Phase 4: Application Usage
    App->>K8s2: Mounts secret as env vars
    App->>App: Connects to PostgreSQL
```

## The Permission Problem

ESO needs permission to read/write secrets in Vault. Without proper policies, ESO gets `403 Permission Denied`.

```mermaid
flowchart LR
    subgraph "Without Policy"
        ESO1[ESO] -->|PUT secret/platform-data/...| Vault1[Vault]
        Vault1 -->|403 Forbidden| ESO1
    end

    subgraph "With Policy"
        ESO2[ESO] -->|PUT secret/platform-data/...| Vault2[Vault]
        Vault2 -->|Check Policy| Policy[external-secrets-policy]
        Policy -->|Allowed| Vault2
        Vault2 -->|200 OK| ESO2
    end
```

## The `external-secrets-policy`

This Vault policy grants ESO permission to manage secrets:

```hcl
# Application secrets
path "secret/data/applications/*" {
  capabilities = ["create", "update", "read", "list"]
}
path "secret/metadata/applications/*" {
  capabilities = ["create", "update", "read", "list"]
}

# Platform data secrets (PostgreSQL credentials, etc.)
path "secret/data/platform-data/*" {
  capabilities = ["create", "update", "read", "list"]
}
path "secret/metadata/platform-data/*" {
  capabilities = ["create", "update", "read", "list"]
}

# Platform config secrets
path "secret/data/platform-config/*" {
  capabilities = ["create", "update", "read", "list"]
}
path "secret/metadata/platform-config/*" {
  capabilities = ["create", "update", "read", "list"]
}
```

## Creating Policies via GitOps (Crossplane)

Instead of manually running `vault policy write`, we use Crossplane to manage Vault policies declaratively:

```mermaid
flowchart LR
    subgraph "Git Repository"
        Manifest[Policy CR<br/>YAML Manifest]
    end

    subgraph "Kubernetes"
        ArgoCD[ArgoCD]
        PolicyCR[Policy CR<br/>in cluster]
        Crossplane[Crossplane<br/>Vault Provider]
    end

    subgraph "Vault"
        VaultPolicy[Vault Policy]
    end

    Manifest -->|syncs| ArgoCD
    ArgoCD -->|creates| PolicyCR
    PolicyCR -->|reconciled by| Crossplane
    Crossplane -->|creates/updates| VaultPolicy
```

The Policy Custom Resource:

```yaml
apiVersion: vault.vault.upbound.io/v1alpha1
kind: Policy
metadata:
  name: external-secrets-policy
spec:
  providerConfigRef:
    name: vault-admin  # References ProviderConfig with Vault credentials
  forProvider:
    name: external-secrets-policy
    policy: |
      path "secret/data/platform-data/*" {
        capabilities = ["create", "update", "read", "list"]
      }
      # ... more paths
```

## Crossplane Authentication to Vault

Crossplane needs credentials to talk to Vault. This is configured via `ProviderConfig`:

```mermaid
flowchart TB
    subgraph "crossplane-system namespace"
        PC[ProviderConfig<br/>vault-admin]
        Secret[Secret<br/>vault-admin-token]
        Provider[Crossplane<br/>Vault Provider]
    end

    subgraph "Vault"
        API[Vault API]
    end

    PC -->|references| Secret
    Provider -->|reads| PC
    Provider -->|reads| Secret
    Provider -->|authenticates with token| API

    Secret -->|must contain JSON| JSON["{'token':'hvs.xxx'}"]
```

**Critical:** The secret must be in JSON format:
```json
{"token":"hvs.EXAMPLE_TOKEN_PLACEHOLDER"}
```

NOT raw format:
```
hvs.EXAMPLE_TOKEN_PLACEHOLDER
```

## The `root-token-sync` Job

This job bridges the gap between Vault's auto-initialization and Crossplane's requirements:

```mermaid
flowchart LR
    subgraph "vault namespace"
        Init[vault-init Secret<br/>root_token: hvs.xxx]
        Job[root-token-sync Job]
    end

    subgraph "crossplane-system namespace"
        Admin[vault-admin-token Secret]
    end

    Init -->|1. Read token| Job
    Job -->|2. Wrap in JSON| Job
    Job -->|3. Create secret| Admin

    Admin -->|Contains| JSON["token: {'token':'hvs.xxx'}"]
```

**What the job does:**
1. Waits for `vault-init` secret to exist (created when Vault initializes)
2. Reads the `root_token` value
3. Wraps it in JSON format: `{"token":"<value>"}`
4. Creates/updates `vault-admin-token` secret in crossplane-system

## Current Issue: Chain of Failures

```mermaid
flowchart TD
    A[root-token-sync Job<br/>not running with new code] -->|causes| B[vault-admin-token<br/>has wrong format]
    B -->|causes| C[Crossplane can't<br/>parse credentials]
    C -->|causes| D[Crossplane can't<br/>connect to Vault]
    D -->|causes| E[external-secrets-policy<br/>not created]
    E -->|causes| F[ESO has no permission<br/>for platform-data/*]
    F -->|causes| G[PushSecret fails<br/>with 403]
    G -->|causes| H[Credentials never<br/>reach Vault]
    H -->|causes| I[ExternalSecret can't<br/>pull credentials]
    I -->|causes| J[Temporal can't get<br/>database credentials]
    J -->|causes| K[Temporal pods<br/>fail to start]

    style A fill:#ff6b6b
    style K fill:#ff6b6b
```

## The Fix

Once `root-token-sync` runs with the updated code:

```mermaid
flowchart TD
    A[root-token-sync runs<br/>with JSON format code] -->|fixes| B[vault-admin-token<br/>has correct JSON format]
    B -->|enables| C[Crossplane connects<br/>to Vault]
    C -->|creates| D[external-secrets-policy<br/>in Vault]
    D -->|grants| E[ESO permission for<br/>platform-data/*]
    E -->|enables| F[PushSecret succeeds]
    F -->|stores| G[Credentials in Vault]
    G -->|enables| H[ExternalSecret pulls<br/>credentials]
    H -->|creates| I[temporal-postgres-secret]
    I -->|enables| J[Temporal pods start<br/>successfully]

    style A fill:#51cf66
    style J fill:#51cf66
```

## File Locations

| Component | File Path |
|-----------|-----------|
| Vault values | `platform/stacks/security/charts/vault/values.yaml` |
| root-token-sync Job | `platform/stacks/security/charts/vault/templates/root-token-sync.yaml` |
| Crossplane Policy CR | `platform/stacks/security/charts/vault/templates/eso/crossplane-policy.yaml` |
| ESO ClusterSecretStore | `platform/stacks/security/charts/vault/templates/eso/cluster-secret-store.yaml` |
| pg-clusters PushSecrets | `platform/stacks/platform-data/pg-clusters/templates/pushsecrets.yaml` |
| Temporal ExternalSecret | `platform/stacks/application-infra/charts/temporal/templates/external-secret.yaml` |

## Sync Wave Order

Resources are deployed in order using ArgoCD sync waves:

```
Wave 0:   ProviderConfig (vault-admin)
Wave 60:  ServiceAccount, RBAC for root-token-sync
Wave 65:  external-secrets-policy (Crossplane Policy CR)
Wave 100: root-token-sync Job (PreSync hook)
```

## Related Documentation

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Crossplane Vault Provider](https://marketplace.upbound.io/providers/upbound/provider-vault/)
