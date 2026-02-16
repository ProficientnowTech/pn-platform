```
RFC-WORKLOAD-IDENTITY-0001                                      Section 2
Category: Standards Track                                    Requirements
```

# 2. Requirements

[← Previous: Introduction](./01-introduction.md) | [Index](./00-index.md#table-of-contents) | [Next: Architecture →](./03-architecture.md)

---

## 2.1 Design Goals

### 2.1.1 Primary Goals

| Goal | Description |
|------|-------------|
| **Unified Identity Model** | Single framework for all workload types |
| **Zero Long-Lived Credentials** | All credentials short-lived and automatically rotated |
| **Attestation-Based Auth** | Identity proven through workload properties, not secrets |
| **Delegation Support** | Track who authorized what, especially for AI agents |
| **Multi-Cloud Portability** | Works across cloud providers and on-premises |

### 2.1.2 Secondary Goals

| Goal | Description |
|------|-------------|
| **Minimal Workload Changes** | Workloads shouldn't need extensive modification |
| **GitOps Compatible** | Configuration declarative and version-controlled |
| **Operator Friendly** | Clear operational runbooks and observability |
| **Compliance Ready** | Meet SOC 2, ISO 27001, PCI DSS requirements |

---

## 2.2 Non-Goals

These are explicitly out of scope for this RFC:

| Non-Goal | Why | Addressed By |
|----------|-----|--------------|
| Human authentication | Different access patterns | RFC-IAM-0001 |
| Human privileged access | Session recording needed | RFC-PAM-0001 |
| Secret storage design | Vault architecture exists | RFC-SECOPS-0001 |
| Network policies | Layer 3/4 concerns | RFC-TENANT-SECURITY |
| Application authorization | Per-app concern | Application teams |

---

## 2.3 Architectural Invariants

Invariants are rules that MUST always be true. Violation of an invariant indicates an architectural breach.

### Identity Authority (INV-1 to INV-3)

---

**INV-1: Workload Identity Authority**

> Every workload MUST have a cryptographically verifiable identity issued by an authorized identity provider (SPIRE, Kubernetes, or cloud provider).

| Aspect | Requirement |
|--------|-------------|
| **Identity Format** | SPIFFE ID or equivalent verifiable identity |
| **Cryptographic Backing** | X.509 certificate or signed JWT |
| **Issuer Authority** | Only SPIRE, Kubernetes, or cloud provider may issue |
| **Verification** | Recipients MUST verify signatures and validity |

**Rationale**: Anonymous or unverifiable workloads cannot be trusted. Cryptographic identity enables mutual authentication and audit.

**Enforcement**: Service mesh rejects connections without valid identity; Vault denies requests from unidentified workloads.

---

**INV-2: No Long-Lived Credentials**

> Workloads MUST NOT use long-lived static credentials (API keys, service account keys, passwords). All credentials MUST be short-lived and automatically rotated.

| Credential Type | Maximum TTL | Rotation |
|-----------------|-------------|----------|
| SPIFFE SVID | 24 hours | Automatic before expiry |
| Vault tokens | 1 hour | Automatic renewal |
| Database credentials | 1 hour | Vault lease renewal |
| Cloud credentials | 1 hour | STS/Workload Identity |

**Rationale**: Long-lived credentials create extended windows for compromise. Short-lived credentials limit blast radius.

**Enforcement**: Vault policies enforce max TTL; SPIRE agent rotates SVIDs; no static secrets in Kubernetes Secrets (except ESO-managed).

**Exceptions**: Bootstrap credentials (e.g., SPIRE join tokens) may have longer TTL but MUST be single-use.

---

**INV-3: Identity Attestation**

> Workload identity MUST be based on attestation of workload properties (Kubernetes metadata, cloud instance metadata, binary signatures) rather than pre-shared secrets.

| Platform | Attestation Method |
|----------|-------------------|
| Kubernetes | Node (PSAT), Pod (namespace, service account, labels) |
| AWS | Instance identity document |
| GCP | Instance metadata |
| Azure | Instance metadata service (IMDS) |

**Rationale**: Pre-shared secrets can be stolen and used from anywhere. Attestation proves the workload is what it claims to be.

**Enforcement**: SPIRE requires attestation for SVID issuance; cloud providers require instance metadata for STS.

---

### Authentication (INV-4 to INV-6)

---

**INV-4: Kubernetes Auth for Vault**

> Kubernetes workloads accessing Vault MUST authenticate using the Kubernetes auth method with projected service account tokens.

| Requirement | Details |
|-------------|---------|
| **Token Type** | Projected service account token (not legacy) |
| **Token Audience** | `vault` or Vault-specific audience |
| **Token TTL** | 10 minutes (renewed by Vault Agent/CSI) |
| **Auth Backend** | `auth/kubernetes-<cluster>` per cluster |

**Rationale**: Kubernetes auth eliminates "secret zero"—the workload's Kubernetes identity serves as the initial authentication.

**Enforcement**: Vault Kubernetes auth method validates token with Kubernetes API; legacy tokens rejected.

---

**INV-5: OIDC Federation for CI/CD**

> CI/CD pipelines accessing cloud resources MUST use OIDC federation (GitHub Actions OIDC, GitLab CI OIDC) rather than static credentials.

| CI/CD Platform | OIDC Provider |
|----------------|---------------|
| GitHub Actions | `token.actions.githubusercontent.com` |
| GitLab CI | `gitlab.com` or self-hosted |
| Tekton | Kubernetes ServiceAccount (OIDC Discovery) |

**Rationale**: Static credentials in CI/CD systems are a major attack vector. OIDC tokens are short-lived and bound to the pipeline run.

**Enforcement**: Cloud IAM policies require OIDC claims (repository, workflow, branch); static credentials removed from CI/CD.

---

**INV-6: mTLS for Service Communication**

> Service-to-service communication MUST use mutual TLS with certificates bound to workload identity.

| Requirement | Details |
|-------------|---------|
| **Certificate Source** | Service mesh (Linkerd) or SPIRE |
| **Verification** | Both client and server present certificates |
| **Identity Binding** | Certificate CN/SAN contains workload identity |
| **Plaintext** | Prohibited within mesh; allowed only for external ingress |

**Rationale**: mTLS ensures both parties are authenticated and traffic is encrypted.

**Enforcement**: Service mesh denies plaintext connections; network policies restrict non-mesh traffic.

---

### Authorization (INV-7 to INV-9)

---

**INV-7: Namespace-Scoped Permissions**

> Workload permissions MUST be scoped to the minimum required namespaces and resources.

| Permission Scope | Example |
|------------------|---------|
| **Vault policies** | `path "secret/data/ns/{{ identity.entity.aliases.auth_kubernetes-prod.metadata.service_account_namespace }}/*"` |
| **Kubernetes RBAC** | Namespace-scoped Roles, not ClusterRoles |
| **Cloud IAM** | Resource-specific policies, not broad roles |

**Rationale**: Broad permissions violate least privilege. Namespace scoping limits blast radius of compromise.

**Enforcement**: Policy templates use identity metadata; ClusterRoleBindings require justification.

---

**INV-8: Delegation Chain Preservation**

> When workloads act on behalf of other principals (human or machine), the delegation chain MUST be preserved and auditable.

| Delegation Scenario | Chain Preservation |
|--------------------|-------------------|
| AI agent for human | OAuth 2.0 Token Exchange with `actor` claim |
| Sub-agent for agent | Chained Token Exchange |
| Service for service | mTLS + request correlation ID |

**Rationale**: Without delegation tracking, accountability is lost. "Who authorized this action?" must be answerable.

**Enforcement**: Token Exchange enforces chain preservation; audit logs capture full delegation context.

---

**INV-9: Authorization Ceiling**

> Workload permissions MUST NOT exceed the permissions of the identity that created or authorized the workload.

| Scenario | Ceiling |
|----------|---------|
| AI agent delegated by human | Agent permissions ≤ Human's permissions |
| Service deployed by CI/CD | Service permissions ≤ Deployer's permissions |
| Operator creating resources | Created resource permissions ≤ Operator's permissions |

**Rationale**: Privilege escalation through automation must be prevented.

**Enforcement**: Token Exchange validates requested scope against delegator's scope; Kubernetes admission validates RBAC grants.

---

### Audit (INV-10 to INV-12)

---

**INV-10: Identity Audit Trail**

> All identity issuance, authentication, and authorization events MUST be logged with full context.

| Event Type | Required Context |
|------------|------------------|
| SVID issuance | SPIFFE ID, attestation data, expiry |
| Vault authentication | Auth method, entity, policies |
| Cloud STS | Assumed role, source identity, session |
| mTLS connection | Client/server identities, connection metadata |

**Rationale**: Security investigations require complete identity event history.

**Enforcement**: SPIRE, Vault, and cloud providers log to centralized system; logs immutable and retained per policy.

---

**INV-11: Delegation Audit**

> All delegation relationships (human→agent, agent→sub-agent) MUST be logged with creation, usage, and revocation events.

| Event | Required Context |
|-------|------------------|
| Delegation creation | Delegator, delegate, scope, expiry |
| Delegation usage | Action performed, resources accessed |
| Delegation revocation | Reason, revoker, timestamp |

**Rationale**: AI agents acting on human behalf must have full accountability.

**Enforcement**: OAuth 2.0 Token Exchange logs all exchanges; applications log delegation usage with correlation IDs.

---

**INV-12: Cross-System Correlation**

> Audit logs MUST include correlation IDs enabling tracing across Kubernetes, Vault, SPIRE, and application logs.

| System | Correlation Mechanism |
|--------|----------------------|
| Kubernetes | Request ID in audit logs |
| Vault | Request ID propagated from client |
| SPIRE | Registration entry ID |
| Application | OpenTelemetry trace ID |

**Rationale**: Distributed systems require correlated logs for incident investigation.

**Enforcement**: All systems configured to accept and propagate correlation IDs; centralized log aggregation correlates by ID.

---

## 2.4 Success Criteria

### 2.4.1 Identity Coverage

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Workloads with cryptographic identity | 100% | SPIRE/mesh certificate coverage |
| Static credentials eliminated | 0 | Secrets audit (no API keys, passwords) |
| OIDC-enabled CI/CD pipelines | 100% | Pipeline configuration audit |

### 2.4.2 Security Posture

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Maximum credential TTL | ≤24h | Vault/SPIRE configuration |
| mTLS coverage | 100% in mesh | Service mesh metrics |
| Failed authentication rate | <1% | Auth provider metrics |

### 2.4.3 Operational Health

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| SVID rotation success | 100% | SPIRE agent metrics |
| Vault token renewal success | 100% | Vault audit logs |
| Identity event correlation | 100% | Cross-system trace completion |

---

## 2.5 Invariant Summary

| ID | Category | One-Line Summary |
|----|----------|------------------|
| INV-1 | Identity Authority | Every workload has cryptographic identity |
| INV-2 | Identity Authority | No long-lived credentials |
| INV-3 | Identity Authority | Identity based on attestation |
| INV-4 | Authentication | Kubernetes auth for Vault |
| INV-5 | Authentication | OIDC federation for CI/CD |
| INV-6 | Authentication | mTLS for service communication |
| INV-7 | Authorization | Namespace-scoped permissions |
| INV-8 | Authorization | Delegation chain preservation |
| INV-9 | Authorization | Authorization ceiling |
| INV-10 | Audit | Identity audit trail |
| INV-11 | Audit | Delegation audit |
| INV-12 | Audit | Cross-system correlation |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 1. Introduction](./01-introduction.md) | [Table of Contents](./00-index.md#table-of-contents) | [3. Architecture →](./03-architecture.md) |

---

*End of Section 2 — RFC-WORKLOAD-IDENTITY-0001*
