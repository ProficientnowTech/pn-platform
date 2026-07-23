```
RFC-PLATARCH-0001                                            Appendix B
Category: Standards Track                                     References
```

# Appendix B: References

[← Glossary](./appendix-a-glossary.md) | [Index](./00-index.md#table-of-contents)

---

## B.1 Standards and Specifications

### 1.1 IETF Standards

**RFC 2119 - Key words for use in RFCs to Indicate Requirement Levels**
https://datatracker.ietf.org/doc/html/rfc2119

Defines the interpretation of MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL as used in this RFC.

**RFC 8174 - Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words**
https://datatracker.ietf.org/doc/html/rfc8174

Clarifies that requirement keywords are only interpreted as defined when they appear in ALL CAPITALS.

### 1.2 Semantic Versioning

**Semantic Versioning 2.0.0**
https://semver.org/spec/v2.0.0.html

The versioning scheme used for capability contracts, base chart versions, and platform APIs. Major.Minor.Patch format with defined compatibility semantics.

---

## 2. Kubernetes Documentation

### 2.1 Core Concepts

**Kubernetes Namespaces**
https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

Foundation for the namespace isolation model described in Section 08.

**Custom Resource Definitions**
https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/

Background for CRD ownership rules described in Section 08.

**Kubernetes Operators**
https://kubernetes.io/docs/concepts/extend-kubernetes/operator/

Background for operator ownership rules and the operator pattern.

### 2.2 Configuration and Security

**ConfigMaps**
https://kubernetes.io/docs/concepts/configuration/configmap/

Non-sensitive configuration management referenced in Section 07.

**Secrets**
https://kubernetes.io/docs/concepts/configuration/secret/

Foundation for secret management rules described in Section 07.

**Network Policies**
https://kubernetes.io/docs/concepts/services-networking/network-policies/

Foundation for network isolation requirements described in Section 08.

**RBAC Authorization**
https://kubernetes.io/docs/reference/access-authn-authz/rbac/

Foundation for access control isolation described in Section 08.

### 2.3 Workload Resources

**Deployments**
https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

Standard workload type for platform applications.

**StatefulSets**
https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

Workload type for stateful infrastructure components.

---

## 3. GitOps and ArgoCD

### 3.1 GitOps Principles

**GitOps Principles**
https://opengitops.dev/

The Open GitOps project defining GitOps principles that inform this RFC's Git-as-source-of-truth approach.

**Weaveworks GitOps**
https://www.weave.works/technologies/gitops/

Original GitOps concept from Weaveworks, informing declarative infrastructure management.

### 3.2 ArgoCD Documentation

**ArgoCD Overview**
https://argo-cd.readthedocs.io/en/stable/

Official ArgoCD documentation. Foundation for ArgoCD usage described in Section 09.

**ArgoCD Application**
https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/

ArgoCD Application resource specification.

**ArgoCD Projects**
https://argo-cd.readthedocs.io/en/stable/user-guide/projects/

ArgoCD AppProject documentation. Foundation for project governance in Section 08.

**ArgoCD Sync Waves**
https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/

Sync wave documentation. Referenced in rationale for why sync waves alone are insufficient.

**ArgoCD Resource Health**
https://argo-cd.readthedocs.io/en/stable/operator-manual/health/

Health check documentation. Referenced in discussion of semantic readiness vs. resource health.

---

## 4. Helm Documentation

**Helm - The Kubernetes Package Manager**
https://helm.sh/docs/

Foundation for base chart implementation.

**Helm Chart Dependencies**
https://helm.sh/docs/chart_best_practices/dependencies/

How applications include the base chart as a dependency.

**Helm Values Files**
https://helm.sh/docs/chart_template_guide/values_files/

Configuration mechanism for base chart integration.

---

## 5. Security References

### 5.1 TLS and Certificates

**Let's Encrypt**
https://letsencrypt.org/

Automated certificate authority referenced for external TLS.

**cert-manager**
https://cert-manager.io/docs/

Kubernetes certificate management. Referenced platform component for certificate lifecycle.

### 5.2 Secret Management

**External Secrets Operator**
https://external-secrets.io/

External secret integration pattern for platform secret management.

**HashiCorp Vault**
https://developer.hashicorp.com/vault/docs

Enterprise secret management referenced as potential backing store.

### 5.3 Identity

**Keycloak**
https://www.keycloak.org/documentation

Identity and access management. Referenced platform identity service.

**OpenID Connect**
https://openid.net/specs/openid-connect-core-1_0.html

Identity protocol specification for platform identity integration.

---

## 6. Observability References

**Prometheus**
https://prometheus.io/docs/introduction/overview/

Metrics collection and monitoring.

**Grafana**
https://grafana.com/docs/grafana/latest/

Metrics visualization and dashboards.

**OpenTelemetry**
https://opentelemetry.io/docs/

Observability framework for traces, metrics, and logs.

---

## 7. Infrastructure Components

### 7.1 Databases

**PostgreSQL**
https://www.postgresql.org/docs/

Relational database referenced as shared infrastructure example.

**Redis**
https://redis.io/docs/

Key-value store referenced as shared infrastructure example.

### 7.2 Messaging

**RabbitMQ**
https://www.rabbitmq.com/documentation.html

Message queue referenced as shared infrastructure example.

**Apache Kafka**
https://kafka.apache.org/documentation/

Event streaming platform referenced as shared infrastructure example.

---

## 8. Design Patterns and Principles

### 8.1 Software Architecture

**Twelve-Factor App**
https://12factor.net/

Application design principles that align with platform requirements, particularly around configuration, dependencies, and statelessness.

**Principle of Least Privilege**
https://csrc.nist.gov/glossary/term/least_privilege

Security principle underlying permission minimization requirements.

### 8.2 Distributed Systems

**Idempotency in Distributed Systems**
https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/

Background on idempotency requirements for event handling.

**Event-Driven Architecture**
https://martinfowler.com/articles/201701-event-driven.html

Background on event model design.

---

## B.9 Platform RFC Internal References

### B.9.1 Normative References (This RFC Defers To)

These RFCs are authoritative for their respective domains. RFC-PLATARCH-0001 declares requirements; these RFCs specify implementation.

| RFC | Title | Domain | Relationship |
|-----|-------|--------|--------------|
| [RFC-SECOPS-0001](../secret-ops/00-index.md) | GitOps-Native, Vault-First Secret Management | Secrets Management | Authoritative for secret lifecycle, rotation, and distribution |
| [RFC-DEPLOY-0001](../deploy-ops/00-index.md) | Deployment Orchestration | Deployment | Authoritative for deployment mechanics using Argo Workflows |

### B.9.2 Informative References (Domain-Specific Extensions)

These RFCs extend this architecture for specific domains.

| RFC | Title | Domain | Relationship |
|-----|-------|--------|--------------|
| [RFC-IAM-0001](../iam/00-index.md) | Federated Identity and Access Management | Web Authentication | Keycloak SSO for human web authentication |
| [RFC-WORKLOAD-IDENTITY-0001](../workload-identity/01-introduction.md) | Workload Identity | Service Identity | SPIFFE/SPIRE attestation-based workload identity |
| [RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md) | Tenant Security | Network Security | WAF, network policies, ingress protection |
| [RFC-PAM-0001](../pam/00-index.md) | Privileged Access Management | Infrastructure Access | Teleport-based SSH, database, kubectl access |
| [RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md) | Developer Platform | Developer Portal | Backstage-based capability discovery and provisioning |

### B.9.3 Preliminary Documents (Superseded)

This RFC consolidates and supersedes the following preliminary documents:

| Document | Title | Status |
|----------|-------|--------|
| RFC-P1-01 through P1-10 | Capability Orchestration Model | Superseded by this RFC |
| RFC-P2-01 through P2-06 | Shared Infrastructure Model | Superseded by this RFC |
| RFC-P3-01 through P3-07 | Application Model | Superseded by this RFC |
| RFC-P4-01 through P4-06 | Platform Governance | Superseded by this RFC |

### B.9.4 Related Platform Documentation

| Document | Description |
|----------|-------------|
| Platform Authoring Standards | Standards for RFC document structure |
| Base Chart Documentation | Implementation documentation for the base chart |
| Capability Catalog | Registry of available platform capabilities |

---

## 10. Change Log

| Date | Description |
|------|-------------|
| 2026-02-17 | Initial RFC creation consolidating P1-P4 documents |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-PLATARCH-0001*
