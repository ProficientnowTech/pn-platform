```
RFC-PAM-0001                                                    Section 1
Category: Standards Track                                    Introduction
```

# 1. Introduction

[← Index](./00-index.md) | [Index](./00-index.md#table-of-contents) | [Next: Requirements →](./02-requirements.md)

---

## 1.1 Background and Context

Modern platform engineering requires developers and operators to access infrastructure resources for debugging, maintenance, and incident response. This access includes:

- **SSH sessions** to Linux/Unix servers for troubleshooting and configuration
- **Database connections** for query execution and data investigation
- **Kubernetes exec** for container debugging and log access
- **Remote desktop** for Windows server administration

Traditionally, this access has been managed through:
- Long-lived SSH keys distributed to individual users
- Shared database credentials stored in password managers
- VPN access combined with direct connections
- Jump boxes (bastions) with varying levels of audit capability

These approaches create significant security and operational challenges that this architecture addresses.

## 1.2 Current State Analysis

### 1.2.1 Traditional SSH Access

Organizations typically manage SSH access through one of these models:

| Model | Description | Problems |
|-------|-------------|----------|
| **Individual SSH Keys** | Each user has a personal key pair | Key sprawl, difficult revocation, no expiry |
| **Shared Keys** | Team shares a single key | No accountability, dangerous rotation |
| **Jump Boxes** | Bastion host for access | Single point of failure, limited audit |
| **VPN + Direct** | VPN grants network access | Broad access, no session logging |

### 1.2.2 Traditional Database Access

Database access patterns exhibit similar challenges:

| Pattern | Description | Problems |
|---------|-------------|----------|
| **Shared Credentials** | Team uses common username/password | No individual accountability |
| **Per-User Accounts** | Manual account provisioning | Account sprawl, stale accounts |
| **Application Credentials** | Developers use app credentials | Excessive permissions, audit confusion |

### 1.2.3 Kubernetes Access

Kubernetes administrative access typically relies on:

| Method | Description | Problems |
|--------|-------------|----------|
| **Admin kubeconfig** | Shared cluster-admin credentials | No accountability, excessive access |
| **OIDC Integration** | Per-user authentication | Incomplete audit for exec/attach |
| **Service Account Tokens** | Long-lived tokens | No session visibility |

## 1.3 The Problem with Traditional Access

### 1.3.1 Standing Credentials

Traditional access models rely on **standing credentials**—credentials that exist and remain valid regardless of whether access is currently needed:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Standing Credentials Problem                             │
│                                                                              │
│   Time ──────────────────────────────────────────────────────────────►      │
│                                                                              │
│   Credential Created              Credential Compromised                     │
│         │                                │                                   │
│         ▼                                ▼                                   │
│   ══════════════════════════════════════════════════════════════════        │
│   │                    CREDENTIAL VALID                              │       │
│   ══════════════════════════════════════════════════════════════════        │
│         │         │         │         │         │         │                 │
│         ▼         ▼         ▼         ▼         ▼         ▼                 │
│      Access    Access    Access   [BREACH]   Attacker   Attacker            │
│      Needed    Needed    Needed              Access     Access              │
│                                                                              │
│   Exposure window = credential lifetime (potentially years)                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3.2 Accountability Gap

Without session recording, answering "who did what, when" becomes forensic investigation:

| Question | Traditional Answer | Desired Answer |
|----------|-------------------|----------------|
| Who accessed the database? | Check DB logs, correlate with auth logs | Session recording with user identity |
| What commands were run? | Shell history (if not cleared) | Complete session capture |
| When did access occur? | Log timestamps (if retained) | Unified audit timeline |
| Was access authorized? | Check ticket system separately | JIT request linked to session |

### 1.3.3 Access Revocation Complexity

When an employee leaves or changes roles:

**Traditional Process**:
1. Identify all systems with user's SSH key
2. Remove key from each system's authorized_keys
3. Identify all database accounts
4. Remove or disable each account
5. Rotate any shared credentials the user knew
6. Revoke VPN access
7. Hope nothing was missed

**Desired Process**:
1. Remove user from identity provider
2. Access automatically revoked everywhere

### 1.3.4 Compliance Burden

Regulatory frameworks require evidence of access controls:

| Requirement | Traditional Evidence | Desired Evidence |
|-------------|---------------------|------------------|
| Access is authorized | Manual approval records | JIT request with approval chain |
| Access is logged | Scattered system logs | Centralized session recordings |
| Access is time-limited | Policy documents | Enforced TTL on all credentials |
| Access is least-privilege | Role documentation | Granular RBAC with audit |

## 1.4 Motivation for This Architecture

### 1.4.1 Zero Standing Credentials

This architecture eliminates standing credentials through:

- **Short-lived SSH certificates** signed on-demand by Vault
- **Ephemeral database credentials** generated per-session by Vault
- **Time-bound access grants** with automatic expiration
- **Certificate-only authentication** with direct key auth disabled

### 1.4.2 Comprehensive Session Visibility

All privileged access is recorded:

- **SSH sessions**: Full terminal capture with playback
- **Database sessions**: Query logging with timing
- **Kubernetes exec**: Command capture via eBPF
- **RDP sessions**: Screen recording

### 1.4.3 Identity-Based Access Control

Access decisions derive from identity:

```
Azure AD Group Membership (Ceiling)
    │
    ▼
Keycloak Role (Platform Identity)
    │
    ▼
Teleport Role (Access Policy)
    │
    ▼
Resource Access (SSH, Database, K8s)
```

The authorization ceiling principle from RFC-IAM-0001 extends to infrastructure access—Teleport cannot grant access that exceeds what the user's Azure AD groups permit.

### 1.4.4 Just-in-Time Access

Elevated access requires explicit request and approval:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Just-in-Time Access Model                             │
│                                                                              │
│   Time ──────────────────────────────────────────────────────────────►      │
│                                                                              │
│   Access        Approval        Access          Access                       │
│   Requested     Granted         Used            Expires                      │
│       │            │              │                │                         │
│       ▼            ▼              ▼                ▼                         │
│   ────────────────══════════════════════════────────────────────────        │
│                   │  ACCESS VALID (2 hours)  │                              │
│   ────────────────══════════════════════════════════════════════════        │
│                                                                              │
│   Exposure window = approved duration only                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.4.5 Single Pane of Glass

All privileged access flows through one system:

| Benefit | Description |
|---------|-------------|
| **Unified Audit** | One place for all access logs |
| **Consistent Policy** | Same RBAC model across resource types |
| **Simplified Revocation** | One integration point to disable |
| **Reduced Attack Surface** | One well-secured access point |

### 1.4.6 Organizational Authority Alignment

Following the rationale from RFC-IAM-0001 §9.1, this architecture respects organizational authority boundaries:

| Authority | Responsibility | System |
|-----------|----------------|--------|
| **HR/Management** | User lifecycle, team assignment | Azure AD |
| **Platform Team** | Access policies, role definitions | Keycloak + Teleport |
| **Resource Owners** | Resource enrollment, specific permissions | Teleport agents |

When HR removes a user from Azure AD:
1. Keycloak session becomes invalid
2. Teleport authentication fails
3. No new certificates can be issued
4. Existing short-lived credentials expire naturally

No manual intervention required from platform or resource teams.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Index](./00-index.md) | [Table of Contents](./00-index.md#table-of-contents) | [2. Requirements →](./02-requirements.md) |

---

*End of Section 1 — RFC-PAM-0001*
