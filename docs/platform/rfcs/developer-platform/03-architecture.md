```
RFC-DEVELOPER-PLATFORM-0001                                       Section 3
Category: Standards Track                                     Architecture
```

# 3. Architecture

[← Requirements](./02-requirements.md) | [Index](./00-index.md#table-of-contents) | [Next: Components →](./04-components.md)

---

## 3.1 System Overview

### 3.1.1 High-Level Architecture

The developer platform provides a unified interface through which developers interact with platform capabilities. The architecture positions Backstage as the central portal, integrating with identity, secrets, privileged access, and platform tools.

```mermaid
flowchart TB
    subgraph Users["Users"]
        Dev["Developer"]
    end

    subgraph Edge["Edge Layer"]
        WAF["BunkerWeb<br/>(RFC-TENANT-SECURITY)"]
    end

    subgraph Portal["Developer Portal"]
        BS_FE["Backstage Frontend"]
        BS_BE["Backstage Backend"]
        BS_DB["PostgreSQL"]
    end

    subgraph Identity["Identity Layer"]
        KC["Keycloak<br/>(RFC-IAM-0001)"]
    end

    subgraph Secrets["Secrets Layer"]
        Vault["Vault<br/>(RFC-SECOPS-0001)"]
        ESO["ESO"]
    end

    subgraph PAM["Privileged Access"]
        Teleport["Teleport<br/>(RFC-PAM-0001)"]
    end

    subgraph GitOps["GitOps Layer"]
        Git["Git Repository"]
        ArgoCD["ArgoCD"]
        Crossplane["Crossplane"]
    end

    subgraph Platform["Platform Tools"]
        Grafana["Grafana"]
        Harbor["Harbor"]
        KafkaUI["Kafka UI"]
        Kargo["Kargo"]
    end

    Dev -->|HTTPS| WAF
    WAF --> BS_FE
    BS_FE --> BS_BE
    BS_BE --> BS_DB
    BS_BE -->|OIDC| KC
    ESO -->|Secrets| BS_BE
    ESO --> Vault
    BS_BE -->|Access Requests| Teleport
    BS_BE -->|Git Commits| Git
    Git --> ArgoCD
    ArgoCD --> Crossplane
    BS_BE -->|Status, Links| Platform
```

### 3.1.2 Architectural Principles

| Principle | Implementation |
|-----------|----------------|
| Unified interface | Single portal for all developer interactions |
| Capability-based | Users see only what they can do |
| GitOps-first | All changes through Git |
| Integration over reimplementation | Portal links to specialized tools |
| Convention over configuration | Golden path templates |

### 3.1.3 Layered Architecture

| Layer | Components | Responsibility |
|-------|------------|----------------|
| Presentation | Backstage Frontend | User interface, navigation |
| API | Backstage Backend | Business logic, integrations |
| Identity | Keycloak | Authentication, authorization claims |
| Secrets | Vault, ESO | Credential management |
| GitOps | ArgoCD, Crossplane | Infrastructure reconciliation |
| Platform | Various tools | Specialized capabilities |

---

## 3.2 Trust Boundaries

### 3.2.1 Trust Boundary Diagram

```mermaid
flowchart TB
    subgraph Internet["UNTRUSTED ZONE"]
        User["Developer Browser"]
    end

    subgraph EdgeLayer["EDGE LAYER (RFC-TENANT-SECURITY)"]
        WAF["BunkerWeb WAF"]
    end

    subgraph PortalZone["DEVELOPER PORTAL ZONE"]
        subgraph BackstageNS["backstage namespace"]
            BS_FE["Frontend"]
            BS_BE["Backend"]
            BS_DB["PostgreSQL"]
        end
    end

    subgraph IdentityZone["IDENTITY ZONE (RFC-IAM-0001)"]
        KC["Keycloak"]
        AAD["Azure AD"]
    end

    subgraph SecretsZone["SECRETS ZONE (RFC-SECOPS-0001)"]
        Vault["Vault"]
        ESO["External Secrets Operator"]
    end

    subgraph PAMZone["PAM ZONE (RFC-PAM-0001)"]
        Teleport["Teleport"]
    end

    subgraph PlatformZone["PLATFORM TOOLS ZONE"]
        ArgoCD["ArgoCD"]
        Grafana["Grafana"]
        Harbor["Harbor"]
        KafkaUI["Kafka UI"]
    end

    subgraph DataZone["DATA PLANE"]
        Crossplane["Crossplane"]
        Databases["Database Operators"]
        Kafka["Kafka Cluster"]
    end

    User -->|"B1: HTTPS/TLS"| WAF
    WAF -->|"B2: Validated Request"| BS_FE
    BS_FE -->|"B3: API Call"| BS_BE
    BS_BE -->|"B4: OIDC Auth"| KC
    KC -->|"B5: Federation"| AAD
    ESO -->|"B6: K8s Auth"| Vault
    ESO -->|"B7: Secret Sync"| BS_BE
    BS_BE -->|"B8: Access Request"| Teleport
    BS_BE -->|"B9: Status Query"| PlatformZone
    BS_BE -->|"B10: Git Commit"| DataZone
```

### 3.2.2 Trust Boundary Definitions

| Boundary | From | To | Verification | Supporting Invariant |
|----------|------|----|--------------|--------------------|
| B1 | Internet | WAF | TLS termination, WAF inspection | — |
| B2 | WAF | Backstage | Request validated, sanitized | INV-15 |
| B3 | Frontend | Backend | Session token validation | INV-1 |
| B4 | Backstage | Keycloak | OIDC protocol validation | INV-1, INV-3 |
| B5 | Keycloak | Azure AD | OIDC federation | RFC-IAM-0001 INV-1 |
| B6 | ESO | Vault | Kubernetes ServiceAccount auth | RFC-SECOPS-0001 |
| B7 | Vault | Backstage | Kubernetes Secret delivery | INV-9 |
| B8 | Backstage | Teleport | API token, user context | INV-13 |
| B9 | Backstage | Platform Tools | ServiceAccount, user token | INV-10 |
| B10 | Backstage | Data Plane | Git commit (GitOps) | INV-4 |

### 3.2.3 Security Zones

| Zone | Trust Level | Access Pattern |
|------|-------------|----------------|
| Internet | Untrusted | WAF-filtered entry |
| Edge Layer | Perimeter | Request validation, rate limiting |
| Portal Zone | Platform | Authenticated users only |
| Identity Zone | Critical | Keycloak, Azure AD |
| Secrets Zone | Critical | Vault, ESO |
| PAM Zone | Critical | Teleport for privileged access |
| Platform Zone | Platform | Tool-specific authorization |
| Data Zone | Platform | Operator-managed resources |

---

## 3.3 Authority Domains

### 3.3.1 Authority Hierarchy

```mermaid
flowchart TB
    subgraph Enterprise["Enterprise Authority"]
        AAD["Azure AD<br/>Groups, Policies"]
    end

    subgraph Platform["Platform Authority"]
        KC["Keycloak<br/>Roles, Clients"]
        Vault["Vault<br/>Secrets, Policies"]
    end

    subgraph Portal["Portal Authority"]
        BS["Backstage<br/>Catalog, Templates"]
    end

    subgraph Team["Team Authority"]
        Owner["Entity Owners<br/>Metadata, Docs"]
    end

    AAD -->|"Ceiling"| KC
    KC -->|"Claims"| BS
    Vault -->|"Secrets"| BS
    BS -->|"Ownership"| Owner
```

### 3.3.2 Authority Responsibilities

| Authority | Governs | Examples |
|-----------|---------|----------|
| Enterprise (Azure AD) | User identity, group membership, enterprise policy | Who exists, org structure |
| Platform Identity (Keycloak) | Role mapping, token claims, client configuration | What roles exist, claim structure |
| Platform Secrets (Vault) | Secret storage, rotation, access policy | Credential lifecycle |
| Portal Configuration | Catalog structure, templates, plugins | What appears in portal |
| Entity Owners | Entity metadata, documentation | Service descriptions, runbooks |

### 3.3.3 Authority Boundaries

| Decision | Authority | This RFC's Role |
|----------|-----------|-----------------|
| User can authenticate | Keycloak + Azure AD | Consume authentication |
| User can access feature | Keycloak claims | Interpret claims |
| Template can be used | Portal configuration | Define template permissions |
| Entity can be modified | Entity ownership | Enforce ownership check |
| Secret can be accessed | Vault policy | Request secret delivery |

---

## 3.4 Data Flow Model

### 3.4.1 Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant Backstage
    participant Keycloak
    participant AzureAD

    User->>Backstage: Access portal
    Backstage->>User: Redirect to Keycloak
    User->>Keycloak: Login request
    Keycloak->>AzureAD: Federated auth
    AzureAD->>Keycloak: Identity + groups
    Keycloak->>User: Authorization code
    User->>Backstage: Code exchange
    Backstage->>Keycloak: Token request
    Keycloak->>Backstage: ID + Access tokens
    Backstage->>User: Authenticated session
```

### 3.4.2 Self-Service Provisioning Flow

```mermaid
sequenceDiagram
    participant User
    participant Backstage
    participant Git
    participant ArgoCD
    participant Crossplane
    participant Operator

    User->>Backstage: Execute template
    Backstage->>Backstage: Validate permissions
    Backstage->>Backstage: Generate resources
    Backstage->>Git: Commit resources
    Git->>ArgoCD: Webhook notification
    ArgoCD->>ArgoCD: Sync application
    ArgoCD->>Crossplane: Apply claim
    Crossplane->>Operator: Create resource
    Operator->>Backstage: Status update (catalog)
```

### 3.4.3 JIT Access Request Flow

```mermaid
sequenceDiagram
    participant User
    participant Backstage
    participant Teleport
    participant Approver
    participant Target

    User->>Backstage: Request access
    Backstage->>Teleport: Create access request
    Teleport->>Approver: Notification
    Approver->>Teleport: Approve request
    Teleport->>User: Certificate issued
    User->>Target: Access with certificate
    Target->>Teleport: Session recorded
```

---

## 3.5 Integration Architecture

### 3.5.1 RFC Integration Points

| RFC | Integration Method | Data Exchanged |
|-----|-------------------|----------------|
| RFC-IAM-0001 | OIDC client | Authentication, token claims |
| RFC-SECOPS-0001 | ESO/ExternalSecret | Portal secrets, plugin credentials |
| RFC-PAM-0001 | Teleport API | Access requests, session links |
| RFC-TENANT-SECURITY | Network policy | Namespace isolation |

### 3.5.2 Platform Tool Integration

| Tool | Integration Pattern | Data Flow |
|------|---------------------|-----------|
| ArgoCD | REST API | Application status, sync actions |
| Grafana | HTTP API, iframes | Dashboard links, embedded views |
| Harbor | REST API | Image status, vulnerability data |
| Kafka UI | URL templates | Topic links |
| Crossplane | Kubernetes API | Resource status |

### 3.5.3 Integration Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| API polling | Status retrieval | ArgoCD sync status |
| Kubernetes watch | Resource status | Crossplane claim status |
| URL templates | Deep linking | Grafana dashboard links |
| Event webhooks | Notifications | GitHub events |
| Git commits | GitOps output | Template scaffolding |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 2. Requirements](./02-requirements.md) | [Table of Contents](./00-index.md#table-of-contents) | [4. Components →](./04-components.md) |

---

*End of Section 3 — RFC-DEVELOPER-PLATFORM-0001*
