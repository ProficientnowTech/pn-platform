```
RFC-PAM-0001                                                    Section 3
Category: Standards Track                                    Architecture
```

# 3. Architecture

[← Previous: Requirements](./02-requirements.md) | [Index](./00-index.md#table-of-contents) | [Next: Components →](./04-components.md)

---

## 3.1 System Overview

The Privileged Access Management architecture positions Teleport as the centralized access broker for all human-to-infrastructure access. Teleport integrates with:

- **Keycloak** for user identity (per RFC-IAM-0001)
- **Vault** for credential authority (per RFC-SECOPS-0001)
- **Target resources** through Teleport agents

```mermaid
flowchart TB
    subgraph Identity["Identity Layer (RFC-IAM-0001)"]
        AAD[Azure AD]
        KC[Keycloak]
        AAD <-->|OIDC Federation| KC
    end

    subgraph PAM["Access Broker Layer (This RFC)"]
        TP[Teleport Cluster]
        TPA[Teleport Agents]
    end

    subgraph Secrets["Secrets Layer (RFC-SECOPS-0001)"]
        V[Vault]
        VSSH[SSH Engine]
        VDB[DB Engine]
        V --- VSSH
        V --- VDB
    end

    subgraph Resources["Target Resources"]
        SSH[Linux Servers]
        DB[Databases]
        K8S[Kubernetes]
        WIN[Windows Servers]
    end

    KC -->|OIDC| TP
    TP <-->|Certificate Requests| VSSH
    TP <-->|Credential Requests| VDB
    TP --> TPA
    TPA --> SSH
    TPA --> DB
    TPA --> K8S
    TPA --> WIN
```

## 3.2 Zero Direct Access Model

### 3.2.1 Model Definition

The **zero direct access** model enforces that all privileged access transits through Teleport. No direct connections are permitted from user workstations to target resources.

```mermaid
flowchart LR
    subgraph Allowed["Allowed Path"]
        U1[User] --> TP1[Teleport] --> R1[Resource]
    end

    subgraph Blocked["Blocked Path"]
        U2[User] -.->|BLOCKED| R2[Resource]
    end

    style Blocked fill:#ffcccc
    style Allowed fill:#ccffcc
```

### 3.2.2 Enforcement Mechanisms

| Resource Type | Enforcement Method |
|---------------|-------------------|
| SSH | Network policies block port 22; sshd accepts only Teleport CA certificates |
| Database | Database credentials only issued through Teleport; network policies block direct ports |
| Kubernetes | API server accessible only through Teleport proxy for exec/attach |
| RDP | Network policies block port 3389; RDP gateway through Teleport |

### 3.2.3 Benefits

| Benefit | Description |
|---------|-------------|
| **Single audit point** | All access logged in one system |
| **Consistent policy** | Same RBAC applies to all resources |
| **Simplified revocation** | Disable Teleport access = disable all access |
| **Session recording** | All sessions captured automatically |

## 3.3 Trust Hierarchy

### 3.3.1 Trust Model

Trust flows from enterprise identity through platform identity to resource access:

```mermaid
flowchart TB
    subgraph Enterprise["Enterprise Trust Domain"]
        AAD[Azure AD]
        HR[HR Systems]
        HR -->|Provisions| AAD
    end

    subgraph Platform["Platform Trust Domain"]
        KC[Keycloak]
        TP[Teleport]
        V[Vault]
        KC -->|Identity| TP
        V -->|Credentials| TP
    end

    subgraph Resource["Resource Trust Domain"]
        Agents[Teleport Agents]
        Targets[Target Resources]
        Agents -->|Manages| Targets
    end

    AAD -->|Federation| KC
    TP -->|Sessions| Agents
```

### 3.3.2 Trust Assertions

| Assertion | Meaning |
|-----------|---------|
| Azure AD asserts user identity | User is who they claim to be |
| Azure AD asserts group membership | User belongs to these organizational groups |
| Keycloak asserts platform roles | User has these platform permissions |
| Teleport asserts access rights | User can access these resources |
| Vault asserts credential validity | These credentials are authentic and current |

### 3.3.3 Trust Verification

At each layer, trust is verified before proceeding:

| Layer | Verification |
|-------|--------------|
| Keycloak → Azure AD | OIDC token signature, issuer, audience |
| Teleport → Keycloak | OIDC token signature, group claims |
| Agent → Teleport | Teleport CA certificate chain |
| Resource → Agent | Agent certificate, Teleport session token |

## 3.4 Authority Domains

### 3.4.1 Domain Responsibilities

| Domain | Authority | Controller |
|--------|-----------|------------|
| **User Identity** | Who is this person? | Azure AD (via HR) |
| **Group Membership** | What teams do they belong to? | Azure AD (via HR) |
| **Platform Roles** | What platform permissions do they have? | Keycloak (via Platform Team) |
| **Access Policies** | What resources can they access? | Teleport (via Platform Team) |
| **Credentials** | What are their authentication credentials? | Vault (via Platform Team) |
| **Resource Enrollment** | What resources are managed? | Teleport Agents (via Resource Owners) |

### 3.4.2 Authority Ceiling

The authorization ceiling principle from RFC-IAM-0001 extends to PAM:

```mermaid
flowchart TB
    subgraph Ceiling["Authorization Ceiling"]
        AAD[Azure AD Groups]
    end

    subgraph Refinement["Permission Refinement"]
        KC[Keycloak Roles]
        TP[Teleport Roles]
        KC --> TP
    end

    subgraph Access["Resource Access"]
        SSH[SSH Access]
        DB[Database Access]
        K8S[Kubernetes Access]
    end

    AAD -->|Constrains| KC
    TP --> SSH
    TP --> DB
    TP --> K8S

    style Ceiling fill:#ffeeee
```

**Example**: A user in Azure AD group `Developers` can be granted Teleport role `developer` which permits SSH to development servers. They cannot be granted Teleport role `sre-production` (which requires Azure AD group `SRE-Team`) even if an administrator attempts to assign it.

### 3.4.3 Separation of Concerns

| Concern | Managed By | System |
|---------|------------|--------|
| User lifecycle | HR/Management | Azure AD |
| Team assignment | HR/Management | Azure AD Groups |
| Platform role definitions | Platform Team | Keycloak + Teleport |
| Role-to-group mapping | Platform Team | Keycloak + Teleport |
| Resource enrollment | Resource Owners | Teleport Agents |
| Access policies | Platform Team | Teleport Roles |

## 3.5 Trust Boundaries

### 3.5.1 Boundary Definitions

```mermaid
flowchart TB
    subgraph B1["Boundary 1: Enterprise → Platform"]
        AAD[Azure AD] -->|OIDC| KC[Keycloak]
    end

    subgraph B2["Boundary 2: Identity → Access"]
        KC2[Keycloak] -->|OIDC| TP[Teleport]
    end

    subgraph B3["Boundary 3: Access → Credentials"]
        TP2[Teleport] -->|API| V[Vault]
    end

    subgraph B4["Boundary 4: Broker → Resource"]
        TP3[Teleport] -->|mTLS| Agent[Agent]
        Agent -->|Protocol| Resource[Resource]
    end
```

### 3.5.2 Boundary 1: Enterprise to Platform

| Aspect | Specification |
|--------|---------------|
| Protocol | OIDC |
| Direction | Azure AD → Keycloak |
| Trust basis | OIDC token validation |
| Crossing | User authenticates, groups synchronized |

### 3.5.3 Boundary 2: Identity to Access Broker

| Aspect | Specification |
|--------|---------------|
| Protocol | OIDC |
| Direction | Keycloak → Teleport |
| Trust basis | OIDC token with group claims |
| Crossing | User identity established, roles assigned |

### 3.5.4 Boundary 3: Access Broker to Credential Authority

| Aspect | Specification |
|--------|---------------|
| Protocol | Vault API (HTTPS) |
| Direction | Teleport → Vault |
| Trust basis | Vault token (Kubernetes auth) |
| Crossing | Credentials requested and issued |

### 3.5.5 Boundary 4: Access Broker to Target Resource

| Aspect | Specification |
|--------|---------------|
| Protocol | mTLS (Teleport protocol) |
| Direction | Teleport ↔ Agent |
| Trust basis | Teleport CA certificates |
| Crossing | Session established, commands proxied |

## 3.6 Data Flow Model

### 3.6.1 Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant TP as Teleport
    participant KC as Keycloak
    participant AAD as Azure AD

    U->>TP: Access Teleport
    TP->>KC: Redirect to Keycloak
    KC->>AAD: Redirect to Azure AD
    U->>AAD: Authenticate (MFA)
    AAD->>KC: ID Token
    KC->>KC: Map groups to roles
    KC->>TP: Access Token with claims
    TP->>TP: Create Teleport session
    TP->>U: Session established
```

### 3.6.2 SSH Access Flow

```mermaid
sequenceDiagram
    participant U as User
    participant TP as Teleport
    participant V as Vault
    participant A as Agent
    participant H as Host

    U->>TP: Request SSH to host
    TP->>TP: Check RBAC
    TP->>V: Request SSH certificate
    V->>V: Sign certificate (SSH CA)
    V->>TP: Return certificate
    TP->>A: Establish session
    A->>H: SSH with certificate
    H->>H: Validate certificate
    H->>A: Session established
    A->>TP: Session proxied
    TP->>TP: Record session
    TP->>U: Interactive session
```

### 3.6.3 Database Access Flow

```mermaid
sequenceDiagram
    participant U as User
    participant TP as Teleport
    participant V as Vault
    participant A as Agent
    participant DB as Database

    U->>TP: Request database access
    TP->>TP: Check RBAC
    TP->>V: Request DB credentials
    V->>DB: Create ephemeral user
    V->>TP: Return credentials
    TP->>A: Establish session
    A->>DB: Connect with credentials
    A->>TP: Session proxied
    TP->>TP: Log queries
    TP->>U: Database session
    Note over V,DB: Credentials auto-revoked at TTL
```

### 3.6.4 Kubernetes Exec Flow

```mermaid
sequenceDiagram
    participant U as User
    participant TP as Teleport
    participant A as K8s Agent
    participant API as K8s API Server
    participant P as Pod

    U->>TP: kubectl exec request
    TP->>TP: Check RBAC (namespace, pod)
    TP->>A: Forward exec request
    A->>API: Exec API call
    API->>P: Establish exec session
    P->>A: Session stream
    A->>TP: Session proxied
    TP->>TP: Record session (eBPF)
    TP->>U: Interactive exec
```

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 2. Requirements](./02-requirements.md) | [Table of Contents](./00-index.md#table-of-contents) | [4. Components →](./04-components.md) |

---

*End of Section 3 — RFC-PAM-0001*
