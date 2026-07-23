```
RFC-TENANT-SECURITY-0001                                         Section 3
Category: Standards Track                                     Architecture
```

# 3. Architecture

[← Requirements](./02-requirements.md) | [Index](./00-index.md#table-of-contents) | [Next: Components →](./04-components.md)

---

## 3.1 System Overview

The Tenant Application Security Architecture establishes a layered defense model for protecting applications from external threats and isolating tenants at the network layer. Traffic flows through multiple security checkpoints, each providing distinct protection capabilities.

```mermaid
flowchart TB
    subgraph Internet["INTERNET (Untrusted)"]
        Client["Client Traffic"]
    end

    subgraph EdgeLayer["EDGE LAYER"]
        LB["Load Balancer"]
    end

    subgraph SecurityLayer["SECURITY LAYER (This RFC)"]
        subgraph BunkerWebLayer["BunkerWeb"]
            TLS["TLS Termination"]
            WAF["WAF Engine<br/>(OWASP CRS)"]
            RateLimit["Rate Limiting"]
            Bot["Bot Mitigation"]
        end
    end

    subgraph NetworkLayer["NETWORK LAYER (This RFC)"]
        NetPol["Network Policies<br/>(Calico)"]
    end

    subgraph MeshLayer["MESH LAYER (RFC-WORKLOAD-IDENTITY)"]
        Mesh["Service Mesh<br/>(Linkerd mTLS)"]
    end

    subgraph AppLayer["APPLICATION LAYER"]
        subgraph Platform["Platform Services"]
            Keycloak["Keycloak"]
            Vault["Vault"]
        end
        subgraph Tenants["Tenant Namespaces"]
            TenantA["Tenant A"]
            TenantB["Tenant B"]
        end
    end

    Client --> LB
    LB --> TLS
    TLS --> WAF
    WAF --> RateLimit
    RateLimit --> Bot
    Bot --> NetPol
    NetPol --> Mesh
    Mesh --> Platform
    Mesh --> Tenants
```

---

## 3.2 Defense Layers

The architecture implements defense-in-depth through distinct security layers:

### 3.2.1 Layer Model

| Layer | Function | Failure Behavior | Enforces |
|-------|----------|------------------|----------|
| **L1: TLS** | Encryption in transit | Connection refused | INV-2 |
| **L2: WAF** | Attack signature detection | Block or log | INV-1, INV-4 |
| **L3: Rate Limiting** | Abuse prevention | Request throttled | — |
| **L4: Bot Mitigation** | Automated threat blocking | Challenge issued | — |
| **L5: Network Policy** | Namespace isolation | Traffic denied | INV-5, INV-6, INV-7 |
| **L6: Service Mesh** | Service authorization | Request rejected | RFC-WORKLOAD-IDENTITY |

### 3.2.2 Layer Independence

Each layer operates independently such that:

- Compromise of one layer does not compromise other layers
- Layers can be updated independently
- Failure of one layer does not cascade to others (where possible)
- Each layer provides distinct security value

### 3.2.3 Traffic Flow States

```mermaid
stateDiagram-v2
    [*] --> TLSHandshake
    TLSHandshake --> TLSFailed: Invalid cert/protocol
    TLSHandshake --> WAFInspection: TLS established
    TLSFailed --> [*]: Connection closed

    WAFInspection --> WAFBlocked: Attack detected
    WAFInspection --> RateLimitCheck: Request clean
    WAFBlocked --> Logged: Log event
    Logged --> [*]: 403 Forbidden

    RateLimitCheck --> Throttled: Limit exceeded
    RateLimitCheck --> BotCheck: Within limits
    Throttled --> [*]: 429 Too Many Requests

    BotCheck --> ChallengeIssued: Suspicious
    BotCheck --> NetworkPolicy: Human verified
    ChallengeIssued --> BotCheck: Challenge passed
    ChallengeIssued --> [*]: Challenge failed

    NetworkPolicy --> Denied: Policy violation
    NetworkPolicy --> ServiceMesh: Allowed
    Denied --> [*]: Connection reset

    ServiceMesh --> Application: Authorized
    Application --> [*]: Response
```

---

## 3.3 Trust Boundaries

### 3.3.1 Boundary Definitions

Trust boundaries define where security context changes and additional verification is required.

```mermaid
flowchart TB
    subgraph Untrusted["UNTRUSTED ZONE"]
        Internet["Internet"]
    end

    subgraph DMZ["DEMILITARIZED ZONE"]
        direction TB
        Ingress["BunkerWeb Ingress"]
        Note1["Trust: None<br/>Verify: Everything"]
    end

    subgraph ClusterZone["CLUSTER ZONE"]
        subgraph PlatformTrust["PLATFORM TRUST"]
            Platform["Platform Services<br/>(Keycloak, Vault, Monitoring)"]
            Note2["Trust: Platform team<br/>Verify: Workload identity"]
        end

        subgraph TenantTrust["TENANT TRUST ZONES"]
            TenantA["Tenant A Namespace"]
            TenantB["Tenant B Namespace"]
            Note3["Trust: Tenant scope only<br/>Verify: Cross-tenant requests"]
        end
    end

    Internet -->|"Boundary 1"| DMZ
    DMZ -->|"Boundary 2"| ClusterZone
    PlatformTrust -->|"Boundary 3"| TenantTrust
    TenantA x--x|"Boundary 4"| TenantB
```

### 3.3.2 Boundary Characteristics

| Boundary | From | To | Verification Required |
|----------|------|----|-----------------------|
| B1: Internet → DMZ | Untrusted | DMZ | TLS, WAF inspection |
| B2: DMZ → Cluster | DMZ | Cluster | Network policy, mesh identity |
| B3: Platform → Tenant | Platform | Tenant | Explicit policy authorization |
| B4: Tenant → Tenant | Tenant A | Tenant B | Prohibited by default (INV-6) |

### 3.3.3 Boundary Enforcement

| Boundary | Enforcement Mechanism | Invariant |
|----------|----------------------|-----------|
| B1 | BunkerWeb WAF | INV-1 |
| B2 | Kubernetes NetworkPolicy | INV-5 |
| B3 | Kubernetes NetworkPolicy | INV-6 |
| B4 | Kubernetes NetworkPolicy | INV-6 |

---

## 3.4 Authority Domains

Authority domains define who controls what aspects of the security architecture.

### 3.4.1 Domain Definitions

| Domain | Authority | Scope | Override Permitted |
|--------|-----------|-------|-------------------|
| **Global WAF Rules** | Security Team | OWASP CRS, custom rules | No |
| **WAF Exceptions** | Security Team + Tenant | Per-application exceptions | With approval |
| **Global Rate Limits** | Platform Team | Cluster-wide defaults | No |
| **Route Rate Limits** | Tenant | Per-route overrides (within bounds) | Within limits |
| **Platform Network Policies** | Platform Team | Guardrail policies | No (INV-8) |
| **Tenant Network Policies** | Tenant | Namespace-scoped policies | Yes |
| **TLS Configuration** | Platform Team | Minimum TLS version, ciphers | No |
| **Certificate Issuance** | Automated | cert-manager | N/A |

### 3.4.2 Authority Hierarchy

```mermaid
flowchart TB
    subgraph SecurityTeam["Security Team Authority"]
        WAFRules["WAF Rules<br/>(OWASP CRS + Custom)"]
        WAFExceptions["WAF Exception Approval"]
    end

    subgraph PlatformTeam["Platform Team Authority"]
        Guardrails["Guardrail Policies<br/>(Cannot be overridden)"]
        GlobalLimits["Global Rate Limits"]
        TLSConfig["TLS Configuration"]
    end

    subgraph Automated["Automated Authority"]
        CertManager["Certificate Issuance"]
    end

    subgraph TenantAuthority["Tenant Authority"]
        TenantPolicies["Namespace Policies<br/>(Within guardrails)"]
        RouteLimits["Route Rate Limits<br/>(Within bounds)"]
    end

    SecurityTeam --> PlatformTeam
    PlatformTeam --> TenantAuthority
    Automated --> TenantAuthority

    WAFRules -.->|"Constrains"| WAFExceptions
    Guardrails -.->|"Constrains"| TenantPolicies
    GlobalLimits -.->|"Constrains"| RouteLimits
```

---

## 3.5 Data Flow

### 3.5.1 Inbound Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant LB as Load Balancer
    participant BW as BunkerWeb
    participant NP as Network Policy
    participant Mesh as Service Mesh
    participant App as Application

    Client->>LB: HTTPS Request
    LB->>BW: Forward request

    Note over BW: TLS Termination
    Note over BW: WAF Inspection
    Note over BW: Rate Limit Check
    Note over BW: Bot Verification

    alt WAF Block
        BW-->>Client: 403 Forbidden
    else Rate Limited
        BW-->>Client: 429 Too Many Requests
    else Bot Challenge
        BW-->>Client: Challenge Page
    else Passed
        BW->>NP: Forward to cluster
    end

    Note over NP: Network Policy Evaluation

    alt Policy Denied
        NP-->>BW: Connection Reset
        BW-->>Client: 502 Bad Gateway
    else Policy Allowed
        NP->>Mesh: Forward to mesh
    end

    Note over Mesh: mTLS + Authorization

    Mesh->>App: Authorized Request
    App->>Mesh: Response
    Mesh->>NP: Response
    NP->>BW: Response
    BW->>LB: Response
    LB->>Client: Response
```

### 3.5.2 Cross-Namespace Request Flow

```mermaid
sequenceDiagram
    participant PodA as Pod in Namespace A
    participant NP as Network Policy
    participant Mesh as Service Mesh
    participant PodB as Pod in Namespace B

    PodA->>NP: Request to Namespace B

    Note over NP: Evaluate egress policy (Namespace A)
    Note over NP: Evaluate ingress policy (Namespace B)

    alt Either Policy Denies
        NP-->>PodA: Connection Reset
    else Both Policies Allow
        NP->>Mesh: Forward request
        Note over Mesh: mTLS verification
        Note over Mesh: Authorization check
        Mesh->>PodB: Authorized request
        PodB->>Mesh: Response
        Mesh->>NP: Response
        NP->>PodA: Response
    end
```

---

## 3.6 Integration Architecture

### 3.6.1 RFC Integration Points

```mermaid
flowchart LR
    subgraph ThisRFC["RFC-TENANT-SECURITY"]
        BunkerWeb["BunkerWeb"]
        NetPol["Network Policies"]
    end

    subgraph IAM["RFC-IAM-0001"]
        Keycloak["Keycloak"]
    end

    subgraph SecOps["RFC-SECOPS-0001"]
        Vault["Vault"]
        ESO["External Secrets"]
    end

    subgraph WorkloadID["RFC-WORKLOAD-IDENTITY"]
        Linkerd["Linkerd"]
    end

    subgraph CertMgr["Certificate Management"]
        CM["cert-manager"]
    end

    BunkerWeb -->|"WAF exceptions for auth"| Keycloak
    ESO -->|"TLS secrets"| BunkerWeb
    Vault -->|"Certificate storage"| ESO
    CM -->|"Let's Encrypt certs"| BunkerWeb
    BunkerWeb -->|"Forwards to mesh"| Linkerd
    NetPol -->|"Controls traffic to"| Linkerd
```

### 3.6.2 Integration Contracts

| Integration | This RFC Provides | Other RFC Provides |
|-------------|-------------------|-------------------|
| RFC-IAM-0001 | WAF exceptions for Keycloak endpoints | Authentication patterns |
| RFC-SECOPS-0001 | Secret references for TLS | TLS certificates via ESO |
| RFC-WORKLOAD-IDENTITY | Filtered traffic to mesh | mTLS for service traffic |

---

## 3.7 Failure Modes

### 3.7.1 Component Failure Behavior

| Component | Failure Mode | System Behavior | Recovery |
|-----------|--------------|-----------------|----------|
| BunkerWeb | Crash | Traffic blocked at LB | Pod restart |
| BunkerWeb | WAF overload | Degraded inspection | Scale out |
| Network Policy | Misconfiguration | Traffic denied | GitOps rollback |
| cert-manager | Certificate expiry | TLS handshake failure | Manual intervention |
| Calico | CNI failure | All traffic blocked | Node restart |

### 3.7.2 Degraded Operation Modes

| Mode | Trigger | Behavior | Risk |
|------|---------|----------|------|
| WAF Detection Only | High false positives | Log but don't block | Attacks not blocked |
| Rate Limit Bypass | Legitimate traffic spike | Increase limits | Abuse possible |
| Emergency Bypass | Critical outage | Direct to mesh | Full WAF bypass |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 2. Requirements](./02-requirements.md) | [Table of Contents](./00-index.md#table-of-contents) | [4. Components →](./04-components.md) |

---

*End of Section 3 — RFC-TENANT-SECURITY-0001*
