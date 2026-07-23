```
RFC-WORKLOAD-IDENTITY-0001                                      Section 3
Category: Standards Track                                    Architecture
```

# 3. Architecture

[← Previous: Requirements](./02-requirements.md) | [Index](./00-index.md#table-of-contents) | [Next: Components →](./04-components.md)

---

## 3.1 Identity Hierarchy

### 3.1.1 Enterprise Identity Model

Workload identity exists within the broader enterprise identity hierarchy:

```mermaid
flowchart TB
    subgraph Enterprise["Enterprise Identity Ceiling"]
        AAD[Azure AD / Entra ID]
    end

    subgraph Human["Human Identity (RFC-IAM-0001)"]
        KC[Keycloak]
        Apps[Platform Apps]
    end

    subgraph Workload["Workload Identity (This RFC)"]
        SPIRE[SPIRE Server]
        Cloud[Cloud Providers]
        Services[Service-to-Service]
    end

    subgraph PAM["Privileged Access (RFC-PAM-0001)"]
        Teleport[Teleport]
        Infra[Infrastructure]
    end

    AAD --> KC
    AAD --> Cloud
    KC --> Apps
    Cloud --> SPIRE
    SPIRE --> Services
    KC --> Teleport
    SPIRE --> Teleport
    Teleport --> Infra
```

### 3.1.2 Authorization Ceiling Principle

Per RFC-IAM-0001, Azure AD establishes the **authorization ceiling**:

| Level | Authority | Constraint |
|-------|-----------|------------|
| **Azure AD** | Ultimate source of truth | Defines maximum possible permissions |
| **SPIRE** | Workload identity issuer | Can only issue identities for registered workloads |
| **Vault** | Credential authority | Policies bounded by workload identity |
| **Application** | Resource access | Bounded by Vault-issued credentials |

A workload's permissions can never exceed what Azure AD allows for its organizational context.

### 3.1.3 Identity Layers

The architecture operates across multiple identity layers:

```mermaid
flowchart TB
    subgraph L1["Layer 1: Platform Identity"]
        K8s[Kubernetes ServiceAccount]
        Cloud[Cloud Instance Identity]
        Attest[Attestation Data]
    end

    subgraph L2["Layer 2: SPIFFE Identity"]
        SVID[SPIFFE SVID]
        SpiffeID[SPIFFE ID]
    end

    subgraph L3["Layer 3: Access Credentials"]
        VaultToken[Vault Token]
        DBCred[Database Credential]
        CloudCred[Cloud STS Token]
    end

    subgraph L4["Layer 4: Service Mesh Identity"]
        mTLS[mTLS Certificate]
        Proxy[Sidecar Proxy]
    end

    K8s --> SVID
    Cloud --> SVID
    Attest --> SVID
    SVID --> VaultToken
    VaultToken --> DBCred
    VaultToken --> CloudCred
    SVID --> mTLS
    mTLS --> Proxy
```

---

## 3.2 Trust Boundaries

### 3.2.1 Trust Boundary Definitions

| Boundary | Meaning | Crossing Requires |
|----------|---------|-------------------|
| **Cluster Boundary** | Different Kubernetes clusters | SPIFFE federation |
| **Cloud Boundary** | Different cloud providers | Workload identity federation |
| **Namespace Boundary** | Different Kubernetes namespaces | RBAC, Vault policy |
| **Service Mesh Boundary** | Mesh vs non-mesh traffic | mTLS termination, AuthorizationPolicy |
| **Organizational Boundary** | Different organizations/tenants | Trust bundle exchange |

### 3.2.2 Trust Boundary Diagram

```mermaid
flowchart TB
    subgraph OrgBoundary["Organizational Boundary"]
        subgraph Cloud1["Cloud: AWS"]
            subgraph Cluster1["Cluster: Production"]
                subgraph NS1["Namespace: app-team-a"]
                    Pod1[Pod A]
                end
                subgraph NS2["Namespace: app-team-b"]
                    Pod2[Pod B]
                end
            end
            subgraph Cluster2["Cluster: Staging"]
                Pod3[Pod C]
            end
        end
        subgraph Cloud2["Cloud: On-Premises"]
            subgraph Cluster3["Cluster: Edge"]
                Pod4[Pod D]
            end
        end
    end

    Pod1 -->|Namespace Policy| Pod2
    Pod1 -->|SPIFFE Federation| Pod3
    Pod3 -->|Cross-Cloud Federation| Pod4
```

### 3.2.3 Trust Establishment

| Boundary Type | Trust Mechanism |
|---------------|-----------------|
| Within cluster | Kubernetes RBAC + Service mesh |
| Cross-cluster (same cloud) | SPIFFE federation + VPN/private link |
| Cross-cloud | SPIFFE federation + mTLS over public network |
| External partners | SPIFFE trust bundle exchange + firewall rules |

---

## 3.3 Authority Domains

### 3.3.1 Identity Authorities

Each authority is responsible for a specific identity domain:

| Authority | Domain | Issues |
|-----------|--------|--------|
| **SPIRE** | Workload identity | SPIFFE SVIDs (X.509 + JWT) |
| **Kubernetes** | Pod identity | ServiceAccount tokens |
| **Cloud Provider** | Instance identity | Instance metadata, STS tokens |
| **Vault** | Access credentials | Database creds, cloud creds, PKI certs |
| **Linkerd** | Network identity | mTLS certificates |

### 3.3.2 Authority Relationships

```mermaid
flowchart LR
    subgraph Platform["Platform Authorities"]
        K8s[Kubernetes]
        Cloud[Cloud Provider]
    end

    subgraph Identity["Identity Authority"]
        SPIRE[SPIRE Server]
    end

    subgraph Credentials["Credential Authority"]
        Vault[HashiCorp Vault]
    end

    subgraph Network["Network Authority"]
        Linkerd[Linkerd]
    end

    K8s -->|Attests| SPIRE
    Cloud -->|Attests| SPIRE
    SPIRE -->|Authenticates| Vault
    SPIRE -->|Issues Certs| Linkerd
    Vault -->|Issues Creds| Apps[Applications]
```

### 3.3.3 Authority Delegation

| Delegating Authority | Receiving Authority | Delegation |
|---------------------|---------------------|------------|
| SPIRE | Vault | SPIFFE auth method authentication |
| SPIRE | Linkerd | Trust anchor for mTLS |
| Kubernetes | SPIRE | Pod attestation data |
| Cloud | SPIRE | Instance attestation data |
| Vault | ESO | Secret distribution to Kubernetes |

---

## 3.4 Data Flow Models

### 3.4.1 Workload Bootstrap Flow

```mermaid
sequenceDiagram
    participant Pod as Workload Pod
    participant Agent as SPIRE Agent
    participant Server as SPIRE Server
    participant Vault as HashiCorp Vault

    Note over Pod: Pod starts with ServiceAccount

    Pod->>Agent: Request SVID
    Agent->>Agent: Attest pod (labels, SA, namespace)
    Agent->>Server: Attest & request SVID
    Server->>Server: Validate attestation
    Server->>Agent: Issue SVID (X.509)
    Agent->>Pod: Deliver SVID

    Note over Pod: Pod now has SPIFFE identity

    Pod->>Vault: Authenticate (Kubernetes auth)
    Vault->>Vault: Validate SA token
    Vault->>Pod: Issue Vault token

    Note over Pod: Pod can now access secrets
```

### 3.4.2 Service-to-Service Flow

```mermaid
sequenceDiagram
    participant ClientPod as Client Pod
    participant ClientProxy as Client Proxy
    participant ServerProxy as Server Proxy
    participant ServerPod as Server Pod

    Note over ClientPod,ServerPod: Both have SPIFFE SVIDs

    ClientPod->>ClientProxy: HTTP request
    ClientProxy->>ClientProxy: Attach client SVID
    ClientProxy->>ServerProxy: mTLS connection
    ServerProxy->>ServerProxy: Verify client SVID
    ServerProxy->>ServerProxy: Check AuthorizationPolicy
    ServerProxy->>ServerPod: Forward request
    ServerPod->>ServerProxy: Response
    ServerProxy->>ClientProxy: Response
    ClientProxy->>ClientPod: Response
```

### 3.4.3 CI/CD Identity Flow

```mermaid
sequenceDiagram
    participant GHA as GitHub Actions
    participant OIDC as GitHub OIDC
    participant Cloud as Cloud Provider
    participant Vault as HashiCorp Vault

    Note over GHA: Pipeline runs

    GHA->>OIDC: Request OIDC token
    OIDC->>GHA: JWT (repo, workflow, branch claims)

    GHA->>Cloud: AssumeRoleWithWebIdentity
    Cloud->>Cloud: Validate JWT claims
    Cloud->>GHA: Temporary credentials

    GHA->>Vault: Authenticate (JWT auth)
    Vault->>Vault: Validate JWT claims
    Vault->>GHA: Vault token

    Note over GHA: Pipeline can access cloud + secrets
```

### 3.4.4 AI Agent Delegation Flow

```mermaid
sequenceDiagram
    participant Human as Human User
    participant Keycloak as Keycloak
    participant Agent as AI Agent
    participant Vault as HashiCorp Vault
    participant Resource as Resource

    Human->>Keycloak: Authenticate
    Keycloak->>Human: Access token

    Human->>Agent: Delegate task
    Agent->>Keycloak: Token Exchange (RFC 8693)
    Note over Keycloak: actor: agent, subject: human
    Keycloak->>Agent: Delegation token

    Agent->>Vault: Authenticate with delegation token
    Vault->>Vault: Extract delegation chain
    Vault->>Agent: Scoped Vault token

    Agent->>Resource: Access (with delegation context)
    Resource->>Resource: Log: agent acted for human
```

---

## 3.5 Integration Architecture

### 3.5.1 Integration with RFC-IAM-0001

| Integration Point | Description |
|------------------|-------------|
| **Authorization Ceiling** | Workload permissions bounded by Azure AD context |
| **Keycloak Groups** | Vault policies may reference Keycloak group for delegation |
| **Token Exchange** | AI agents use Keycloak for OAuth 2.0 Token Exchange |
| **Audit Correlation** | Human and workload actions share correlation IDs |

### 3.5.2 Integration with RFC-SECOPS-0001

| Integration Point | Description |
|------------------|-------------|
| **Vault as Credential Authority** | Workloads authenticate to Vault for secrets |
| **ESO Distribution** | Workload secrets distributed via ExternalSecret |
| **Dynamic Credentials** | Database, cloud credentials from Vault engines |
| **PushSecret** | Workloads may push generated credentials to Vault |

### 3.5.3 Integration with RFC-PAM-0001

| Integration Point | Description |
|------------------|-------------|
| **Teleport Machine ID** | VMs use Teleport tbot for machine identity |
| **Shared Vault** | Same Vault SSH/database engines |
| **Audit Convergence** | Machine and human sessions in same audit system |

### 3.5.4 Integration Diagram

```mermaid
flowchart TB
    subgraph IAM["RFC-IAM-0001"]
        AAD[Azure AD]
        KC[Keycloak]
    end

    subgraph SecOps["RFC-SECOPS-0001"]
        Vault[Vault]
        ESO[ESO]
    end

    subgraph PAM["RFC-PAM-0001"]
        Teleport[Teleport]
    end

    subgraph WI["This RFC"]
        SPIRE[SPIRE]
        Linkerd[Linkerd]
    end

    subgraph Workloads["Workloads"]
        K8s[Kubernetes Pods]
        CICD[CI/CD Pipelines]
        Agents[AI Agents]
        VMs[VMs/Machines]
    end

    AAD --> KC
    KC --> Agents
    SPIRE --> K8s
    SPIRE --> Vault
    SPIRE --> Linkerd
    K8s --> Vault
    CICD --> Vault
    VMs --> Teleport
    Teleport --> Vault
    Vault --> ESO
    ESO --> K8s
```

---

## 3.6 Security Model

### 3.6.1 Defense in Depth

| Layer | Control | Failure Mode |
|-------|---------|--------------|
| **Identity** | SPIFFE attestation | Impersonation prevented |
| **Authentication** | Short-lived credentials | Credential theft limited |
| **Authorization** | Namespace-scoped policies | Lateral movement limited |
| **Network** | mTLS + AuthorizationPolicy | Traffic interception prevented |
| **Audit** | Immutable, correlated logs | Investigations enabled |

### 3.6.2 Threat Model

| Threat | Mitigation |
|--------|------------|
| **Credential theft** | Short TTL (≤24h), automatic rotation |
| **Workload impersonation** | Attestation-based identity |
| **Privilege escalation** | Authorization ceiling enforcement |
| **Lateral movement** | Namespace isolation, mTLS |
| **Insider threat** | Delegation audit, correlation IDs |
| **Supply chain attack** | Binary attestation (future) |

### 3.6.3 Zero Trust Alignment

This architecture aligns with NIST SP 800-207 Zero Trust principles:

| Principle | Implementation |
|-----------|----------------|
| **All resources secured** | mTLS for all service traffic |
| **Least privilege** | Namespace-scoped, short-lived access |
| **Never trust, always verify** | Every request requires valid identity |
| **Assume breach** | Defense in depth, audit everything |
| **Continuous validation** | SVIDs rotate, tokens renew |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 2. Requirements](./02-requirements.md) | [Table of Contents](./00-index.md#table-of-contents) | [4. Components →](./04-components.md) |

---

*End of Section 3 — RFC-WORKLOAD-IDENTITY-0001*
