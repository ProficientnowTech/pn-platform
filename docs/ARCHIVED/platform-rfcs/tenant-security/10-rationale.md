```
RFC-TENANT-SECURITY-0001                                        Section 10
Category: Standards Track                                        Rationale
```

# 10. Rationale

[← Tenant Isolation](./09-tenant-isolation.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution →](./11-evolution.md)

---

## 10.1 Overview

This section documents the key architectural decisions, alternatives considered, and rationale for selections made in this RFC. Each decision references the invariants it supports.

---

## 10.2 WAF Solution Selection

### 10.2.1 Decision

**Selected: BunkerWeb**

BunkerWeb is selected as the unified ingress controller and Web Application Firewall.

### 10.2.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| SafeLine | ML-based semantic analysis WAF |
| Coraza | Go-based WAF library for Envoy |
| ModSecurity | Traditional WAF engine |

### 10.2.3 Evaluation Criteria

| Criterion | Weight | Rationale |
|-----------|--------|-----------|
| OWASP CRS Compatibility | High | Industry standard, auditable rules |
| Kubernetes Native | High | Operational simplicity |
| Open Source (Free) | High | No licensing costs or app limits |
| Ingress Replacement | Medium | Address NGINX Ingress retirement |
| Management UI | Medium | Operational efficiency |
| Rule Transparency | High | Security auditability |

### 10.2.4 Comparison

| Criterion | BunkerWeb | SafeLine | Coraza | ModSecurity |
|-----------|-----------|----------|--------|-------------|
| OWASP CRS | Integrated | Not compatible | Compatible | Native |
| Kubernetes | Helm + Ingress | Docker-first | Envoy plugin | NGINX module |
| License | AGPLv3 (free) | GPL-3.0 (10 app limit) | Apache 2.0 | Apache 2.0 |
| UI | Web UI | Web UI | None | None |
| Transparency | Auditable | Black-box | Auditable | Auditable |
| Ingress | Can replace | No | No | No |
| Status | Active | Active | Active | Maintenance |

### 10.2.5 Decision Rationale

BunkerWeb was selected because:

| Factor | Rationale | Invariant Support |
|--------|-----------|-------------------|
| OWASP CRS integration | Industry-standard rules, auditable by security teams | INV-1 |
| Kubernetes-native | Helm chart, Ingress controller capability | Operational |
| Unlimited free tier | No artificial app limits unlike SafeLine | Cost |
| Rule transparency | OWASP CRS rules are publicly documented | INV-9, INV-13 |
| Ingress replacement | Solves NGINX retirement requirement | Operational |
| Web UI | Reduces operational burden | Operational |

### 10.2.6 Rejected Alternatives

**SafeLine Rejected Because:**

| Reason | Impact |
|--------|--------|
| No OWASP CRS compatibility | Cannot use industry-standard rules |
| Proprietary semantic engine | Rules are not auditable (black box) |
| 10 app limit (free tier) | Would require paid tier for production |
| Docker-first | Kubernetes deployment requires workarounds |

**Coraza Rejected Because:**

| Reason | Impact |
|--------|--------|
| Library only | Requires separate ingress integration |
| No management UI | Higher operational burden |
| Envoy-focused | Better suited for Envoy Gateway, not current stack |

**ModSecurity Rejected Because:**

| Reason | Impact |
|--------|--------|
| End-of-life (July 2024) | No active development |
| No standalone deployment | Requires NGINX/Apache integration |

---

## 10.3 Ingress Architecture

### 10.3.1 Decision

**Selected: BunkerWeb as Combined Ingress + WAF**

Rather than separate ingress controller and WAF, BunkerWeb serves both functions.

### 10.3.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| NGINX Ingress + Separate WAF | Traditional separation |
| Gateway API + Coraza | Modern API with WAF plugin |
| Service Mesh Ingress | Linkerd or Istio ingress |

### 10.3.3 Decision Rationale

| Factor | Rationale |
|--------|-----------|
| Unified solution | Single component to manage |
| NGINX Ingress retirement | Needs replacement by March 2026 |
| Reduced complexity | Fewer moving parts |
| Consistent security | WAF always in path (INV-1) |

### 10.3.4 Rejected Alternatives

**NGINX Ingress + Separate WAF Rejected Because:**

| Reason | Impact |
|--------|--------|
| NGINX Ingress end-of-life | March 2026 retirement |
| Two components to manage | Increased complexity |
| Potential bypass | WAF could be misconfigured |

**Gateway API + Coraza Rejected Because:**

| Reason | Impact |
|--------|--------|
| Increased complexity | Two separate components |
| No management UI | Higher operational burden |
| Current stack mismatch | Envoy not deployed |

---

## 10.4 Network Policy Model

### 10.4.1 Decision

**Selected: Kubernetes NetworkPolicy (Standard API)**

Use standard Kubernetes NetworkPolicy resources rather than CNI-specific CRDs.

### 10.4.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| Calico-specific policies | CiliumNetworkPolicy or Calico CRDs |
| Service mesh policies | Linkerd AuthorizationPolicy |

### 10.4.3 Decision Rationale

| Factor | Rationale | Invariant Support |
|--------|-----------|-------------------|
| Portability | Standard API works with any CNI | Operational |
| Simplicity | Well-understood API | Operational |
| Calico support | Calico fully supports NetworkPolicy | INV-5, INV-6, INV-7 |
| GitOps friendly | Standard resources sync easily | INV-12 |

### 10.4.4 Rejected Alternatives

**Calico-Specific Policies Rejected Because:**

| Reason | Impact |
|--------|--------|
| Vendor lock-in | Tied to Calico CNI |
| Complexity | Additional API to learn |
| Standard sufficiency | NetworkPolicy meets requirements |

**Service Mesh Policies Rejected Because:**

| Reason | Impact |
|--------|--------|
| Different layer | Mesh handles East-West only |
| Scope overlap | Would duplicate network policy function |
| RFC boundary | Service mesh in RFC-WORKLOAD-IDENTITY |

---

## 10.5 Rate Limiting Location

### 10.5.1 Decision

**Selected: Gateway-Level (BunkerWeb)**

Rate limiting is implemented at the ingress layer.

### 10.5.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| Application-level | Each application implements limits |
| Both gateway and application | Defense in depth |

### 10.5.3 Decision Rationale

| Factor | Rationale |
|--------|-----------|
| Single enforcement point | Consistent behavior |
| Early rejection | Saves backend resources |
| Centralized management | Easier to configure and monitor |
| Application simplicity | Applications don't need rate limit logic |

### 10.5.4 When Application-Level is Appropriate

Application-level rate limiting MAY be added when:

| Scenario | Rationale |
|----------|-----------|
| User-specific quotas | Gateway doesn't know user identity |
| Complex business rules | Custom logic required |
| Fine-grained control | Per-operation limits |

---

## 10.6 Certificate Authority

### 10.6.1 Decision

**Selected: Let's Encrypt via cert-manager**

Automated certificate issuance from Let's Encrypt.

### 10.6.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| Vault PKI | Internal CA from Vault |
| Hybrid | Let's Encrypt external, Vault internal |

### 10.6.3 Decision Rationale

| Factor | Rationale | Invariant Support |
|--------|-----------|-------------------|
| Automation | Fully automated lifecycle | INV-3, INV-14 |
| Trust | Publicly trusted certificates | — |
| Cost | Free certificates | Cost |
| Integration | cert-manager well-supported | Operational |

### 10.6.4 When Vault PKI is Appropriate

Vault PKI MAY be used for:

| Scenario | Rationale |
|----------|-----------|
| Internal services | Not exposed to internet |
| mTLS | Service-to-service (RFC-WORKLOAD-IDENTITY) |
| Custom validity | Specific certificate lifetimes |

---

## 10.7 Bot Mitigation Strategy

### 10.7.1 Decision

**Selected: Challenge-Based Verification**

Use progressive challenges (cookie, JavaScript, CAPTCHA) for bot detection.

### 10.7.2 Alternatives Considered

| Alternative | Description |
|-------------|-------------|
| ML-based detection | Machine learning models |
| IP reputation only | Block known bad IPs |

### 10.7.3 Decision Rationale

| Factor | Rationale |
|--------|-----------|
| User experience | Progressive challenges minimize friction |
| Flexibility | Multiple challenge providers supported |
| Transparency | Challenge logic is understandable |
| Integration | BunkerWeb supports multiple providers |

---

## 10.8 Decision Summary

| Decision Area | Selection | Key Rationale |
|---------------|-----------|---------------|
| WAF | BunkerWeb | OWASP CRS, Kubernetes-native, free |
| Ingress | BunkerWeb (combined) | Unified solution, replaces NGINX |
| Network Policy | Kubernetes NetworkPolicy | Standard API, portable |
| Rate Limiting | Gateway-level | Centralized, early rejection |
| Certificates | Let's Encrypt + cert-manager | Automated, free, trusted |
| Bot Mitigation | Challenge-based | Progressive, flexible |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 9. Tenant Isolation](./09-tenant-isolation.md) | [Table of Contents](./00-index.md#table-of-contents) | [11. Evolution →](./11-evolution.md) |

---

*End of Section 10 — RFC-TENANT-SECURITY-0001*
