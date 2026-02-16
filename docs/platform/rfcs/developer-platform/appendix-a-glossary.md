```
RFC-DEVELOPER-PLATFORM-0001                                      Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Evolution](./15-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: Appendix B →](./appendix-b-references.md)

---

## A.1 Term Definitions

### A.1.1 Portal Terms

| Term | Definition |
|------|------------|
| **Backstage** | Open-source developer portal framework from Spotify, now CNCF Incubating |
| **Capability-Based UI** | Authorization model where users see only actions they can perform |
| **Developer Portal** | Unified interface for developer interactions with platform |
| **Golden Path** | Opinionated template encoding organizational best practices |
| **Internal Developer Platform (IDP)** | Platform providing self-service capabilities to developers |
| **Plugin** | Backstage extension providing additional functionality |
| **Scaffolder** | Backstage component for template-based project creation |
| **Software Catalog** | Central registry of all software entities in the organization |
| **TechDocs** | Backstage documentation-as-code feature |

### A.1.2 Entity Terms

| Term | Definition |
|------|------------|
| **API** | Catalog entity representing an interface exposed by a component |
| **Component** | Catalog entity representing a piece of software |
| **Domain** | Catalog entity representing a business domain grouping |
| **Entity** | Any object registered in the Software Catalog |
| **Group** | Catalog entity representing a team or organizational unit |
| **Ownership** | Relationship assigning responsibility for an entity to a team or user |
| **Resource** | Catalog entity representing infrastructure (database, queue, etc.) |
| **System** | Catalog entity representing a collection of related components |
| **User** | Catalog entity representing an individual user |

### A.1.3 Authorization Terms

| Term | Definition |
|------|------------|
| **Authorization Ceiling** | Maximum permissions defined by Azure AD that cannot be exceeded |
| **Claim** | Attribute in a token (groups, roles) used for authorization decisions |
| **Conjunctive Authorization** | Authorization model where multiple systems must agree (AND logic) |
| **Permission Framework** | Backstage system for evaluating authorization decisions |
| **Token** | OIDC token containing identity and permission claims |

### A.1.4 Self-Service Terms

| Term | Definition |
|------|------------|
| **Approval Workflow** | Process requiring approval before action execution |
| **Crossplane Claim** | Kubernetes resource requesting infrastructure from Crossplane |
| **Environment Tier** | Classification of environment (dev, staging, production) |
| **GitOps Output** | Template output committed to Git for reconciliation |
| **JIT Access** | Just-In-Time access providing time-limited credentials |
| **Self-Service** | Actions developers can perform without platform team involvement |
| **Template** | Backstage Software Template for scaffolding projects or resources |

### A.1.5 Integration Terms

| Term | Definition |
|------|------------|
| **Deep Link** | URL that navigates directly to a specific resource in a tool |
| **SSO** | Single Sign-On enabling authentication across multiple tools |
| **Tool Library** | Portal feature providing permission-aware links to platform tools |

### A.1.6 Event Streaming Terms

| Term | Definition |
|------|------------|
| **Apicurio Registry** | Schema registry for event schemas |
| **CDC** | Change Data Capture, streaming database changes to Kafka |
| **Consumer Lag** | Number of messages a consumer is behind |
| **Debezium** | CDC platform for capturing database changes |
| **Kafka Connect** | Framework for connecting Kafka with external systems |
| **Kafka Topic** | Named stream of records in Kafka |
| **Schema Compatibility** | Rules for schema evolution (backward, forward, full) |

---

## A.2 Diagram Index

| Diagram | Section | Description |
|---------|---------|-------------|
| High-Level Architecture | 3.1.1 | System overview showing portal and integrations |
| Trust Boundary Diagram | 3.2.1 | Security zones and boundaries |
| Authority Hierarchy | 3.3.1 | Authorization authority relationships |
| Authentication Flow | 3.4.1 | Keycloak authentication sequence |
| Self-Service Provisioning Flow | 3.4.2 | Template execution to resource creation |
| JIT Access Request Flow | 3.4.3 | Access request through Teleport |
| Backstage Plugin Architecture | 4.3.1 | Frontend and backend plugin structure |
| Entity Relationships | 5.1.3 | Catalog entity relationship model |
| Discovery Flow | 5.2.2 | Entity discovery and processing |
| Entity Lifecycle | 5.6.3 | Entity state transitions |
| GitOps Output Flow | 6.4.1 | Template output to resource reconciliation |
| TechDocs Build Process | 7.2.3 | Documentation build and storage |
| Permission Evaluation | 8.1.3 | Token to UI visibility flow |
| Claim Hierarchy | 8.2.2 | Azure AD to Backstage permission flow |
| Permission Filter Flow | 8.4.2 | UI component filtering sequence |
| Database Provisioning Workflow | 9.3.1 | Database creation flow |
| Crossplane Provisioning Flow | 9.4.3 | Claim to resource creation |
| Access Request Workflow | 10.3.1 | JIT access request sequence |
| Access Request States | 10.3.4 | Request state machine |
| Deep Link Generation | 11.2.3 | Entity to URL generation |
| SSO Authentication Flow | 11.3.1 | Tool authentication sequence |
| Kafka Topic Creation | 12.1.2 | Topic provisioning flow |
| Schema Validation Workflow | 12.2.4 | Schema compatibility check |
| Schema Entity Relationships | 12.5.2 | Event streaming entity model |
| ArgoCD Integration Flow | 13.2.2 | ArgoCD data retrieval |
| Harbor Integration Flow | 13.4.2 | Harbor data retrieval |

---

## A.3 Invariant Index

| ID | Statement | Section |
|----|-----------|---------|
| INV-1 | All developer portal authentication MUST flow through Keycloak | 2.4 |
| INV-2 | Portal authorization MUST use capability-based UI rendering | 2.4 |
| INV-3 | Backstage permission decisions MUST derive from Keycloak token claims | 2.4 |
| INV-4 | All self-service actions MUST produce Git commits | 2.4 |
| INV-5 | Software Templates MUST follow organizational golden paths | 2.4 |
| INV-6 | Self-service workflows MUST operate within platform guardrails | 2.4 |
| INV-7 | Catalog entities MUST have defined ownership | 2.4 |
| INV-8 | Documentation MUST be co-located with code | 2.4 |
| INV-9 | Database credentials MUST be short-lived | 2.4 |
| INV-10 | Tool links MUST respect user authorization boundaries | 2.4 |
| INV-11 | Production restore operations MUST require approval workflow | 2.4 |
| INV-12 | Schema changes MUST pass compatibility validation | 2.4 |
| INV-13 | All privileged access MUST be session-recorded | 2.4 |
| INV-14 | Plugin extensions MUST integrate with permission framework | 2.4 |
| INV-15 | Plugins MUST NOT bypass the Keycloak authentication chain | 2.4 |

---

## A.4 Acronyms

| Acronym | Expansion |
|---------|-----------|
| API | Application Programming Interface |
| CDC | Change Data Capture |
| CI/CD | Continuous Integration / Continuous Deployment |
| CNCF | Cloud Native Computing Foundation |
| CRD | Custom Resource Definition |
| ESO | External Secrets Operator |
| GitOps | Git-based Operations |
| HA | High Availability |
| IAM | Identity and Access Management |
| IDP | Internal Developer Platform |
| JIT | Just-In-Time |
| JWT | JSON Web Token |
| K8s | Kubernetes |
| OIDC | OpenID Connect |
| PAM | Privileged Access Management |
| PVC | Persistent Volume Claim |
| RBAC | Role-Based Access Control |
| REST | Representational State Transfer |
| RFC | Request for Comments |
| SPA | Single Page Application |
| SSO | Single Sign-On |
| TLS | Transport Layer Security |
| TOC | Table of Contents |
| UI | User Interface |
| URL | Uniform Resource Locator |
| VM | Virtual Machine |
| WAF | Web Application Firewall |
| XR | Composite Resource (Crossplane) |
| XRD | Composite Resource Definition (Crossplane) |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 15. Evolution](./15-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A — RFC-DEVELOPER-PLATFORM-0001*
