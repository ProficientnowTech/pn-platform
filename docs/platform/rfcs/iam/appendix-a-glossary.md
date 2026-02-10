```
RFC-IAM-0001                                                 Appendix A
Category: Standards Track                                   Glossary
```

# Appendix A: Glossary

[← Previous: Evolution](./10-evolution.md) | [Index](./00-index.md#table-of-contents) | [Next: Appendix B →](./appendix-b-references.md)

---

## A.1 Term Definitions

### Identity and Authentication Terms

**Access Token**
A token issued by Keycloak that grants access to protected resources. Contains claims about the user's identity and permissions. Validated by applications to authorize requests.

**Authentication**
The process of verifying a user's identity. In this architecture, authentication flows through Azure AD to Keycloak to applications.

**Authentication Chain**
The sequence of authentication validations: Azure AD verifies user identity, Keycloak receives the assertion, applications validate Keycloak tokens. As used in this RFC, the chain represents the mandatory flow through which all authentication MUST pass.

**Authorization**
The process of determining whether an authenticated user can perform a requested action. Derived from Keycloak token claims which are constrained by Azure AD group memberships.

**Authorization Ceiling**
The principle that downstream systems cannot grant permissions exceeding those available from upstream systems. Azure AD group memberships define the ceiling; Keycloak and applications can only grant subsets.

**Claim**
An assertion about a subject contained in a token. Examples include user identity, group memberships, and roles.

**Federation**
The process of linking identity systems so that authentication in one system is recognized by another. Azure AD federates with Keycloak through OIDC.

**Identity Provider (IdP)**
A system that authenticates users and issues identity assertions. Azure AD is the enterprise IdP; Keycloak is the platform IdP.

**JWKS (JSON Web Key Set)**
A set of cryptographic keys used to verify token signatures. Applications retrieve JWKS from identity providers to validate tokens.

**OIDC (OpenID Connect)**
An authentication protocol built on OAuth 2.0. Used for federation between Azure AD and Keycloak, and between Keycloak and applications.

**Principal**
An entity (user or service) that can be authenticated and authorized. Users authenticate through OIDC; services authenticate through service accounts.

**Realm**
A Keycloak concept representing an isolated namespace for identity management. Contains users, roles, clients, and configuration.

**Refresh Token**
A token used to obtain new access tokens without re-authentication. Managed by Keycloak with configurable expiration policies.

**Role**
A named set of permissions. Keycloak roles are mapped from Azure AD groups and included in tokens for application authorization.

**Session**
A stateful authentication context maintained by Keycloak. Sessions have configurable lifetimes and can be terminated for security purposes.

**Token**
A cryptographically signed data structure asserting claims about a subject. ID tokens assert identity; access tokens assert permissions.

### Secrets Management Terms

**Note**: For comprehensive secrets management terminology, see [RFC-SECOPS-0001 Appendix A](../secret-ops/appendix-a-glossary.md). This section defines only terms specific to the identity-secrets intersection.

**Dynamic Secret**
A secret generated on-demand with a limited lifetime. Vault can generate dynamic secrets for databases and cloud providers.

**External Secrets Operator (ESO)**
A Kubernetes operator that synchronizes secrets from external secret stores (Vault) to Kubernetes Secrets.

**Identity-Bound Secret**
A secret whose existence, validity, or access authorization is tied to an identity managed by the IAM system. As used in this RFC, identity-bound secrets include Keycloak client secrets, service-to-service tokens, and user-specific API tokens. Their lifecycle is coupled to the identity they are bound to.

**ExternalSecret**
A Kubernetes custom resource defining a secret requirement. ESO watches ExternalSecrets and creates corresponding Kubernetes Secrets.

**Secret**
Sensitive data that must be protected (credentials, API keys, certificates). As used in this RFC, secrets MUST be stored in Vault and distributed through ESO.

**SecretStore**
A Kubernetes custom resource defining connection parameters to an external secret store (Vault).

**Vault**
HashiCorp Vault, the secrets management system. Serves as the single authoritative source for all platform secrets.

**Vault Policy**
A rule set defining which identities can access which secret paths with which capabilities.

### Infrastructure and GitOps Terms

**ArgoCD**
A GitOps continuous delivery tool that synchronizes Kubernetes cluster state with Git repository definitions.

**Composition**
A Crossplane concept for bundling multiple managed resources into a single claimable unit.

**Crossplane**
A Kubernetes-native infrastructure provisioning tool. Extends Kubernetes to manage external resources through declarative definitions.

**GitOps**
An operational model where Git serves as the source of truth for infrastructure and application configuration. Changes are applied by reconciling cluster state with Git state.

**Helm Chart**
A package of Kubernetes resource templates. Used to define application deployments and associated resources.

**Managed Resource**
A Crossplane custom resource representing an external resource (registry project, database schema, etc.). Crossplane reconciles managed resources with target systems.

**Provider**
A Crossplane component that implements resource management for a specific system (registry provider, Vault provider, etc.).

**ProviderConfig**
A Crossplane resource specifying connection parameters for a provider, including credentials.

**Reconciliation**
The process of comparing declared state (in Git/Kubernetes) with actual state (in target systems) and making corrections to achieve consistency.

### Application Terms

**Container Registry**
A service that stores and distributes container images, typically with features like vulnerability scanning and access control. Examples include Harbor and Docker Registry.

**Developer Portal (Backstage)**
The developer portal platform. Architecture is defined in RFC-DEVELOPER-PLATFORM. This RFC covers only the identity integration (Keycloak authentication).

**Package Registry**
A service that hosts software packages (npm, Maven, etc.) and proxies public registries. Examples include Verdaccio and Nexus.

**Platform Application**
Any web-based developer tool that integrates with the platform identity system. Examples include container registries, package registries, developer portals, and monitoring dashboards.

**Robot Account / Service Account**
An account in a registry or application for automated access (CI/CD pipelines). Uses token authentication rather than OIDC.

---

## A.2 ADR Index

Architectural Decision Records documenting significant decisions in this RFC:

| ADR ID | Decision Summary | Rationale Section | Defining Section |
|--------|------------------|-------------------|------------------|
| ADR-001 | Azure AD as authorization ceiling | §9.1.2 | §5.1 |
| ADR-002 | Keycloak as platform identity broker | §9.1.1 | §4.2 |
| ADR-003 | Vault as sole secret authority (defers to RFC-SECOPS-0001) | §9.3.1 | §2.4 INV-3 |
| ADR-004 | ESO for secret distribution (defers to RFC-SECOPS-0001) | §9.3.4 | §2.4 INV-4 |
| ADR-005 | GitOps boundary at access assignments | §9.4.1 | §7.5 |
| ADR-011 | Defer secrets architecture to RFC-SECOPS-0001 | §2.3.6 | §6.1 |
| ADR-006 | Crossplane for resource provisioning | §9.4.3 | §7.2 |
| ADR-007 | Helm templating for resource coupling | §9.4.4 | §7.3 |
| ADR-008 | Token-based application authorization | §9.2.1 | §5.4 |
| ADR-009 | Group-to-role mapping in Keycloak | §9.2.3 | §5.3 |
| ADR-010 | Administrative interface for access assignments | §9.4.1 | §7.5.1 |

---

## A.3 Diagram Index

All diagrams included in this RFC:

| Diagram Name | Type | Section |
|--------------|------|---------|
| Architectural Layers | flowchart | §3.1.1 |
| Trust Hierarchy | flowchart | §3.2.1 |
| Enterprise to Platform Boundary | flowchart | §3.4.1 |
| Platform to Application Boundary | flowchart | §3.4.2 |
| Vault to Namespace Boundary | flowchart | §3.4.3 |
| User to Developer Portal Action Boundary | flowchart | §3.4.4 |
| Authentication Data Flow | sequenceDiagram | §3.5.1 |
| Secret Data Flow | sequenceDiagram | §3.5.3 |
| Resource Provisioning Data Flow | sequenceDiagram | §3.5.4 |
| Authorization Ceiling | flowchart | §5.1.1 |
| Trust Verification Flow | flowchart | §5.2.3 |
| Role Hierarchy | flowchart | §5.3.1 |
| Complete Authorization Decision Flow | sequenceDiagram | §5.5.1 |
| Vault-Keycloak Integration | flowchart | §6.4.1 |
| Keycloak Client Secret Flow | sequenceDiagram | §6.5.2 |
| Configuration Change Flow | flowchart | §7.1.4 |
| Provider Architecture | flowchart | §7.2.1 |
| Composition Strategy | flowchart | §7.2.4 |
| Reconciliation Model | stateDiagram-v2 | §7.4.1 |
| Developer Portal GitOps Integration | sequenceDiagram | §7.6.1 |
| Standard Integration Model | flowchart | §8.1.1 |
| Integration Lifecycle | stateDiagram-v2 | §8.1.3 |
| OIDC Authentication Flow | sequenceDiagram | §8.2.1 |
| Developer Portal Identity Integration | sequenceDiagram | §8.6.1 |
| CI/CD Service Account Integration | sequenceDiagram | §8.8.1 |

---

## A.4 Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| AAD | Azure Active Directory |
| ABAC | Attribute-Based Access Control |
| ADR | Architectural Decision Record |
| API | Application Programming Interface |
| CA | Certificate Authority |
| CI/CD | Continuous Integration / Continuous Delivery |
| ESO | External Secrets Operator |
| HSM | Hardware Security Module |
| HTTP | Hypertext Transfer Protocol |
| IAM | Identity and Access Management |
| IdP | Identity Provider |
| JSON | JavaScript Object Notation |
| JWT | JSON Web Token |
| JWKS | JSON Web Key Set |
| K8s | Kubernetes |
| MFA | Multi-Factor Authentication |
| mTLS | Mutual Transport Layer Security |
| OIDC | OpenID Connect |
| RBAC | Role-Based Access Control |
| RFC | Request for Comments |
| SA | Service Account |
| SSO | Single Sign-On |
| TLS | Transport Layer Security |
| UI | User Interface |
| URL | Uniform Resource Locator |
| YAML | YAML Ain't Markup Language |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 10. Evolution](./10-evolution.md) | [Table of Contents](./00-index.md#table-of-contents) | [Appendix B: References →](./appendix-b-references.md) |

---

*End of Appendix A*
