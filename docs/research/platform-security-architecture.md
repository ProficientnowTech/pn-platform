# Platform Security Architecture

## Centralized Authentication & Authorization
### Azure AD → Keycloak → Platform Components

**ProficientNow Infrastructure Team**  
*January 2026*

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Security Architecture Overview](#security-architecture-overview)
3. [Azure AD Configuration](#azure-ad-configuration)
4. [Keycloak Realm Configuration](#keycloak-realm-configuration)
5. [Role-Based Access Control Model](#role-based-access-control-model)
6. [Component OIDC Configuration](#component-oidc-configuration)
7. [Security Tools Architecture](#security-tools-architecture)
8. [Kubernetes RBAC Integration](#kubernetes-rbac-integration)
9. [Implementation Plan](#implementation-plan)
10. [Appendices](#appendices)

---

## Executive Summary

This document defines the comprehensive security architecture for the ProficientNow platform, establishing **Azure AD as the authoritative identity source** with **Keycloak as the central identity broker**. The architecture ensures zero-trust authentication across all 15+ platform components while maintaining fine-grained role-based access control (RBAC) for diverse user personas.

### Key Objectives

- **Single source of identity truth**: Azure AD manages all user lifecycle operations
- **Centralized authentication**: Keycloak federates identity to all platform components via OIDC
- **Role-based authorization**: Seven distinct platform roles mapped to Azure AD groups
- **Runtime security**: Falco, Falco-Talon, and Kyverno provide defense-in-depth
- **Zero manual user management**: Users auto-provisioned through group membership sync

### Scope

This architecture covers authentication and authorization for:

| Category | Components |
|----------|------------|
| GitOps & Deployment | ArgoCD, Kargo, Argo Rollouts |
| Observability | Grafana, OneUptime |
| Security | Vault, Keycloak Admin, Falco |
| Developer Platform | Backstage, Harbor, Verdaccio, Tekton Dashboard |
| Application Infrastructure | Temporal, KubeVirt Manager |
| Cluster Access | Kubernetes API (kubectl) |

---

## Security Architecture Overview

### Identity Flow Architecture

The platform implements a three-tier identity architecture that separates identity source, identity broker, and service provider concerns.

```mermaid
flowchart TB
    subgraph Azure["☁️ Azure AD (Identity Source)"]
        Users[(Users)]
        Groups[(Security Groups)]
        MFA[MFA Policies]
    end

    subgraph Keycloak["🔐 Keycloak (Identity Broker)"]
        Realm[Platform Realm]
        IDP[Azure AD IDP]
        Clients[OIDC Clients]
        GroupMapper[Group Mappers]
    end

    subgraph Platform["🖥️ Platform Components"]
        ArgoCD[ArgoCD]
        Grafana[Grafana]
        Harbor[Harbor]
        Vault[Vault]
        Backstage[Backstage]
        Kargo[Kargo]
        Tekton[Tekton]
        K8s[Kubernetes API]
    end

    Users --> Groups
    Groups --> MFA
    MFA -->|OIDC Federation| IDP
    IDP --> Realm
    Realm --> GroupMapper
    GroupMapper --> Clients
    
    Clients -->|OIDC + Groups| ArgoCD
    Clients -->|OIDC + Groups| Grafana
    Clients -->|OIDC + Groups| Harbor
    Clients -->|OIDC + Groups| Vault
    Clients -->|OIDC + Groups| Backstage
    Clients -->|OIDC + Groups| Kargo
    Clients -->|OIDC + Groups| Tekton
    Clients -->|OIDC + Groups| K8s
```

### Authentication Flow Sequence

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant Component as Platform Component<br/>(ArgoCD, Grafana, etc.)
    participant Keycloak
    participant AzureAD as Azure AD

    User->>Component: Access application
    Component->>Keycloak: Redirect to /auth (OIDC)
    Keycloak->>User: Present Azure AD login option
    User->>Keycloak: Select Azure AD
    Keycloak->>AzureAD: Redirect to Azure AD
    AzureAD->>User: Authentication prompt (+ MFA)
    User->>AzureAD: Credentials + MFA
    AzureAD->>AzureAD: Validate & include group claims
    AzureAD->>Keycloak: ID Token with groups
    Keycloak->>Keycloak: Map Azure groups → Keycloak groups
    Keycloak->>Keycloak: Generate session & tokens
    Keycloak->>Component: OIDC tokens (ID + Access)
    Component->>Component: Extract groups, apply RBAC
    Component->>User: Authorized access
```

### Layer Responsibilities

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **Identity Source** | Azure AD (Entra ID) | User lifecycle, group management, MFA enforcement, identity verification |
| **Identity Broker** | Keycloak | OIDC/SAML federation, claims transformation, session management, protocol translation |
| **Service Providers** | Platform Components | OIDC client authentication, group-based RBAC, service-specific authorization |

---

## Azure AD Configuration

### Enterprise Application Setup

A single Azure AD Enterprise Application serves as the OIDC provider for Keycloak. This centralizes identity federation and simplifies certificate/secret rotation.

```mermaid
flowchart LR
    subgraph AzureAD["Azure AD Tenant"]
        App[Enterprise Application<br/>ProficientNow-Keycloak-OIDC]
        
        subgraph Groups["Security Groups"]
            Parent[PN-Tech-All]
            PlatformEng[PN-Platform-Engineers]
            DevOps[PN-DevOps-Engineers]
            TechLeads[PN-Tech-Leads]
            Devs[PN-Developers]
            Managers[PN-Engineering-Managers]
            Stakeholders[PN-Stakeholders]
        end
    end

    Parent --> PlatformEng
    Parent --> DevOps
    Parent --> TechLeads
    Parent --> Devs
    Parent --> Managers
    Parent --> Stakeholders

    App -->|Token with group claims| Keycloak[Keycloak]
```

### App Registration Configuration

| Setting | Value |
|---------|-------|
| **Application Name** | `ProficientNow-Keycloak-OIDC` |
| **Supported Account Types** | Single tenant (this organization only) |
| **Redirect URI** | `https://keycloak.pnats.cloud/realms/platform/broker/azure-ad/endpoint` |
| **ID Token Claims** | `email`, `preferred_username`, `groups`, `name` |
| **Token Configuration** | Groups claim: Security groups, emit as: Group ID |

### Azure AD Security Groups

All platform users must belong to a parent group that syncs to Keycloak. Role-specific subgroups determine authorization levels:

| Azure AD Group | Keycloak Group | Purpose |
|----------------|----------------|---------|
| `PN-Tech-All` | `/platform-users` | Parent group for all tech staff |
| `PN-Platform-Engineers` | `/platform-admins` | Full platform administration |
| `PN-DevOps-Engineers` | `/devops-engineers` | CI/CD and deployment operations |
| `PN-Tech-Leads` | `/tech-leads` | Team-scoped elevated access |
| `PN-Developers` | `/developers` | Application development access |
| `PN-Engineering-Managers` | `/engineering-managers` | Read-only dashboards and reports |
| `PN-Stakeholders` | `/stakeholders` | Business metrics visibility |

### Group Claims Configuration

In Azure AD App Registration → Token Configuration:

```json
{
  "groupMembershipClaims": "SecurityGroup",
  "optionalClaims": {
    "idToken": [
      {
        "name": "groups",
        "source": null,
        "essential": false,
        "additionalProperties": ["emit_as_roles"]
      }
    ]
  }
}
```

---

## Keycloak Realm Configuration

### Realm Structure

```mermaid
flowchart TB
    subgraph Keycloak["Keycloak Server"]
        subgraph Realm["Platform Realm"]
            IDP[Identity Provider<br/>Azure AD OIDC]
            
            subgraph ClientScopes["Client Scopes"]
                GroupScope[groups scope<br/>Group Membership Mapper]
            end
            
            subgraph Clients["OIDC Clients"]
                C1[argocd]
                C2[grafana]
                C3[harbor]
                C4[vault]
                C5[backstage]
                C6[kargo]
                C7[tekton]
                C8[kubernetes]
            end
            
            subgraph Groups["Keycloak Groups"]
                G1[/platform-admins]
                G2[/devops-engineers]
                G3[/tech-leads]
                G4[/developers]
                G5[/engineering-managers]
                G6[/stakeholders]
            end
        end
    end

    IDP -->|Group Mapping| Groups
    GroupScope --> Clients
    Groups -->|Included in tokens| Clients
```

### Realm Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Realm Name** | `platform` | Isolated from other Keycloak uses |
| **SSO Session Idle** | 30 minutes | Balance security/usability |
| **SSO Session Max** | 10 hours | Full workday coverage |
| **Access Token Lifespan** | 5 minutes | Short-lived for security |
| **Refresh Token Lifespan** | 30 minutes | Aligned with session idle |
| **User Registration** | Disabled | Managed via Azure AD |
| **Login with Email** | Enabled | Consistent with Azure AD |
| **Edit Username** | Disabled | Federated identity |

### Azure AD Identity Provider Configuration

| Configuration | Value |
|---------------|-------|
| **Alias** | `azure-ad` |
| **Display Name** | `Microsoft Azure AD` |
| **Discovery Endpoint** | `https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration` |
| **Client Authentication** | Client secret sent as post |
| **Scopes** | `openid email profile` |
| **Trust Email** | Enabled |
| **First Login Flow** | `first broker login` |
| **Sync Mode** | Force (update on every login) |

### Identity Provider Mappers

```mermaid
flowchart LR
    subgraph AzureToken["Azure AD Token"]
        email_claim[email]
        given_name[given_name]
        family_name[family_name]
        groups_claim[groups]
    end

    subgraph Mappers["IDP Mappers"]
        M1[Attribute Importer:<br/>Email]
        M2[Attribute Importer:<br/>First Name]
        M3[Attribute Importer:<br/>Last Name]
        M4[Advanced Claim to Group:<br/>Groups]
    end

    subgraph KeycloakUser["Keycloak User"]
        email_attr[email attribute]
        firstName[firstName attribute]
        lastName[lastName attribute]
        group_membership[Group Memberships]
    end

    email_claim --> M1 --> email_attr
    given_name --> M2 --> firstName
    family_name --> M3 --> lastName
    groups_claim --> M4 --> group_membership
```

### Client Scope: groups

Create a dedicated client scope named `groups` that includes group membership in tokens:

| Setting | Value |
|---------|-------|
| **Name** | `groups` |
| **Protocol** | OpenID Connect |
| **Display On Consent Screen** | Off |
| **Include In Token Scope** | On |

**Mapper Configuration:**

| Mapper Setting | Value |
|----------------|-------|
| **Mapper Type** | Group Membership |
| **Token Claim Name** | `groups` |
| **Full group path** | Disabled (use group names only) |
| **Add to ID token** | Enabled |
| **Add to access token** | Enabled |
| **Add to userinfo** | Enabled |

---

## Role-Based Access Control Model

### Platform Role Hierarchy

```mermaid
flowchart TB
    subgraph Roles["Platform Roles"]
        PA[Platform Administrator<br/>/platform-admins]
        DO[DevOps Engineer<br/>/devops-engineers]
        TL[Tech Lead<br/>/tech-leads]
        DEV[Developer<br/>/developers]
        EM[Engineering Manager<br/>/engineering-managers]
        SH[Stakeholder<br/>/stakeholders]
    end

    subgraph Access["Access Levels"]
        Full[Full Admin Access]
        Ops[Operations Access]
        Team[Team-Scoped Access]
        Dev[Development Access]
        View[View-Only Access]
        Metrics[Metrics Only]
    end

    PA --> Full
    DO --> Ops
    TL --> Team
    DEV --> Dev
    EM --> View
    SH --> Metrics

    Full -.->|includes| Ops
    Ops -.->|includes| Team
    Team -.->|includes| Dev
    Dev -.->|includes| View
```

### Role: Platform Administrator

**Keycloak Group:** `/platform-admins`  
**Description:** Full administrative access to all platform components. Reserved for Platform Engineering team members.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| ArgoCD | `role:admin` | Full cluster and application management |
| Grafana | `GrafanaAdmin` | Org administration, data source management |
| Harbor | Project Admin + System Admin | All projects |
| Vault | `admin`, `secrets-admin` policies | All paths |
| Keycloak | Realm admin | Platform realm |
| Kargo | Full management | All stages and freight |
| Kubernetes | `cluster-admin` | Cluster-wide |

### Role: DevOps Engineer

**Keycloak Group:** `/devops-engineers`  
**Description:** CI/CD pipeline management, deployment operations, and monitoring access.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| ArgoCD | `role:admin` | Assigned projects only |
| Grafana | `Admin` | Dashboard creation, alerting |
| Harbor | `Developer` | Push/pull images, create repositories |
| Vault | `secrets-read`, `ci-cd` policies | Assigned paths |
| Tekton | Full management | All pipelines and tasks |
| Kargo | Stage promotion | Assigned projects |
| Kubernetes | `edit` ClusterRole | Assigned namespaces |

### Role: Tech Lead

**Keycloak Group:** `/tech-leads`  
**Description:** Team-scoped elevated access for technical leadership responsibilities.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| ArgoCD | `role:admin` | Team projects |
| Grafana | `Editor` | Team folder access |
| Harbor | `Developer` | Team projects |
| Backstage | Entity ownership | Template execution |
| Vault | `secrets-read` | Team paths |
| Kubernetes | `edit` ClusterRole | Team namespaces |

### Role: Developer

**Keycloak Group:** `/developers`  
**Description:** Application development access with read-heavy permissions.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| ArgoCD | Read-only + sync | Dev environments only |
| Grafana | `Viewer` | Assigned dashboards |
| Harbor | Pull + dev push | Dev repositories only |
| Backstage | Component viewing | Limited templates |
| Vault | `app-secrets-read` | Assigned paths |
| Kubernetes | `view` ClusterRole | Assigned namespaces |

### Role: Engineering Manager

**Keycloak Group:** `/engineering-managers`  
**Description:** Read-only access to dashboards, metrics, and operational status.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| ArgoCD | Read-only | Application status |
| Grafana | `Viewer` | Executive dashboards |
| Backstage | Catalog browsing | No modifications |
| Kubernetes | None | Dashboards only |

### Role: Stakeholder

**Keycloak Group:** `/stakeholders`  
**Description:** Business stakeholder visibility into key metrics.

| Component | Role/Permission | Scope |
|-----------|-----------------|-------|
| Grafana | `Viewer` | Business metrics dashboards |
| OneUptime | Status page | Viewing only |

### Permission Matrix

```mermaid
flowchart LR
    subgraph Components
        A[ArgoCD]
        G[Grafana]
        H[Harbor]
        V[Vault]
        B[Backstage]
        K[Kubernetes]
    end

    subgraph Roles
        PA[Platform Admin]
        DO[DevOps]
        TL[Tech Lead]
        D[Developer]
        EM[Eng Manager]
    end

    PA -->|admin| A
    PA -->|GrafanaAdmin| G
    PA -->|system-admin| H
    PA -->|all policies| V
    PA -->|admin| B
    PA -->|cluster-admin| K

    DO -->|admin*| A
    DO -->|Admin| G
    DO -->|Developer| H
    DO -->|read+cicd| V
    DO -->|user| B
    DO -->|edit*| K

    TL -->|admin*| A
    TL -->|Editor| G
    TL -->|Developer*| H
    TL -->|read*| V
    TL -->|owner| B
    TL -->|edit*| K

    D -->|readonly+sync*| A
    D -->|Viewer| G
    D -->|pull+dev| H
    D -->|app-read| V
    D -->|viewer| B
    D -->|view*| K

    EM -->|readonly| A
    EM -->|Viewer| G
```

*Note: Asterisk (*) indicates scoped to specific projects/namespaces*

---

## Component OIDC Configuration

### ArgoCD

ArgoCD integrates directly with Keycloak OIDC without requiring Dex.

```mermaid
flowchart LR
    subgraph ArgoCD
        CM[argocd-cm<br/>ConfigMap]
        RBAC[argocd-rbac-cm<br/>ConfigMap]
        Secret[argocd-secret<br/>Secret]
    end

    subgraph Keycloak
        Client[argocd client]
        Groups[Group Claims]
    end

    Client -->|client_secret| Secret
    Client -->|OIDC config| CM
    Groups -->|group mapping| RBAC
```

**argocd-cm ConfigMap:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.pnats.cloud
  oidc.config: |
    name: Keycloak
    issuer: https://keycloak.pnats.cloud/realms/platform
    clientID: argocd
    clientSecret: $oidc.keycloak.clientSecret
    requestedScopes: ["openid", "profile", "email", "groups"]
    enablePKCEAuthentication: true
```

**argocd-rbac-cm ConfigMap:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    # Platform Admins - full access
    g, /platform-admins, role:admin
    
    # DevOps Engineers - full access
    g, /devops-engineers, role:admin
    
    # Tech Leads - read + sync for team projects
    p, role:tech-lead, applications, get, */*, allow
    p, role:tech-lead, applications, sync, */*, allow
    g, /tech-leads, role:tech-lead
    
    # Developers - read only + sync dev
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, dev/*, allow
    g, /developers, role:developer
    
    # Engineering Managers - read only
    g, /engineering-managers, role:readonly
    
  policy.default: role:readonly
  scopes: '[groups]'
```

### Grafana

Grafana uses Generic OAuth with JMESPath expressions for role mapping.

**grafana.ini configuration:**

```ini
[server]
root_url = https://grafana.pnats.cloud

[auth.generic_oauth]
enabled = true
name = Keycloak SSO
allow_sign_up = true
client_id = grafana
client_secret = ${GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET}
scopes = openid profile email groups
auth_url = https://keycloak.pnats.cloud/realms/platform/protocol/openid-connect/auth
token_url = https://keycloak.pnats.cloud/realms/platform/protocol/openid-connect/token
api_url = https://keycloak.pnats.cloud/realms/platform/protocol/openid-connect/userinfo

# Role mapping using JMESPath
role_attribute_path = contains(groups[*], '/platform-admins') && 'GrafanaAdmin' || contains(groups[*], '/devops-engineers') && 'Admin' || contains(groups[*], '/tech-leads') && 'Editor' || 'Viewer'
role_attribute_strict = true
allow_assign_grafana_admin = true

[auth]
disable_login_form = false
oauth_auto_login = false
```

### Harbor

Harbor OIDC authentication is configured via the admin UI or API.

| Setting | Value |
|---------|-------|
| **Auth Mode** | OIDC |
| **OIDC Provider Name** | Keycloak |
| **OIDC Endpoint** | `https://keycloak.pnats.cloud/realms/platform` |
| **OIDC Client ID** | `harbor` |
| **OIDC Client Secret** | (from Vault) |
| **OIDC Scope** | `openid,profile,email,groups` |
| **Group Claim Name** | `groups` |
| **OIDC Admin Group** | `/platform-admins` |
| **Automatic Onboarding** | Enabled |

**Group-to-Role Mapping in Harbor:**

| Keycloak Group | Harbor Role | Scope |
|----------------|-------------|-------|
| `/platform-admins` | System Admin | Global |
| `/devops-engineers` | Developer | All projects |
| `/tech-leads` | Developer | Team projects |
| `/developers` | Guest + Developer | Dev projects only |

### Vault

HashiCorp Vault OIDC authentication method configuration.

```mermaid
flowchart TB
    subgraph Vault["Vault Server"]
        OIDC[OIDC Auth Method]
        
        subgraph Roles["OIDC Roles"]
            R1[platform-admin]
            R2[devops]
            R3[developer]
        end
        
        subgraph Policies["Policies"]
            P1[admin]
            P2[secrets-admin]
            P3[secrets-read]
            P4[ci-cd]
            P5[app-secrets-read]
        end
    end

    OIDC --> Roles
    R1 --> P1
    R1 --> P2
    R2 --> P3
    R2 --> P4
    R3 --> P5
```

**Enable and Configure OIDC:**

```bash
# Enable OIDC auth method
vault auth enable oidc

# Configure OIDC with Keycloak
vault write auth/oidc/config \
    oidc_discovery_url="https://keycloak.pnats.cloud/realms/platform" \
    oidc_client_id="vault" \
    oidc_client_secret="$VAULT_OIDC_SECRET" \
    default_role="default"

# Create platform-admin role
vault write auth/oidc/role/platform-admin \
    user_claim="preferred_username" \
    allowed_redirect_uris="https://vault.pnats.cloud/ui/vault/auth/oidc/oidc/callback" \
    groups_claim="groups" \
    bound_claims='{"groups": ["/platform-admins"]}' \
    policies="admin,secrets-admin" \
    ttl="1h"

# Create devops role
vault write auth/oidc/role/devops \
    user_claim="preferred_username" \
    allowed_redirect_uris="https://vault.pnats.cloud/ui/vault/auth/oidc/oidc/callback" \
    groups_claim="groups" \
    bound_claims='{"groups": ["/devops-engineers"]}' \
    policies="secrets-read,ci-cd" \
    ttl="1h"

# Create developer role
vault write auth/oidc/role/developer \
    user_claim="preferred_username" \
    allowed_redirect_uris="https://vault.pnats.cloud/ui/vault/auth/oidc/oidc/callback" \
    groups_claim="groups" \
    bound_claims='{"groups": ["/developers"]}' \
    policies="app-secrets-read" \
    ttl="1h"
```

### Backstage

Backstage OIDC authentication requires custom provider configuration plus the Keycloak catalog plugin.

**app-config.yaml:**

```yaml
auth:
  environment: production
  session:
    secret: ${AUTH_SESSION_SECRET}
  providers:
    oidc:
      production:
        metadataUrl: https://keycloak.pnats.cloud/realms/platform/.well-known/openid-configuration
        clientId: backstage
        clientSecret: ${AUTH_OIDC_CLIENT_SECRET}
        scope: 'openid profile email groups'
        prompt: auto

catalog:
  providers:
    keycloakOrg:
      default:
        baseUrl: https://keycloak.pnats.cloud
        loginRealm: platform
        realm: platform
        clientId: backstage-catalog
        clientSecret: ${KEYCLOAK_CATALOG_SECRET}
        schedule:
          frequency: { hours: 1 }
          timeout: { minutes: 5 }
```

### Additional Components Summary

| Component | Client ID | Authentication Method | Notes |
|-----------|-----------|----------------------|-------|
| Kargo | `kargo` | Direct OIDC | Groups for stage promotion |
| Tekton Dashboard | `tekton` | OAuth2-proxy sidecar | Proxy handles OIDC flow |
| Argo Rollouts | `argo-rollouts` | Direct OIDC | Dashboard access |
| Verdaccio | `verdaccio` | OAuth2-proxy | htpasswd fallback for CLI |
| OneUptime | `oneuptime` | SAML or OIDC | Depends on version |
| Temporal | `temporal` | OAuth2-proxy | Web UI protection |

---

## Security Tools Architecture

### Defense-in-Depth Strategy

```mermaid
flowchart TB
    subgraph Prevention["🛡️ Prevention Layer"]
        Kyverno[Kyverno<br/>Admission Controller]
    end

    subgraph Detection["🔍 Detection Layer"]
        Falco[Falco<br/>Runtime Security]
    end

    subgraph Response["⚡ Response Layer"]
        Talon[Falco-Talon<br/>Automated Response]
    end

    subgraph Routing["📡 Event Routing"]
        Sidekick[Falco Sidekick]
    end

    subgraph Destinations["📊 Destinations"]
        Loki[Loki]
        AlertManager[AlertManager]
        Slack[Slack]
    end

    APIRequest[API Request] --> Kyverno
    Kyverno -->|Allowed| Workload[Workload]
    Kyverno -->|Denied| Rejected[Rejected]
    
    Workload --> Falco
    Falco -->|Events| Sidekick
    Sidekick --> Talon
    Sidekick --> Loki
    Sidekick --> AlertManager
    Sidekick --> Slack
    
    Talon -->|Terminate/Isolate| Workload
```

### Kyverno: Policy Enforcement

**Role:** Admission controller for policy enforcement at resource creation/modification time.

#### Key Policy Categories

```mermaid
mindmap
  root((Kyverno Policies))
    Pod Security
      Disallow privileged
      Require non-root
      Drop capabilities
      Block hostPID/hostIPC
    Resource Governance
      Require limits
      Enforce labels
      Image pull policy
    Network Security
      Require NetworkPolicy
      Block hostNetwork
      Block hostPorts
    Image Security
      Restrict registries
      Require signatures
      Block latest tag
    RBAC
      Prevent wildcards
      Enforce least privilege
```

#### Platform-Specific Policies

**require-harbor-images (ClusterPolicy):**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-harbor-images
  annotations:
    policies.kyverno.io/title: Require Harbor Registry
    policies.kyverno.io/severity: high
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: validate-image-registry
      match:
        any:
          - resources:
              kinds:
                - Pod
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system
                - rook-ceph
                - argocd
      validate:
        message: "Images must be from harbor.pnats.cloud registry"
        pattern:
          spec:
            containers:
              - image: "harbor.pnats.cloud/*"
            initContainers:
              - image: "harbor.pnats.cloud/*"
```

**disallow-latest-tag (ClusterPolicy):**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Using ':latest' tag is not allowed"
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

**enforce-network-policy (ClusterPolicy):**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: enforce-network-policy
spec:
  validationFailureAction: Audit  # Start with audit
  rules:
    - name: require-network-policy
      match:
        any:
          - resources:
              kinds:
                - Namespace
      exclude:
        any:
          - resources:
              namespaces:
                - kube-system
                - kube-public
      validate:
        message: "Namespace must have at least one NetworkPolicy"
        deny:
          conditions:
            - key: "{{ request.object.metadata.name }}"
              operator: AnyIn
              value: "{{ networkpolicies.items[].metadata.namespace }}"
```

### Falco: Runtime Threat Detection

**Role:** Kernel-level syscall monitoring for runtime anomaly and threat detection.

#### Detection Categories

| Category | Examples |
|----------|----------|
| **Privilege Escalation** | Container escape, capability abuse, ptrace |
| **File Integrity** | /etc/shadow access, k8s secrets read |
| **Network Anomalies** | Unexpected outbound, port scanning, DNS exfil |
| **Process Anomalies** | Shells in containers, crypto mining, reverse shells |
| **K8s API Abuse** | Excessive API calls, unauthorized access |

#### Custom Platform Rules

```yaml
# Vault secret access monitoring
- rule: Unauthorized Vault Agent Access
  desc: Detect non-approved processes accessing Vault agent socket
  condition: >
    open_write and 
    fd.name startswith "/vault/secrets" and
    not proc.name in (vault, vault-agent, consul-template)
  output: >
    Unauthorized Vault secret access 
    (user=%user.name command=%proc.cmdline file=%fd.name container=%container.name)
  priority: WARNING
  tags: [platform, vault, secrets]

# ArgoCD credential access
- rule: ArgoCD Repo Credentials Access
  desc: Detect access to ArgoCD repository credentials
  condition: >
    open_read and
    fd.name contains "argocd-repo-creds" and
    not proc.name in (argocd-repo-server, argocd-application-controller)
  output: >
    ArgoCD repo credentials accessed by unexpected process
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: CRITICAL
  tags: [platform, argocd, credentials]

# Harbor registry bypass
- rule: Non-Harbor Registry Pull
  desc: Detect container pulls from non-Harbor registries
  condition: >
    spawned_process and
    proc.name = "docker" and
    proc.args contains "pull" and
    not proc.args contains "harbor.pnats.cloud"
  output: >
    Docker pull from non-Harbor registry detected
    (user=%user.name command=%proc.cmdline)
  priority: WARNING
  tags: [platform, harbor, compliance]
```

### Falco-Talon: Automated Response

**Role:** Response engine that takes automated action based on Falco alerts.

```mermaid
flowchart LR
    subgraph FalcoRules["Falco Rules"]
        R1[Terminal shell in container]
        R2[Outbound C2 connection]
        R3[Crypto miner detected]
        R4[Sensitive file read]
    end

    subgraph TalonActions["Talon Actions"]
        A1[kubernetes:terminate]
        A2[kubernetes:networkpolicy]
        A3[kubernetes:labelize]
        A4[kubernetes:log]
    end

    subgraph Results["Results"]
        Pod1[Pod Terminated]
        Pod2[Pod Isolated]
        Pod3[Pod Labeled for Review]
        Pod4[Enhanced Logging]
    end

    R1 --> A1 --> Pod1
    R2 --> A2 --> Pod2
    R3 --> A3 --> Pod3
    R4 --> A4 --> Pod4
```

#### Talon Rules Configuration

```yaml
# falco-talon-rules.yaml
- action: Terminate on shell
  match:
    rules:
      - Terminal shell in container
    priority: Critical
  actions:
    - action: kubernetes:terminate
      parameters:
        grace_period_seconds: 0

- action: Isolate on C2 connection
  match:
    rules:
      - Outbound Connection to C2 Server
    priority: Critical
  actions:
    - action: kubernetes:networkpolicy
      parameters:
        allow:
          - "192.168.0.0/16"  # Internal only
    - action: slack:post
      parameters:
        channel: "#security-alerts"
        
- action: Label crypto miners
  match:
    rules:
      - Detect crypto miners
    priority: Warning
  actions:
    - action: kubernetes:labelize
      parameters:
        labels:
          security.pnats.cloud/quarantine: "true"
          security.pnats.cloud/reason: "crypto-mining"
```

---

## Kubernetes RBAC Integration

### OIDC Authentication to Kubernetes API

```mermaid
flowchart LR
    User[User with kubectl] -->|1. kubectl command| KubeLogin[kubelogin plugin]
    KubeLogin -->|2. OIDC auth request| Keycloak
    Keycloak -->|3. Redirect to Azure AD| AzureAD[Azure AD]
    AzureAD -->|4. Authenticate + MFA| User
    AzureAD -->|5. Tokens| Keycloak
    Keycloak -->|6. ID Token with groups| KubeLogin
    KubeLogin -->|7. Bearer token| APIServer[kube-apiserver]
    APIServer -->|8. Validate token| APIServer
    APIServer -->|9. Extract groups, apply RBAC| APIServer
    APIServer -->|10. Authorized response| User
```

### API Server OIDC Configuration

| Flag | Value |
|------|-------|
| `--oidc-issuer-url` | `https://keycloak.pnats.cloud/realms/platform` |
| `--oidc-client-id` | `kubernetes` |
| `--oidc-username-claim` | `preferred_username` |
| `--oidc-groups-claim` | `groups` |
| `--oidc-username-prefix` | `-` (no prefix) |
| `--oidc-groups-prefix` | `oidc:` |

### ClusterRoleBindings

```yaml
# Platform Admins - cluster-admin
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-platform-admins
subjects:
  - kind: Group
    name: "oidc:/platform-admins"
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---
# DevOps Engineers - edit in production namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: oidc-devops-edit
  namespace: production
subjects:
  - kind: Group
    name: "oidc:/devops-engineers"
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io

---
# Developers - view in application namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: oidc-developers-view
  namespace: apps
subjects:
  - kind: Group
    name: "oidc:/developers"
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
```

### kubelogin Configuration

**kubeconfig for OIDC authentication:**

```yaml
apiVersion: v1
kind: Config
clusters:
  - cluster:
      certificate-authority-data: ${CA_DATA}
      server: https://k8s.pnats.cloud:6443
    name: pn-production

contexts:
  - context:
      cluster: pn-production
      user: oidc
    name: pn-production

current-context: pn-production

users:
  - name: oidc
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: kubectl
        args:
          - oidc-login
          - get-token
          - --oidc-issuer-url=https://keycloak.pnats.cloud/realms/platform
          - --oidc-client-id=kubernetes
          - --oidc-use-pkce
        interactiveMode: IfAvailable
```

---

## Implementation Plan

### Timeline Overview

```mermaid
gantt
    title Platform Security Implementation
    dateFormat  YYYY-MM-DD
    section Phase 1: Foundation
    Azure AD Setup           :a1, 2026-01-13, 7d
    Keycloak Core            :a2, after a1, 7d
    
    section Phase 2: Core Components
    ArgoCD OIDC              :b1, after a2, 4d
    Vault OIDC               :b2, after a2, 4d
    Grafana OAuth            :b3, after b1, 3d
    Harbor OIDC              :b4, after b2, 3d
    
    section Phase 3: Extended
    Backstage                :c1, after b4, 5d
    Kargo + Tekton           :c2, after c1, 5d
    Supporting Services      :c3, after c2, 4d
    
    section Phase 4: Security Tools
    Kyverno Policies         :d1, after c3, 5d
    Falco + Talon            :d2, after d1, 5d
    
    section Phase 5: K8s OIDC
    API Server Config        :e1, after d2, 4d
    RBAC + kubelogin         :e2, after e1, 4d
    Validation               :e3, after e2, 6d
```

### Phase 1: Foundation (Week 1-2)

#### Azure AD Setup
- [ ] Create Enterprise Application `ProficientNow-Keycloak-OIDC`
- [ ] Configure group claims in token configuration
- [ ] Create security groups hierarchy (`PN-Tech-All` parent)
- [ ] Create role-specific subgroups
- [ ] Assign initial users to appropriate groups
- [ ] Document client ID and tenant ID

#### Keycloak Core
- [ ] Verify Keycloak deployment with PostgreSQL backend
- [ ] Create `platform` realm with security settings
- [ ] Configure Azure AD as OIDC identity provider
- [ ] Create identity provider mappers (email, name, groups)
- [ ] Create `groups` client scope with membership mapper
- [ ] Create Keycloak groups matching Azure AD groups
- [ ] Test end-to-end authentication flow
- [ ] Document realm configuration

### Phase 2: Core Components (Week 3-4)

#### ArgoCD
- [ ] Create `argocd` client in Keycloak
- [ ] Configure `argocd-cm` with OIDC settings
- [ ] Configure `argocd-rbac-cm` with group policies
- [ ] Store client secret in Vault
- [ ] Create ExternalSecret for client secret
- [ ] Test login and RBAC enforcement

#### Vault
- [ ] Create `vault` client in Keycloak
- [ ] Enable OIDC auth method
- [ ] Configure OIDC with Keycloak discovery URL
- [ ] Create Vault policies (admin, secrets-read, ci-cd, app-secrets-read)
- [ ] Create OIDC roles mapped to Keycloak groups
- [ ] Test login and policy enforcement

#### Grafana
- [ ] Create `grafana` client in Keycloak
- [ ] Configure Grafana OAuth settings
- [ ] Configure role_attribute_path JMESPath
- [ ] Store client secret in Vault
- [ ] Test login and role mapping

#### Harbor
- [ ] Create `harbor` client in Keycloak
- [ ] Configure OIDC in Harbor admin UI
- [ ] Set admin group to `/platform-admins`
- [ ] Configure group-to-project-role mappings
- [ ] Test login and project access

### Phase 3: Extended Components (Week 5-6)

#### Backstage
- [ ] Create `backstage` client in Keycloak
- [ ] Create `backstage-catalog` client for user sync
- [ ] Configure OIDC auth provider
- [ ] Configure Keycloak catalog plugin
- [ ] Set up user/group sync schedule
- [ ] Test login and catalog sync

#### Kargo
- [ ] Create `kargo` client in Keycloak
- [ ] Configure OIDC settings in Kargo
- [ ] Map groups to stage promotion permissions
- [ ] Test login and promotion workflows

#### Supporting Services
- [ ] Deploy OAuth2-proxy for Tekton Dashboard
- [ ] Configure Verdaccio authentication
- [ ] Set up OneUptime SSO
- [ ] Configure Temporal UI OAuth2-proxy
- [ ] Test all supporting service logins

### Phase 4: Security Tools (Week 7-8)

#### Kyverno
- [ ] Deploy Kyverno controller
- [ ] Create `require-harbor-images` policy (Audit mode)
- [ ] Create `disallow-latest-tag` policy (Audit mode)
- [ ] Create `require-labels` policy (Audit mode)
- [ ] Create `enforce-network-policy` policy (Audit mode)
- [ ] Review audit results
- [ ] Gradually enable Enforce mode
- [ ] Document exception procedures

#### Falco & Talon
- [ ] Deploy Falco with platform-specific rules
- [ ] Configure Falco Sidekick routing
- [ ] Deploy Falco-Talon
- [ ] Configure Talon response rules
- [ ] Test automated responses in non-prod
- [ ] Enable in production with monitoring
- [ ] Document incident response procedures

### Phase 5: Kubernetes OIDC (Week 9-10)

#### API Server Configuration
- [ ] Create `kubernetes` client in Keycloak (public)
- [ ] Configure kube-apiserver OIDC flags
- [ ] Restart API server with new configuration
- [ ] Verify OIDC token validation

#### RBAC & kubelogin
- [ ] Create ClusterRoleBindings for Keycloak groups
- [ ] Create namespace-scoped RoleBindings
- [ ] Install kubelogin on engineer workstations
- [ ] Distribute kubeconfig templates
- [ ] Test kubectl access for each role
- [ ] Document kubectl authentication procedure

#### Validation & Documentation
- [ ] End-to-end testing of all authentication flows
- [ ] Security review and penetration testing
- [ ] Create operational runbooks
- [ ] Create user onboarding documentation
- [ ] Training sessions for platform users

---

## Appendices

### Appendix A: Keycloak Clients Summary

| Client ID | Protocol | Access Type | Redirect URI Pattern | Default Scopes |
|-----------|----------|-------------|---------------------|----------------|
| `argocd` | OIDC | Confidential | `/auth/callback` | openid profile email groups |
| `grafana` | OIDC | Confidential | `/login/generic_oauth` | openid profile email groups |
| `harbor` | OIDC | Confidential | `/c/oidc/callback` | openid profile email groups |
| `vault` | OIDC | Confidential | `/ui/vault/auth/oidc/oidc/callback` | openid profile email groups |
| `backstage` | OIDC | Confidential | `/api/auth/oidc/handler/frame` | openid profile email groups |
| `backstage-catalog` | OIDC | Confidential | N/A (service account) | openid |
| `kargo` | OIDC | Confidential | `/auth/callback` | openid profile email groups |
| `tekton` | OIDC | Confidential | `/oauth2/callback` | openid profile email groups |
| `argo-rollouts` | OIDC | Confidential | `/auth/callback` | openid profile email groups |
| `kubernetes` | OIDC | Public | `http://localhost:8000` | openid profile email groups |

> **Note:** All clients should have the `groups` client scope added to their default scopes.

### Appendix B: Secrets Management

#### Vault Paths for Keycloak Secrets

| Vault Path | Keys | Target |
|------------|------|--------|
| `secret/platform/keycloak/clients` | `argocd-client-secret` | argocd-secret (argocd ns) |
| `secret/platform/keycloak/clients` | `grafana-client-secret` | grafana-oauth (monitoring ns) |
| `secret/platform/keycloak/clients` | `harbor-client-secret` | harbor-core (harbor ns) |
| `secret/platform/keycloak/clients` | `vault-client-secret` | vault-oidc (vault ns) |
| `secret/platform/keycloak/clients` | `backstage-client-secret` | backstage-auth (backstage ns) |
| `secret/platform/keycloak/clients` | `kargo-client-secret` | kargo-oidc (kargo ns) |
| `secret/platform/azure-ad` | `tenant-id`, `client-id`, `client-secret` | Keycloak IDP config |

#### ExternalSecret Example

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-oidc-secret
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: argocd-secret
    creationPolicy: Merge
  data:
    - secretKey: oidc.keycloak.clientSecret
      remoteRef:
        key: secret/platform/keycloak/clients
        property: argocd-client-secret
```

### Appendix C: Troubleshooting Guide

#### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Groups not in token | RBAC not working | Verify `groups` scope added to client, check mapper configuration |
| Login redirect loop | Infinite redirects | Check redirect URI matches exactly, verify client secret |
| User not created in Keycloak | First login fails | Verify Azure AD IDP sync mode is "Force" |
| Wrong role assigned | User has incorrect permissions | Check group membership in both Azure AD and Keycloak |
| Token expired | Frequent re-authentication | Adjust token lifespans in realm settings |

#### Debug Commands

```bash
# Verify Keycloak OIDC configuration
curl -s https://keycloak.pnats.cloud/realms/platform/.well-known/openid-configuration | jq

# Decode JWT token (paste token)
echo "YOUR_TOKEN" | cut -d'.' -f2 | base64 -d | jq

# Check ArgoCD OIDC config
kubectl get configmap argocd-cm -n argocd -o yaml | grep -A20 "oidc.config"

# Check Grafana OAuth status
kubectl logs -n monitoring deployment/grafana | grep -i oauth

# Verify Vault OIDC auth
vault read auth/oidc/config
vault read auth/oidc/role/platform-admin
```

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-07 | Platform Team | Initial release |

---

*This document is maintained in Git and should be updated as the security architecture evolves.*
