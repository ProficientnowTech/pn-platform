```
RFC-PAM-0001                                                  Appendix A
Category: Standards Track                                      Glossary
```

# Appendix A: Glossary

[← Previous: Evolution](./13-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: Appendix B →](./appendix-b-references.md)

---

## A.1 Term Definitions

### Access Management Terms

**Access Broker**
A system that mediates access between users and target resources. In this architecture, Teleport serves as the access broker for all privileged infrastructure access.

**Access Request**
A formal request for elevated or temporary access. Access requests include requester identity, requested permissions, duration, and justification.

**Authorization Ceiling**
The principle that downstream systems cannot grant permissions exceeding those available from upstream systems. Azure AD group memberships define the ceiling; Keycloak and Teleport can only grant subsets.

**Certificate-Based Authentication**
Authentication using cryptographically signed certificates instead of passwords or static keys. Certificates contain identity claims and have limited validity periods.

**Dynamic Credentials**
Credentials generated on-demand with limited lifetime. Vault generates dynamic credentials for database access, eliminating standing passwords.

**Ephemeral Credentials**
Short-lived credentials that automatically expire. Used interchangeably with dynamic credentials in this RFC.

**Just-in-Time (JIT) Access**
Access granted only when needed, for a limited duration, typically requiring explicit approval. Contrasts with standing access.

**Principal**
In SSH certificate context, the Unix usernames that a certificate holder is permitted to use. For example, a certificate with principals `ubuntu` and `ec2-user` allows login as either user.

**Privileged Access**
Access to infrastructure resources that requires elevated permissions, such as SSH to servers, database connections, or Kubernetes exec.

**Session Recording**
Capture of all activity during a privileged session for audit and compliance purposes. Includes terminal I/O, queries, and metadata.

**Standing Access**
Permanent or long-lived access that exists regardless of current need. This architecture eliminates standing access in favor of JIT.

**Zero Direct Access**
The principle that no direct connections are permitted from user workstations to target resources; all access must flow through the access broker.

### Component Terms

**Auth Service**
Teleport's control plane component responsible for authentication, certificate issuance, and RBAC enforcement.

**Database Agent**
Teleport component that proxies database connections and enables query logging.

**eBPF (extended Berkeley Packet Filter)**
Linux kernel technology used for low-latency session capture in containers without modifying applications.

**External Secrets Operator (ESO)**
Kubernetes operator that synchronizes secrets from external stores (Vault) to Kubernetes Secrets.

**Kubernetes Agent**
Teleport component that enables governed kubectl exec/attach/port-forward operations.

**Proxy Service**
Teleport's data plane component responsible for routing connections to agents.

**SSH Agent**
Teleport component running on target hosts that handles SSH connections and session recording.

**SSH Certificate Authority (CA)**
The system that signs SSH certificates. In this architecture, Vault's SSH secrets engine acts as the CA.

**Teleport**
The access broker platform providing unified access to SSH, databases, Kubernetes, and applications with session recording and access control.

### Protocol Terms

**mTLS (Mutual TLS)**
TLS where both client and server present certificates for mutual authentication. Used between Teleport components.

**OIDC (OpenID Connect)**
Authentication protocol used for Teleport integration with Keycloak.

**SSH Certificate**
A signed document asserting that a public key belongs to a specific identity with specific permissions (principals) for a limited time.

### Workflow Terms

**Approval Chain**
The sequence of approvers required for an access request. May require one approver (OR logic) or multiple approvers (AND logic).

**Break-Glass**
Emergency access procedure that bypasses normal controls. Subject to enhanced audit and review.

**TTL (Time To Live)**
The duration for which a credential or access grant remains valid.

---

## A.2 Diagram Index

All diagrams included in this RFC:

| Diagram Name | Type | Section |
|--------------|------|---------|
| System Overview | flowchart | §3.1 |
| Zero Direct Access Model | flowchart | §3.2.1 |
| Trust Hierarchy | flowchart | §3.3.1 |
| Trust Boundaries | flowchart | §3.5.1 |
| Authentication Flow | sequenceDiagram | §3.6.1 |
| SSH Access Flow | sequenceDiagram | §3.6.2 |
| Database Access Flow | sequenceDiagram | §3.6.3 |
| Kubernetes Exec Flow | sequenceDiagram | §3.6.4 |
| Teleport Cluster Diagram | flowchart | §4.1.5 |
| Agent Architecture | flowchart | §4.2.5 |
| SSH CA Integration | flowchart | §4.3.1 |
| Certificate Flow | sequenceDiagram | §4.3.4 |
| Credential Lifecycle | sequenceDiagram | §4.4.4 |
| ESO Secret Distribution | flowchart | §4.5.3 |
| Resource Enrollment | flowchart | §4.6.4 |
| Keycloak SSO Integration | flowchart | §5.1.1 |
| Group-to-Role Mapping | flowchart | §5.2.1 |
| Authorization Ceiling Enforcement | flowchart | §5.3.1 |
| Session Establishment | sequenceDiagram | §5.5.1 |
| User Onboarding | flowchart | §5.6.1 |
| User Offboarding | flowchart | §5.6.2 |
| User Certificate Flow | sequenceDiagram | §6.4.1 |
| Principal Hierarchy | flowchart | §6.5.3 |
| Database Agent Flow | flowchart | §7.3.2 |
| Credential Lifecycle (Database) | sequenceDiagram | §7.4.1 |
| Kubernetes Exec Flow | sequenceDiagram | §8.1.3 |
| Namespace Security Boundary | flowchart | §8.3.1 |
| Dual Authorization | flowchart | §8.4.1 |
| Storage Architecture | flowchart | §9.2.3 |
| Session Join | sequenceDiagram | §9.4.2 |
| Log Correlation | flowchart | §9.5.4 |
| JIT Access Request Flow | sequenceDiagram | §10.2.1 |
| Access Lifecycle | stateDiagram | §10.4.3 |
| Request-Session Linking | flowchart | §10.6.2 |
| Repository Structure | text | §11.1.2 |
| Role Hierarchy | flowchart | §11.2.3 |
| GitOps Workflow | flowchart | §11.2.4 |
| ESO Distribution | flowchart | §11.4.3 |
| Multi-Region Deployment | flowchart | §13.2.3 |

---

## A.3 Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| AAD | Azure Active Directory |
| API | Application Programming Interface |
| CA | Certificate Authority |
| CLI | Command Line Interface |
| DBA | Database Administrator |
| eBPF | extended Berkeley Packet Filter |
| ESO | External Secrets Operator |
| GCS | Google Cloud Storage |
| HA | High Availability |
| HTTPS | Hypertext Transfer Protocol Secure |
| IAM | Identity and Access Management |
| IdP | Identity Provider |
| JIT | Just-in-Time |
| JWT | JSON Web Token |
| K8s | Kubernetes |
| MFA | Multi-Factor Authentication |
| mTLS | Mutual Transport Layer Security |
| OIDC | OpenID Connect |
| OTP | One-Time Password |
| PAM | Privileged Access Management |
| PR | Pull Request |
| RBAC | Role-Based Access Control |
| RDP | Remote Desktop Protocol |
| RFC | Request for Comments |
| S3 | Simple Storage Service (AWS) |
| SA | Service Account |
| SAML | Security Assertion Markup Language |
| SCIM | System for Cross-domain Identity Management |
| SIEM | Security Information and Event Management |
| SRE | Site Reliability Engineering |
| SSH | Secure Shell |
| SSM | Systems Manager (AWS) |
| SSO | Single Sign-On |
| TLS | Transport Layer Security |
| TTL | Time To Live |
| UI | User Interface |
| VPN | Virtual Private Network |
| YAML | YAML Ain't Markup Language |

---

## A.4 ADR Index

Architectural Decision Records documented in this RFC:

| ADR ID | Decision Summary | Rationale Section |
|--------|------------------|-------------------|
| ADR-PAM-001 | Teleport as access broker | §12.1 |
| ADR-PAM-002 | Certificate-based SSH authentication | §12.3.1 |
| ADR-PAM-003 | Vault as SSH CA | §6.2 |
| ADR-PAM-004 | Dynamic database credentials | §12.3.3 |
| ADR-PAM-005 | Separate from RFC-WORKLOAD-IDENTITY | §12.4 |
| ADR-PAM-006 | Session recording mandatory | §9.1.1 |
| ADR-PAM-007 | GitOps for role definitions | §11.5 |
| ADR-PAM-008 | JIT for elevated access | §10.1 |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 13. Evolution](./13-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A — RFC-PAM-0001*
