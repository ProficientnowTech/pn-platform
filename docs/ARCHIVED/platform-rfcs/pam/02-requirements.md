```
RFC-PAM-0001                                                    Section 2
Category: Standards Track                                    Requirements
```

# 2. Requirements

[← Previous: Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture →](./03-architecture.md)

---

## 2.1 Problem Restatement

The platform requires a privileged access management system that:

1. **Eliminates standing credentials** for infrastructure access
2. **Records all privileged sessions** for audit and compliance
3. **Integrates with the platform identity system** (RFC-IAM-0001)
4. **Uses Vault as the credential authority** (RFC-SECOPS-0001)
5. **Supports just-in-time access** with approval workflows
6. **Enables GitOps management** of access policies

The system must handle SSH, database, and Kubernetes access through a unified model while maintaining the authorization ceiling established by Azure AD group memberships.

## 2.2 Design Goals

### 2.2.1 Primary Goals

| ID | Goal | Rationale |
|----|------|-----------|
| G-1 | **Zero direct access** | All privileged access flows through Teleport |
| G-2 | **Certificate-based authentication** | Eliminate long-lived SSH keys |
| G-3 | **Ephemeral database credentials** | No standing database passwords |
| G-4 | **Comprehensive session recording** | Complete audit trail for compliance |
| G-5 | **Identity-derived authorization** | Access based on Keycloak identity |
| G-6 | **Just-in-time elevated access** | Time-bound grants with approval |
| G-7 | **GitOps policy management** | Version-controlled access policies |

### 2.2.2 Secondary Goals

| ID | Goal | Rationale |
|----|------|-----------|
| G-8 | **Minimal user friction** | Security that doesn't impede productivity |
| G-9 | **Self-service where appropriate** | Reduce operational bottlenecks |
| G-10 | **Extensibility** | Support future resource types |
| G-11 | **High availability** | Critical path for incident response |

## 2.3 Non-Goals

The following are explicitly **out of scope** for this RFC:

| Non-Goal | Rationale | Covered By |
|----------|-----------|------------|
| Web application SSO | Different access pattern | RFC-IAM-0001 |
| Service-to-service authentication | Machine identity, not human | RFC-WORKLOAD-IDENTITY |
| Secret storage and rotation | Vault mechanics | RFC-SECOPS-0001 |
| Network segmentation | Complementary control | RFC-TENANT-SECURITY |
| Self-service request UI | Portal functionality | RFC-DEVELOPER-PLATFORM |
| CI/CD pipeline credentials | Automated workloads | RFC-WORKLOAD-IDENTITY |
| API token management | Service identity | RFC-WORKLOAD-IDENTITY |

## 2.4 Architectural Invariants

These rules MUST always hold. Violations indicate architecture failure.

### 2.4.1 Identity Invariants

| ID | Invariant | Verification |
|----|-----------|--------------|
| INV-1 | All privileged access MUST be authenticated through Keycloak | Teleport OIDC connector is sole auth method |
| INV-2 | Teleport roles MUST NOT exceed Azure AD group permissions | Role-to-group mapping respects ceiling |
| INV-3 | Local user accounts on Teleport MUST NOT exist | Teleport user database is empty |

**INV-1: Keycloak Authentication**

Teleport MUST NOT authenticate users through any mechanism other than Keycloak OIDC. This ensures:
- Single identity source across the platform
- Azure AD group memberships are authoritative
- User termination in Azure AD revokes all access

**INV-2: Authorization Ceiling**

Teleport roles MUST be designed such that a user cannot obtain permissions exceeding what their Azure AD groups permit. The hierarchy is:

```
Azure AD Groups (immutable ceiling)
    │
    └── Keycloak Groups (≤ Azure AD)
            │
            └── Teleport Roles (≤ Keycloak)
                    │
                    └── Resource Access (≤ Teleport)
```

**INV-3: No Local Users**

Teleport MUST NOT maintain local user accounts. All users MUST authenticate through Keycloak. This prevents:
- Shadow identity management
- Bypass of Azure AD termination
- Inconsistent access records

### 2.4.2 Access Control Invariants

| ID | Invariant | Verification |
|----|-----------|--------------|
| INV-4 | All privileged sessions MUST flow through Teleport | Direct SSH/DB connections blocked |
| INV-5 | Direct SSH key authentication MUST be disabled on managed hosts | `PubkeyAuthentication no` or cert-only in sshd_config |
| INV-6 | All interactive sessions MUST be recorded | Recording enabled, storage verified |
| INV-7 | Session recordings MUST be stored in immutable storage | Write-once storage, retention policy |

**INV-4: Teleport as Single Access Point**

All privileged access MUST transit through Teleport. This is enforced through:
- Network policies blocking direct SSH (port 22) from user networks
- Database credentials only issued through Teleport
- Kubernetes API access through Teleport proxy

**INV-5: Certificate-Only SSH**

Managed hosts MUST reject direct SSH key authentication. Only certificates signed by the Vault SSH CA (via Teleport) are accepted. This ensures:
- No long-lived SSH keys
- Automatic credential expiration
- Audit trail for all sessions

**INV-6: Mandatory Recording**

All interactive sessions MUST be recorded. This includes:
- SSH terminal sessions
- Database query sessions
- Kubernetes exec sessions
- RDP sessions

Recording MUST NOT be optional or bypassable.

**INV-7: Immutable Audit Storage**

Session recordings MUST be stored in append-only/write-once storage. This ensures:
- Recordings cannot be deleted by users
- Tampering is detectable
- Compliance retention requirements are met

### 2.4.3 Credential Invariants

| ID | Invariant | Verification |
|----|-----------|--------------|
| INV-8 | SSH certificates MUST be signed by Vault SSH CA | Certificate chain verification |
| INV-9 | Database credentials MUST be ephemeral (Vault dynamic secrets) | No static database passwords |
| INV-10 | Credential TTL MUST NOT exceed session duration | Credentials expire with session |

**INV-8: Vault SSH CA Authority**

All SSH certificates MUST be signed by Vault's SSH secrets engine. Teleport acts as a certificate request broker, not a CA. This centralizes CA authority in Vault per RFC-SECOPS-0001.

**INV-9: Ephemeral Database Credentials**

Database access MUST use Vault dynamic secrets. Credentials are:
- Generated on-demand for each session
- Unique per user per session
- Automatically revoked at TTL expiry

Static database passwords MUST NOT be used for human access.

**INV-10: Credential-Session Binding**

Credentials issued for a session MUST NOT outlive that session. When a session ends:
- SSH certificates become invalid (short TTL)
- Database credentials are revoked
- No credential can be reused

### 2.4.4 GitOps Invariants

| ID | Invariant | Verification |
|----|-----------|--------------|
| INV-11 | Teleport role definitions MUST be stored in Git | Roles exist in platform repository |
| INV-12 | User-to-role assignments MAY be managed administratively | Operational flexibility preserved |
| INV-13 | Agent enrollment tokens MUST be distributed via ESO | Tokens sourced from Vault |

**INV-11: Roles in Git**

Teleport role definitions (what permissions exist) MUST be version-controlled in Git. This provides:
- Audit trail for policy changes
- Peer review for role modifications
- Reproducible access configuration

**INV-12: Administrative Assignments**

User-to-role assignments (who has what role) MAY be managed through administrative interfaces rather than Git. This preserves operational flexibility for:
- Rapid access changes during incidents
- Time-sensitive role grants
- JIT access approvals

**INV-13: ESO for Agent Secrets**

Teleport agent enrollment tokens and other bootstrap secrets MUST be distributed through External Secrets Operator per RFC-SECOPS-0001 patterns. Tokens MUST NOT be:
- Hardcoded in manifests
- Stored in Git
- Manually distributed

## 2.5 Success Criteria

### 2.5.1 Security Criteria

| Criterion | Measurement |
|-----------|-------------|
| No standing SSH keys | Zero authorized_keys entries on managed hosts |
| No static DB passwords | All DB access via Vault dynamic credentials |
| Complete session coverage | 100% of privileged sessions recorded |
| Timely revocation | Access revoked within 5 minutes of identity removal |

### 2.5.2 Operational Criteria

| Criterion | Measurement |
|-----------|-------------|
| Access availability | 99.9% uptime for Teleport proxy |
| Session latency | <500ms additional latency for proxied sessions |
| Recording retrieval | Session playback available within 1 minute |
| JIT approval time | P95 approval response <15 minutes |

### 2.5.3 Compliance Criteria

| Criterion | Measurement |
|-----------|-------------|
| Audit completeness | All access events queryable by user, resource, time |
| Retention compliance | Recordings retained per policy (default: 1 year) |
| Access justification | JIT requests linked to sessions |
| Approval evidence | Approval chain captured in audit log |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture →](./03-architecture.md) |

---

*End of Section 2 — RFC-PAM-0001*
