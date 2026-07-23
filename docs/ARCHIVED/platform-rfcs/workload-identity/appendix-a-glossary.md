```
RFC-WORKLOAD-IDENTITY-0001                                      Appendix A
Category: Standards Track                                        Glossary
```

# Appendix A: Glossary

[← Previous: Evolution](./14-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: Appendix B →](./appendix-b-references.md)

---

## A.1 Term Definitions

### Identity Terms

**ARIA (Agent Relationship-based Identity and Authorization)**
An emerging pattern for AI agent identity that tracks delegation relationships between principals.

**Attestation**
The process of proving workload properties (Kubernetes metadata, cloud instance metadata, binary signatures) to establish identity without pre-shared secrets.

**Authorization Ceiling**
The principle that downstream systems cannot grant permissions exceeding those available from upstream systems. Azure AD group memberships define the ceiling; Vault and SPIRE can only grant subsets.

**Delegation**
The act of one principal authorizing another to act on its behalf. Creates a delegation chain.

**Delegation Chain**
The complete sequence of delegation relationships from the original principal to the current actor.

**Delegation Token**
A token issued via OAuth 2.0 Token Exchange that contains claims about both the subject (original principal) and actor (delegated entity).

**SPIFFE (Secure Production Identity Framework For Everyone)**
A set of open-source standards for workload identity in dynamic environments.

**SPIFFE ID**
A URI-formatted identifier for a workload: `spiffe://trust-domain/path`.

**SVID (SPIFFE Verifiable Identity Document)**
A cryptographically signed document (X.509 certificate or JWT) that proves a workload's SPIFFE identity.

**Trust Domain**
An administrative boundary within SPIFFE. A trust domain has a single root of trust.

**Workload**
Any non-human principal: container, service, pipeline, operator, scheduled job, AI agent.

### Authentication Terms

**AppRole**
A Vault authentication method using role ID and secret ID for machine authentication.

**JWT Auth**
Vault authentication using JSON Web Tokens, often from OIDC providers.

**Kubernetes Auth**
Vault authentication using Kubernetes ServiceAccount tokens.

**mTLS (Mutual TLS)**
TLS where both client and server present certificates for mutual authentication.

**OIDC (OpenID Connect)**
Authentication layer on OAuth 2.0 providing identity verification.

**PSAT (Projected ServiceAccount Token)**
Kubernetes ServiceAccount token projected into a pod with specific audience and expiration.

**Token Exchange (RFC 8693)**
OAuth 2.0 mechanism for exchanging one token for another with different characteristics.

### Infrastructure Terms

**eBPF (extended Berkeley Packet Filter)**
Linux kernel technology used for observability and network control.

**ESO (External Secrets Operator)**
Kubernetes operator that synchronizes secrets from external stores to Kubernetes.

**Linkerd**
A lightweight service mesh providing mTLS and traffic management.

**SPIRE (SPIFFE Runtime Environment)**
Reference implementation of the SPIFFE specification.

**SPIRE Agent**
Component running on each node that attests workloads and delivers SVIDs.

**SPIRE Server**
Central component that issues SVIDs and manages trust bundles.

**tbot**
Teleport Machine ID agent that manages machine certificates.

**Trust Bundle**
Collection of public keys/certificates used to verify identities from a trust domain.

### Kubernetes Terms

**ClusterRole**
Kubernetes RBAC role that applies cluster-wide.

**DaemonSet**
Kubernetes workload that runs one pod per node.

**NetworkPolicy**
Kubernetes resource controlling pod network traffic.

**Role**
Kubernetes RBAC role that applies within a namespace.

**RoleBinding**
Kubernetes resource binding a Role to subjects.

**ServiceAccount**
Kubernetes identity for pods.

### Cloud Terms

**IRSA (IAM Roles for Service Accounts)**
AWS mechanism to associate IAM roles with Kubernetes ServiceAccounts.

**STS (Security Token Service)**
AWS service for issuing temporary security credentials.

**Workload Identity**
GCP/Azure mechanism for pod identity federation.

**Workload Identity Federation**
Cross-cloud identity federation mechanism.

---

## A.2 Diagram Index

All diagrams included in this RFC:

| Diagram Name | Type | Section |
|--------------|------|---------|
| Identity Hierarchy | flowchart | §0 Index |
| Enterprise Identity Model | flowchart | §3.1.1 |
| Identity Layers | flowchart | §3.1.3 |
| Trust Boundary Diagram | flowchart | §3.2.2 |
| Authority Relationships | flowchart | §3.3.2 |
| Workload Bootstrap Flow | sequenceDiagram | §3.4.1 |
| Service-to-Service Flow | sequenceDiagram | §3.4.2 |
| CI/CD Identity Flow | sequenceDiagram | §3.4.3 |
| AI Agent Delegation Flow | sequenceDiagram | §3.4.4 |
| Integration Diagram | flowchart | §3.5.4 |
| Component Relationships | flowchart | §4.1.2 |
| SPIRE Deployment | flowchart | §4.2.6 |
| Vault Agent Integration | flowchart | §4.3.5 |
| Machine Certificate Lifecycle | sequenceDiagram | §4.4.3 |
| Linkerd Authorization Flow | flowchart | §4.5.4 |
| ESO Secret Flow | flowchart | §4.6.2 |
| Cloud Integration | flowchart | §4.7.4 |
| SPIRE Workload Flow | sequenceDiagram | §5.2.4 |
| Vault Auth Flow | sequenceDiagram | §5.3.1 |
| Identity Lifecycle | stateDiagram | §5.5.1 |
| Application Pattern | flowchart | §5.6.1 |
| OIDC Token Flow | sequenceDiagram | §6.1.3 |
| ArgoCD Identity Flow | flowchart | §7.2.5 |
| Token Hierarchy | flowchart | §7.5.2 |
| Controller Deployment | flowchart | §8.2.3 |
| CronJob Identity Flow | sequenceDiagram | §8.3.4 |
| Delegation Flow | sequenceDiagram | §9.2.3 |
| Chain Delegation | flowchart | §9.4.1 |
| Revocation Cascade | flowchart | §9.8.3 |
| tbot Architecture | flowchart | §10.2.3 |
| AWS Attestation | sequenceDiagram | §10.4.2 |
| Machine Secret Access | sequenceDiagram | §10.6.2 |
| mTLS Flow | sequenceDiagram | §11.2.4 |
| Authorization Flow | flowchart | §11.3.4 |
| SPIRE-Linkerd Integration | flowchart | §11.5.2 |
| Federation Relationship | flowchart | §12.2.3 |
| Federation Workflow | sequenceDiagram | §12.2.5 |
| GCP to AWS Federation | flowchart | §12.3.2 |
| Trust Domain Hierarchy | flowchart | §12.4.1 |
| Trust Bundle Lifecycle | stateDiagram | §12.4.3 |

---

## A.3 Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| AAD | Azure Active Directory |
| API | Application Programming Interface |
| ARIA | Agent Relationship-based Identity and Authorization |
| CA | Certificate Authority |
| CI/CD | Continuous Integration/Continuous Delivery |
| CLI | Command Line Interface |
| CNCF | Cloud Native Computing Foundation |
| CRD | Custom Resource Definition |
| DaemonSet | Kubernetes DaemonSet |
| DNS | Domain Name System |
| eBPF | extended Berkeley Packet Filter |
| ESO | External Secrets Operator |
| GCP | Google Cloud Platform |
| HA | High Availability |
| HSM | Hardware Security Module |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | HTTP Secure |
| IAM | Identity and Access Management |
| IdP | Identity Provider |
| IRSA | IAM Roles for Service Accounts |
| JWT | JSON Web Token |
| K8s | Kubernetes |
| KMS | Key Management Service |
| mTLS | Mutual Transport Layer Security |
| OIDC | OpenID Connect |
| OPA | Open Policy Agent |
| PAM | Privileged Access Management |
| PKI | Public Key Infrastructure |
| PSAT | Projected ServiceAccount Token |
| RBAC | Role-Based Access Control |
| RFC | Request for Comments |
| SA | Service Account |
| SAML | Security Assertion Markup Language |
| SPIFFE | Secure Production Identity Framework For Everyone |
| SPIRE | SPIFFE Runtime Environment |
| SSH | Secure Shell |
| STS | Security Token Service |
| SVID | SPIFFE Verifiable Identity Document |
| TLS | Transport Layer Security |
| TPM | Trusted Platform Module |
| TTL | Time To Live |
| UI | User Interface |
| URI | Uniform Resource Identifier |
| VM | Virtual Machine |
| WI | Workload Identity |
| WIF | Workload Identity Federation |
| YAML | YAML Ain't Markup Language |

---

## A.4 ADR Index

Architecture Decision Records documented in this RFC:

| ADR ID | Decision Summary | Section |
|--------|------------------|---------|
| ADR-WI-001 | SPIFFE/SPIRE as primary identity framework | §13.6 |
| ADR-WI-002 | Linkerd for service mesh identity | §13.6 |
| ADR-WI-003 | OAuth 2.0 Token Exchange for AI agents | §13.6 |
| ADR-WI-004 | Vault Kubernetes auth as primary | §13.6 |
| ADR-WI-005 | Teleport Machine ID for VMs | §13.6 |

---

## A.5 Invariant Index

| ID | Category | Summary |
|----|----------|---------|
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
| [← 14. Evolution](./14-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A — RFC-WORKLOAD-IDENTITY-0001*
