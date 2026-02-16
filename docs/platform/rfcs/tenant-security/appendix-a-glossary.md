```
RFC-TENANT-SECURITY-0001                                        Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Evolution](./11-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: Appendix B →](./appendix-b-references.md)

---

## A.1 Terms and Definitions

### A.1.1 Security Terms

| Term | Definition |
|------|------------|
| **Bot** | Automated software that interacts with web services, potentially for malicious purposes |
| **Brute Force Attack** | Attack method using repeated attempts to guess credentials |
| **CAPTCHA** | Challenge-response test to determine whether a user is human |
| **Circuit Breaker** | Pattern that stops requests to a failing service to prevent cascade failures |
| **Cross-Site Scripting (XSS)** | Attack injecting malicious scripts into web pages |
| **DDoS** | Distributed Denial of Service; attack overwhelming services with traffic |
| **Defense in Depth** | Security strategy using multiple layers of protection |
| **DNSBL** | DNS-based Blackhole List; IP reputation service via DNS |
| **Egress** | Outbound network traffic from a pod or namespace |
| **False Positive** | Legitimate request incorrectly identified as malicious |
| **Guardrail** | Security policy that cannot be overridden by tenants |
| **Ingress** | Inbound network traffic to a pod or namespace |
| **Lateral Movement** | Attacker technique of moving between systems after initial compromise |
| **mTLS** | Mutual TLS; both client and server authenticate via certificates |
| **OWASP** | Open Web Application Security Project |
| **Rate Limiting** | Controlling the rate of requests to prevent abuse |
| **SQL Injection** | Attack inserting malicious SQL into application queries |
| **SSRF** | Server-Side Request Forgery; attack making server request internal resources |
| **Token Bucket** | Algorithm for rate limiting allowing burst traffic |
| **Trust Boundary** | Point where security context changes |
| **WAF** | Web Application Firewall |
| **Zero Trust** | Security model assuming no implicit trust |

### A.1.2 Kubernetes Terms

| Term | Definition |
|------|------------|
| **CNI** | Container Network Interface; plugin for container networking |
| **CRD** | Custom Resource Definition; extends Kubernetes API |
| **DaemonSet** | Ensures pod runs on all (or selected) nodes |
| **Ingress** | Kubernetes API for HTTP routing to services |
| **Namespace** | Virtual cluster for resource isolation |
| **NetworkPolicy** | Kubernetes resource controlling pod network traffic |
| **Pod** | Smallest deployable unit in Kubernetes |
| **Service** | Kubernetes abstraction for exposing applications |

### A.1.3 Architecture Terms

| Term | Definition |
|------|------------|
| **East-West Traffic** | Traffic between services within the cluster |
| **North-South Traffic** | Traffic between external clients and cluster services |
| **Tenant** | Organization or team with isolated resources |
| **Workload** | Application or service running in the cluster |

### A.1.4 Technology Terms

| Term | Definition |
|------|------------|
| **BunkerWeb** | Open-source WAF and ingress controller |
| **Calico** | CNI plugin providing networking and network policy |
| **cert-manager** | Kubernetes certificate management controller |
| **OWASP CRS** | OWASP Core Rule Set; standard WAF rules |
| **Let's Encrypt** | Free, automated certificate authority |
| **Linkerd** | Service mesh for Kubernetes |

---

## A.2 Acronyms

| Acronym | Expansion |
|---------|-----------|
| ACME | Automatic Certificate Management Environment |
| API | Application Programming Interface |
| CA | Certificate Authority |
| CDN | Content Delivery Network |
| CIDR | Classless Inter-Domain Routing |
| CNI | Container Network Interface |
| CRD | Custom Resource Definition |
| CRS | Core Rule Set |
| CSP | Content Security Policy |
| DDoS | Distributed Denial of Service |
| DNS | Domain Name System |
| DNSBL | DNS-based Blackhole List |
| ESO | External Secrets Operator |
| HSTS | HTTP Strict Transport Security |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | HTTP Secure |
| IAM | Identity and Access Management |
| IP | Internet Protocol |
| JWT | JSON Web Token |
| LB | Load Balancer |
| ML | Machine Learning |
| mTLS | Mutual Transport Layer Security |
| OIDC | OpenID Connect |
| OWASP | Open Web Application Security Project |
| PAM | Privileged Access Management |
| PKI | Public Key Infrastructure |
| RBAC | Role-Based Access Control |
| RFC | Request for Comments |
| SIEM | Security Information and Event Management |
| SNI | Server Name Indication |
| SQL | Structured Query Language |
| SSRF | Server-Side Request Forgery |
| TLS | Transport Layer Security |
| UI | User Interface |
| URL | Uniform Resource Locator |
| WAF | Web Application Firewall |
| XSS | Cross-Site Scripting |

---

## A.3 Diagram Index

| Diagram | Section | Description |
|---------|---------|-------------|
| Defense-in-Depth Model | 0 (Index) | Security layer overview |
| System Overview | 3.1 | Complete traffic flow |
| Traffic Flow States | 3.2.3 | Request state transitions |
| Trust Boundaries | 3.3.1 | Trust zones and boundaries |
| Authority Hierarchy | 3.4.2 | Policy authority structure |
| Inbound Request Flow | 3.5.1 | Sequence diagram of request processing |
| Cross-Namespace Request Flow | 3.5.2 | Sequence diagram of cross-namespace traffic |
| RFC Integration Points | 3.6.1 | Integration with other RFCs |
| Component Overview | 4.1 | Primary components |
| Request Processing Sequence | 4.5.1 | Component interaction sequence |
| TLS Termination Flow | 5.1.1 | Single entry point diagram |
| Certificate Lifecycle | 5.2.2 | Certificate state transitions |
| Backend Communication | 5.5.1 | Ingress to service flow |
| WAF Processing | 6.1.1 | WAF decision flow |
| Rule Hierarchy | 6.2.1 | WAF rule layers |
| Mode Transitions | 6.3.2 | WAF mode state diagram |
| Exception Lifecycle | 6.4.2 | Exception state transitions |
| Challenge Flow | 6.5.3 | Bot challenge sequence |
| Network Policy Overview | 7.1.1 | Namespace isolation |
| Policy Layers | 7.2.1 | Policy hierarchy |
| Cross-Namespace Flow | 7.4.3 | Bilateral policy requirement |
| Egress Control Model | 7.5.1 | Egress destinations |
| Policy Management Flow | 7.7.1 | Policy lifecycle |
| Rate Limiting Flow | 8.1.1 | Rate limit decision |
| Token Bucket | 8.4.1 | Token bucket state |
| Circuit Breaker | 8.7.3 | Circuit breaker states |
| Multi-Tenancy Model | 9.1.1 | Tenant boundaries |
| Strict Isolation | 9.3.2 | Strict isolation pattern |
| Cross-Tenant Flow | 9.4.3 | Cross-tenant sequence |
| Platform Access | 9.5.2 | Platform service access |
| Onboarding Flow | 9.6.3 | Tenant onboarding |
| Offboarding Flow | 9.7.2 | Tenant offboarding |
| Gateway API Migration | 11.2.4 | Migration path |

---

## A.4 Invariant Index

| ID | Statement | Section |
|----|-----------|---------|
| INV-1 | All external HTTP/HTTPS traffic MUST pass through WAF | 2.3.1 |
| INV-2 | All public endpoints MUST use TLS 1.2+ | 2.3.1 |
| INV-3 | Certificate provisioning MUST be automated | 2.3.1 |
| INV-4 | WAF rules MUST operate in detection before enforcement | 2.3.1 |
| INV-5 | All tenant namespaces MUST have default-deny ingress | 2.3.2 |
| INV-6 | Cross-namespace traffic MUST be explicitly authorized | 2.3.2 |
| INV-7 | Egress to internet MUST be controlled | 2.3.2 |
| INV-8 | Platform guardrails MUST NOT be overridable | 2.3.2 |
| INV-9 | All blocked requests MUST be logged | 2.3.3 |
| INV-10 | Network flows MUST be observable | 2.3.3 |
| INV-11 | WAF events MUST integrate with monitoring | 2.3.3 |
| INV-12 | Network policies MUST be in Git | 2.3.4 |
| INV-13 | WAF customizations MUST be version controlled | 2.3.4 |
| INV-14 | TLS secrets MUST be automated | 2.3.4 |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 11. Evolution](./11-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A — RFC-TENANT-SECURITY-0001*
