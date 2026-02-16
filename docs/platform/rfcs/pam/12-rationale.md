```
RFC-PAM-0001                                                   Section 12
Category: Standards Track                                      Rationale
```

# 12. Rationale

[← Previous: GitOps Integration](./11-gitops-integration.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution →](./13-evolution.md)

---

## 12.1 Why Teleport

### 12.1.1 Selection Criteria

The access broker was evaluated against these criteria:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Protocol coverage | High | SSH, database, Kubernetes, applications |
| Session recording | High | Complete capture for compliance |
| Identity integration | High | OIDC/SAML support |
| Certificate-based auth | High | Eliminate long-lived credentials |
| JIT access | Medium | Built-in access request workflow |
| Open source option | Medium | Avoid vendor lock-in |
| Kubernetes-native | Medium | Deploy as containers |
| Vault integration | High | Use existing credential authority |

### 12.1.2 Teleport Strengths

| Strength | Benefit |
|----------|---------|
| **Multi-protocol** | SSH, database, Kubernetes, applications in one system |
| **Session recording** | Built-in recording with playback |
| **Certificate-based** | Native certificate authentication |
| **OIDC integration** | Works with Keycloak |
| **Access requests** | Built-in JIT workflow |
| **Open source core** | Community edition available |
| **eBPF recording** | Low-latency Kubernetes session capture |
| **Active development** | Regular releases, active community |

### 12.1.3 Teleport Considerations

| Consideration | Mitigation |
|---------------|------------|
| Complexity | Phased rollout, starting with SSH |
| Learning curve | Training, documentation |
| Enterprise features | Evaluate OSS vs Enterprise needs |
| Vault integration | Custom integration for SSH CA |

## 12.2 Alternative Access Brokers

### 12.2.1 HashiCorp Boundary

**Description**: HashiCorp's access management solution focusing on identity-based access.

**Why It Was Attractive**:
- Same vendor as Vault (tight integration)
- Identity-based access model
- Simple architecture
- Growing feature set

**Why It Was Rejected**:
- Limited session recording capabilities
- Fewer supported protocols than Teleport
- Less mature Kubernetes integration
- No built-in JIT access workflow

**Invariants Affected**:
- INV-6 (session recording) would require additional components
- INV-4 (single access point) harder to achieve across all protocols

**Conclusion**: Boundary is a strong option for simpler use cases but lacks the session recording depth required for compliance.

### 12.2.2 Traditional Bastion Hosts

**Description**: Jump servers providing SSH access to internal networks.

**Why It Was Attractive**:
- Simple, well-understood model
- Minimal infrastructure
- No new software to learn
- Works with existing SSH clients

**Why It Was Rejected**:
- Limited session recording (requires additional tools)
- SSH key management burden
- No protocol coverage beyond SSH
- No built-in access control beyond SSH authorized_keys
- Manual key rotation

**Invariants Violated**:
- INV-5 (certificate-only auth)—bastion relies on SSH keys
- INV-6 (session recording)—requires additional tooling
- INV-8 (Vault SSH CA)—not native

**Conclusion**: Bastion hosts solve network segmentation but don't address credential management, session recording, or multi-protocol access.

### 12.2.3 VPN + Direct Access

**Description**: VPN provides network access; users connect directly to resources.

**Why It Was Attractive**:
- Standard enterprise pattern
- Works with all protocols
- No per-resource configuration
- Users have familiar experience

**Why It Was Rejected**:
- No session recording
- Broad network access (not least privilege)
- Credential management per-resource
- No centralized audit
- VPN becomes single point of failure

**Invariants Violated**:
- INV-4 (single access point)—no centralized broker
- INV-6 (session recording)—no recording capability
- INV-9 (ephemeral credentials)—static credentials typical

**Conclusion**: VPN provides network connectivity but offers none of the access governance this architecture requires.

### 12.2.4 AWS Systems Manager (SSM)

**Description**: AWS-native session manager for EC2 instances.

**Why It Was Attractive**:
- AWS-native integration
- Session recording to S3
- No bastion host needed
- IAM-based access control

**Why It Was Rejected**:
- AWS-only (not multi-cloud)
- Limited to SSH-like access (no database, Kubernetes)
- No OIDC integration (IAM only)
- No JIT access workflow
- Recording quality varies

**Invariants Affected**:
- INV-1 (Keycloak auth)—would require IAM federation
- Not applicable for database or Kubernetes access

**Conclusion**: SSM is appropriate for AWS-only SSH access but doesn't meet multi-protocol, multi-cloud requirements.

## 12.3 Alternative Credential Models

### 12.3.1 Long-Lived SSH Keys

**Description**: Traditional SSH key pairs distributed to users.

**Why It Was Attractive**:
- Universal SSH support
- No additional infrastructure
- Users manage their own keys
- Simple mental model

**Why It Was Rejected**:
- Keys never expire without manual revocation
- Key distribution is error-prone
- Revocation requires touching every host
- No individual accountability without configuration
- Key sprawl across hosts

**Invariants Violated**:
- INV-5 (certificate-only)—explicitly prohibited
- INV-10 (credential TTL)—keys have no TTL

**Conclusion**: Long-lived SSH keys are fundamentally incompatible with zero-standing-credentials model.

### 12.3.2 Vault SSH OTP

**Description**: Vault generates one-time passwords for SSH authentication.

**Why It Was Attractive**:
- Simple Vault integration
- Works with password authentication
- No CA infrastructure needed
- Short-lived by design

**Why It Was Rejected**:
- Requires password authentication enabled on hosts
- Less secure than certificate authentication
- Password transmission over network
- Limited principal/identity embedding

**Invariants Affected**:
- INV-5 would need modification (password vs certificate)
- Weaker security properties than certificates

**Conclusion**: SSH OTP is simpler but certificates provide stronger security guarantees.

### 12.3.3 Static Database Credentials

**Description**: Shared or per-user database credentials that persist.

**Why It Was Attractive**:
- Simple setup
- No Vault integration required
- Standard database authentication
- Works with all clients

**Why It Was Rejected**:
- Credentials never expire without manual rotation
- Shared credentials lack accountability
- Per-user credentials create management burden
- Rotation is disruptive
- No automatic revocation

**Invariants Violated**:
- INV-9 (ephemeral credentials)—explicitly requires dynamic
- INV-10 (credential TTL)—static has no TTL

**Conclusion**: Static database credentials are incompatible with ephemeral credential requirements.

## 12.4 Why Separate from RFC-WORKLOAD-IDENTITY

### 12.4.1 Fundamental Differences

| Aspect | RFC-PAM (Human Access) | RFC-WORKLOAD-IDENTITY (Service Access) |
|--------|------------------------|----------------------------------------|
| **Identity type** | Human user | Machine/service |
| **Authentication** | Interactive (OIDC via Keycloak) | Non-interactive (Kubernetes SA) |
| **Session concept** | Interactive session with recording | Connection/request |
| **Credential flow** | Human → Teleport → Vault | Service → Vault directly |
| **Recording requirement** | Mandatory | Not applicable |
| **JIT workflow** | Required for elevated access | Not applicable |
| **Audit focus** | What did this person do? | What did this service do? |

### 12.4.2 Why Not One RFC?

**Argument for combining**: "It's all access management"

**Counter-argument**:
1. **Different lifecycles**: Human access is interactive and session-based; service access is programmatic and continuous
2. **Different controls**: Humans need session recording and JIT; services need policy-based pre-authorization
3. **Different audiences**: PAM is for security/compliance teams; workload identity is for platform/DevOps teams
4. **Different technologies**: Teleport for humans; direct Vault for services
5. **Separate concerns**: Easier to reason about each independently

### 12.4.3 Integration Points

The two RFCs share:

| Shared Component | Usage |
|------------------|-------|
| **Vault** | Both use Vault for credentials |
| **Keycloak** | Human identity flows through Keycloak |
| **Azure AD** | Authorization ceiling for both |
| **ESO** | Secret distribution for both |

But implement different access patterns appropriate to their subjects.

### 12.4.4 Boundary Example

A developer accessing a database:

**As a human (RFC-PAM)**:
1. Authenticate via Keycloak
2. Connect through Teleport
3. Teleport requests credentials from Vault
4. Session is recorded
5. Credentials revoked at session end

**As a service (RFC-WORKLOAD-IDENTITY)**:
1. Pod starts with ServiceAccount
2. Vault Agent authenticates to Vault
3. Vault issues credentials
4. Application uses credentials
5. Credentials renewed/revoked per lease

Same database, same Vault, different access patterns.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 11. GitOps Integration](./11-gitops-integration.md) | [Table of Contents](./00-index.md#table-of-contents) | [13. Evolution →](./13-evolution.md) |

---

*End of Section 12 — RFC-PAM-0001*
