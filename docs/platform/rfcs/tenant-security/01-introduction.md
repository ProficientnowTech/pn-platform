```
RFC-TENANT-SECURITY-0001                                         Section 1
Category: Standards Track                                     Introduction
```

# 1. Introduction

[← Index](./00-index.md) | [Index](./00-index.md#table-of-contents) | [Next: Requirements →](./02-requirements.md)

---

## 1.1 Background

Modern cloud-native platforms face persistent threats from automated attacks, data exfiltration attempts, and abuse of exposed services. The OWASP Top 10 documents the most critical web application security risks, while the OWASP API Security Top 10 addresses API-specific threats. Protection against these risks requires multiple layers of defense operating at different points in the traffic flow.

Kubernetes environments introduce additional complexity through their multi-tenant nature. Multiple applications and teams share cluster resources, creating the need for strong isolation between tenants while maintaining operational efficiency. Without explicit network policies, Kubernetes allows unrestricted communication between all pods, violating the principle of least privilege.

The platform security architecture distributes responsibility across multiple RFCs, each governing a specific security domain:

| Domain | RFC | Focus |
|--------|-----|-------|
| Human Identity | RFC-IAM-0001 | Web UI authentication, application authorization |
| Secrets Management | RFC-SECOPS-0001 | Vault-first secret lifecycle |
| Workload Identity | RFC-WORKLOAD-IDENTITY | Service-to-service authentication (East-West) |
| Privileged Access | RFC-PAM-0001 | SSH, database, kubectl access |
| **Tenant Security** | **This RFC** | **External traffic protection, tenant isolation (North-South)** |

This RFC addresses the gap in North-South traffic protection and tenant network isolation.

---

## 1.2 Current State

### 1.2.1 Ingress Infrastructure

The current ingress infrastructure relies on NGINX Ingress Controller, which has announced end-of-life for March 2026. This creates an imperative to evaluate replacement options that can provide both routing and security capabilities.

| Component | State | Concern |
|-----------|-------|---------|
| NGINX Ingress | Deployed | End-of-life March 2026 |
| TLS Termination | cert-manager | Functioning, continue pattern |
| WAF | None | No OWASP protection currently deployed |
| Rate Limiting | Limited | Basic NGINX rate limiting only |

### 1.2.2 Network Policy Enforcement

Calico CNI is deployed and provides network policy enforcement capabilities. However, network policies are not systematically applied across namespaces.

| Aspect | Current State |
|--------|---------------|
| CNI Provider | Calico (deployed) |
| Default Policy | Allow-all (Kubernetes default) |
| Namespace Isolation | Inconsistent |
| Egress Controls | Not enforced |

### 1.2.3 Threat Landscape

Without WAF protection, applications are exposed to common web attacks:

| Threat Category | Current Mitigation | Gap |
|-----------------|-------------------|-----|
| SQL Injection | Application-level only | No network-level filtering |
| Cross-Site Scripting (XSS) | Application-level only | No input validation at ingress |
| Brute Force Attacks | Limited rate limiting | Insufficient protection |
| Bot Traffic | None | No challenge-based verification |
| DDoS | Infrastructure-level | No application-layer protection |

---

## 1.3 Problem Statement

The platform lacks a unified approach to protecting tenant applications from external threats and isolating tenants from each other at the network layer.

### 1.3.1 Security Gaps

| Gap | Impact |
|-----|--------|
| No WAF | OWASP Top 10 attacks reach applications unfiltered |
| No systematic network policies | Lateral movement possible between namespaces |
| No egress controls | Data exfiltration paths exist |
| Limited rate limiting | Vulnerable to abuse and DDoS |
| No bot protection | Automated attacks not mitigated |

### 1.3.2 Operational Gaps

| Gap | Impact |
|-----|--------|
| Ingress end-of-life | NGINX Ingress requires replacement by March 2026 |
| No centralized security management | Security configuration scattered |
| No visibility into blocked threats | Incident response hindered |
| Manual policy creation | Error-prone, inconsistent |

### 1.3.3 Compliance Gaps

| Requirement | Gap |
|-------------|-----|
| SOC 2 CC6.6 | No documented WAF or rate limiting controls |
| PCI DSS 6.6 | WAF required for cardholder data environments |
| ISO 27001 A.13.1 | Network segmentation not systematically enforced |

---

## 1.4 Motivation

This architecture addresses the identified gaps through a unified approach:

### 1.4.1 Unified Ingress and WAF

Deploying BunkerWeb as a combined ingress controller and WAF provides:

| Benefit | Description |
|---------|-------------|
| Single entry point | All external traffic passes through one security layer |
| OWASP CRS protection | Industry-standard rule set for common attacks |
| Bot mitigation | Challenge-based verification (CAPTCHA, JavaScript challenges) |
| Rate limiting | Connection and request limits per client |
| NGINX replacement | Addresses ingress end-of-life requirement |

### 1.4.2 Systematic Network Isolation

Implementing consistent network policies provides:

| Benefit | Description |
|---------|-------------|
| Default-deny posture | Traffic must be explicitly allowed |
| Tenant isolation | Cross-namespace traffic blocked by default |
| Egress controls | Outbound traffic restricted |
| Platform guardrails | Policies that tenants cannot override |

### 1.4.3 Operational Improvements

| Benefit | Description |
|---------|-------------|
| Centralized management | Web UI for WAF rule management |
| GitOps integration | Policies defined in version control |
| Observability | Security events in monitoring stack |
| Compliance evidence | Documented controls for auditors |

---

## 1.5 Scope Statement

This RFC establishes the architecture for:

1. **Web Application Firewall** — OWASP Top 10 protection using BunkerWeb with OWASP Core Rule Set
2. **Ingress Security** — TLS termination, routing, request validation
3. **Rate Limiting** — DDoS mitigation, abuse prevention
4. **Bot Mitigation** — Challenge-based verification for automated threats
5. **Network Policies** — Namespace isolation using Kubernetes NetworkPolicy
6. **Tenant Isolation** — Multi-tenancy segmentation patterns
7. **Egress Controls** — Controlled outbound traffic

This RFC does NOT establish architecture for:

- Service-to-service authentication (see RFC-WORKLOAD-IDENTITY)
- User authentication flows (see RFC-IAM-0001)
- Secret management (see RFC-SECOPS-0001)
- Privileged access management (see RFC-PAM-0001)

---

## 1.6 Success Criteria

The architecture will be considered successful when:

| Criterion | Verification |
|-----------|--------------|
| OWASP Top 10 protection | WAF blocks standard attack payloads in testing |
| Tenant isolation | Cross-namespace traffic denied by default |
| Certificate automation | No manual certificate operations required |
| Observability | All security events visible in monitoring |
| GitOps compliance | All policies managed via Git |
| Compliance readiness | Controls documented for SOC 2, PCI DSS, ISO 27001 |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Index](./00-index.md) | [Table of Contents](./00-index.md#table-of-contents) | [2. Requirements →](./02-requirements.md) |

---

*End of Section 1 — RFC-TENANT-SECURITY-0001*
