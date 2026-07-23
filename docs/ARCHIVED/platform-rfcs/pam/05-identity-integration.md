```
RFC-PAM-0001                                                    Section 5
Category: Standards Track                           Identity Integration
```

# 5. Identity Integration

[← Previous: Components](./04-components.md) | [Index](./00-index.md#table-of-contents) | [Next: SSH Access →](./06-ssh-access.md)

---

## 5.1 Keycloak SSO Configuration

### 5.1.1 Integration Overview

Teleport authenticates users through Keycloak using OIDC, per RFC-IAM-0001. This establishes a single identity source for all platform access.

```mermaid
flowchart LR
    subgraph User
        U[User Browser]
    end

    subgraph Teleport
        TP[Teleport Proxy]
        Auth[Auth Service]
    end

    subgraph Keycloak
        KC[Keycloak]
        Realm[Platform Realm]
    end

    subgraph Azure
        AAD[Azure AD]
    end

    U --> TP
    TP --> Auth
    Auth -->|OIDC| KC
    KC --> Realm
    Realm -->|Federation| AAD
```

### 5.1.2 Keycloak Client Configuration

Teleport requires a Keycloak client:

| Setting | Value | Description |
|---------|-------|-------------|
| Client ID | `teleport` | Unique identifier |
| Client Protocol | `openid-connect` | OIDC authentication |
| Access Type | `confidential` | Client has a secret |
| Valid Redirect URIs | `https://teleport.example.com/v1/webapi/oidc/callback` | Callback URL |
| Client Authentication | `Client ID and Secret` | Authentication method |

### 5.1.3 Required Scopes and Claims

| Scope | Claims Included | Purpose |
|-------|-----------------|---------|
| `openid` | `sub` | User identifier |
| `profile` | `name`, `preferred_username` | Display name |
| `email` | `email` | User email |
| `groups` | `groups` | Group memberships for role mapping |

### 5.1.4 OIDC Connector Configuration

Teleport's OIDC connector references Keycloak:

| Parameter | Description |
|-----------|-------------|
| `issuer_url` | Keycloak realm URL |
| `client_id` | `teleport` |
| `client_secret` | From Vault via ESO |
| `redirect_url` | Teleport callback URL |
| `claims_to_roles` | Maps Keycloak groups to Teleport roles |

## 5.2 Group-to-Role Mapping

### 5.2.1 Mapping Strategy

Keycloak groups (derived from Azure AD) map to Teleport roles:

```mermaid
flowchart TB
    subgraph Azure["Azure AD Groups"]
        A1[Developers]
        A2[SRE-Team]
        A3[DBA-Team]
        A4[Platform-Admins]
    end

    subgraph Keycloak["Keycloak Groups"]
        K1[developers]
        K2[sre-team]
        K3[dba-team]
        K4[platform-admins]
    end

    subgraph Teleport["Teleport Roles"]
        T1[developer]
        T2[sre-oncall]
        T3[dba-oncall]
        T4[platform-admin]
    end

    A1 -->|Sync| K1
    A2 -->|Sync| K2
    A3 -->|Sync| K3
    A4 -->|Sync| K4

    K1 -->|Map| T1
    K2 -->|Map| T2
    K3 -->|Map| T3
    K4 -->|Map| T4
```

### 5.2.2 Role Mapping Table

| Azure AD Group | Keycloak Group | Teleport Role | Access Level |
|----------------|----------------|---------------|--------------|
| `Developers` | `developers` | `developer` | Non-prod SSH, K8s |
| `SRE-Team` | `sre-team` | `sre-oncall` | All SSH, K8s, prod access |
| `DBA-Team` | `dba-team` | `dba-oncall` | Database access |
| `Data-Team` | `data-team` | `data-analyst` | Read-only database |
| `Security-Team` | `security-team` | `security-analyst` | Audit log access |
| `Platform-Admins` | `platform-admins` | `platform-admin` | Full access |

### 5.2.3 Claims-to-Roles Configuration

The OIDC connector maps claims to roles:

| Claim | Value | Assigned Role |
|-------|-------|---------------|
| `groups` | contains `developers` | `developer` |
| `groups` | contains `sre-team` | `sre-oncall` |
| `groups` | contains `dba-team` | `dba-oncall` |
| `groups` | contains `platform-admins` | `platform-admin` |

Users may receive multiple roles if they belong to multiple groups.

## 5.3 Authorization Ceiling Enforcement

### 5.3.1 Ceiling Principle

Per RFC-IAM-0001 §5.1, Azure AD group membership defines the **authorization ceiling**. Teleport roles MUST NOT grant permissions exceeding this ceiling.

```mermaid
flowchart TB
    subgraph Ceiling["Azure AD Ceiling"]
        AAD[User in 'Developers' group]
    end

    subgraph Allowed["Allowed Mapping"]
        A1[developer role]
        A2[readonly role]
    end

    subgraph Blocked["Blocked Mapping"]
        B1[sre-oncall role]
        B2[platform-admin role]
    end

    AAD --> A1
    AAD --> A2
    AAD -.->|BLOCKED| B1
    AAD -.->|BLOCKED| B2

    style Blocked fill:#ffcccc
    style Allowed fill:#ccffcc
```

### 5.3.2 Enforcement Mechanism

The ceiling is enforced through:

1. **Keycloak group synchronization**: Only Azure AD groups are synchronized
2. **Claims-to-roles mapping**: Roles assigned based only on group claims
3. **No local role assignment**: Teleport does not maintain local user-role mappings

### 5.3.3 Ceiling Verification

To verify ceiling compliance:

| Check | Method |
|-------|--------|
| User's Azure AD groups | Query Azure AD or Keycloak |
| User's Teleport roles | Query Teleport for user's roles |
| Role permissions | Compare against ceiling expectation |

A user's Teleport roles MUST be a subset of what their Azure AD groups permit.

## 5.4 Token Claims for Access Decisions

### 5.4.1 Relevant Claims

Teleport uses these token claims for access decisions:

| Claim | Source | Usage |
|-------|--------|-------|
| `sub` | Keycloak | Unique user identifier |
| `preferred_username` | Keycloak | Display name in sessions |
| `email` | Azure AD (via Keycloak) | User contact, audit attribution |
| `groups` | Azure AD (via Keycloak) | Role assignment |

### 5.4.2 Session Attribution

Session recordings and audit logs include:

| Field | Source | Example |
|-------|--------|---------|
| User | `preferred_username` claim | `jane.doe` |
| Email | `email` claim | `jane.doe@example.com` |
| Roles | Derived from `groups` | `developer`, `readonly` |
| Session ID | Teleport-generated | `abc123...` |

### 5.4.3 Access Decision Flow

```mermaid
flowchart TB
    Token[OIDC Token] --> Claims[Extract Claims]
    Claims --> Groups[groups claim]
    Groups --> Roles[Map to Teleport Roles]
    Roles --> RBAC[RBAC Evaluation]
    RBAC --> Decision{Access Decision}
    Decision -->|Permitted| Allow[Allow Access]
    Decision -->|Denied| Deny[Deny Access]
```

## 5.5 Session Establishment

### 5.5.1 Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant TP as Teleport
    participant KC as Keycloak
    participant AAD as Azure AD

    U->>TP: Access Teleport (tsh login or web)
    TP->>KC: Redirect to Keycloak
    KC->>AAD: Redirect to Azure AD
    U->>AAD: Authenticate (username/password + MFA)
    AAD->>AAD: Validate credentials
    AAD->>KC: Return ID token
    KC->>KC: Validate token, map groups
    KC->>TP: Return access token with claims
    TP->>TP: Map claims to roles
    TP->>TP: Create Teleport session
    TP->>U: Issue Teleport certificates
    Note over U,TP: User now has time-limited certificates
```

### 5.5.2 Certificate Issuance

Upon successful authentication, Teleport issues:

| Certificate | Purpose | TTL |
|-------------|---------|-----|
| User certificate | SSH authentication | Session TTL (e.g., 12h) |
| TLS certificate | Database/App authentication | Session TTL |

### 5.5.3 Session Properties

| Property | Value | Source |
|----------|-------|--------|
| Session TTL | Configurable (default: 12h) | Teleport configuration |
| Max session TTL | Configurable (default: 30h) | Teleport configuration |
| Idle timeout | Configurable (default: 30m) | Teleport configuration |
| MFA requirement | Per-session or per-resource | Role configuration |

## 5.6 Identity Lifecycle

### 5.6.1 User Onboarding

When a new user is added to Azure AD:

```mermaid
flowchart LR
    HR[HR adds user to Azure AD] --> AAD[Azure AD]
    AAD --> Groups[Assigned to groups]
    Groups --> KC[Groups sync to Keycloak]
    KC --> TP[User can authenticate to Teleport]
    TP --> Access[Access based on group membership]
```

No action required from Platform Team—access is automatic based on group membership.

### 5.6.2 User Offboarding

When a user is removed from Azure AD:

```mermaid
flowchart LR
    HR[HR removes user from Azure AD] --> AAD[Azure AD]
    AAD --> KC[Keycloak session invalid]
    KC --> TP[Teleport authentication fails]
    TP --> Cert[Existing certificates expire naturally]
    Cert --> NoAccess[No further access possible]
```

| Timeline | Effect |
|----------|--------|
| Immediate | Cannot authenticate to Keycloak |
| Within TTL | Existing certificates may still work |
| After TTL | All access revoked |

For immediate revocation, administrators can:
- Lock the Teleport user
- Revoke active certificates
- Terminate active sessions

### 5.6.3 Role Changes

When a user's Azure AD groups change:

| Action | Effect | Timeline |
|--------|--------|----------|
| Added to group | New role available | Next authentication |
| Removed from group | Role revoked | Next authentication |

Active sessions continue with original roles until re-authentication.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 4. Components](./04-components.md) | [Table of Contents](./00-index.md#table-of-contents) | [6. SSH Access →](./06-ssh-access.md) |

---

*End of Section 5 — RFC-PAM-0001*
