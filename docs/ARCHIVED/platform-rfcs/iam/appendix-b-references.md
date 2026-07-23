```
RFC-IAM-0001                                                 Appendix B
Category: Standards Track                                 References
```

# Appendix B: References

[← Previous: Appendix A](./appendix-a-glossary.md) | [Index](./00-index.md#table-of-contents)

---

## B.1 Normative References

These references are essential for understanding and implementing this RFC.

### Standards

**[RFC2119]** Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.
<https://datatracker.ietf.org/doc/html/rfc2119>

**[RFC8174]** Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words", BCP 14, RFC 8174, May 2017.
<https://datatracker.ietf.org/doc/html/rfc8174>

**[OIDC-CORE]** Sakimura, N., Bradley, J., Jones, M., de Medeiros, B., and C. Mortimore, "OpenID Connect Core 1.0", November 2014.
<https://openid.net/specs/openid-connect-core-1_0.html>

**[OAUTH2]** Hardt, D., "The OAuth 2.0 Authorization Framework", RFC 6749, October 2012.
<https://datatracker.ietf.org/doc/html/rfc6749>

**[JWT]** Jones, M., Bradley, J., and N. Sakimura, "JSON Web Token (JWT)", RFC 7519, May 2015.
<https://datatracker.ietf.org/doc/html/rfc7519>

**[JWK]** Jones, M., "JSON Web Key (JWK)", RFC 7517, May 2015.
<https://datatracker.ietf.org/doc/html/rfc7517>

---

## B.2 Technology Documentation

Documentation for technologies referenced in this RFC.

### Identity Systems

**[AAD-DOCS]** Microsoft, "Azure Active Directory documentation".
<https://docs.microsoft.com/en-us/azure/active-directory/>

**[AAD-OIDC]** Microsoft, "Microsoft identity platform and OpenID Connect protocol".
<https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc>

**[KEYCLOAK-DOCS]** Red Hat, "Keycloak Documentation".
<https://www.keycloak.org/documentation>

**[KEYCLOAK-ADMIN]** Red Hat, "Keycloak Server Administration Guide".
<https://www.keycloak.org/docs/latest/server_admin/>

**[KEYCLOAK-IDP]** Red Hat, "Keycloak Identity Brokering".
<https://www.keycloak.org/docs/latest/server_admin/#_identity_broker>

### Secrets Management

**[VAULT-DOCS]** HashiCorp, "Vault Documentation".
<https://developer.hashicorp.com/vault/docs>

**[VAULT-K8S-AUTH]** HashiCorp, "Vault Kubernetes Auth Method".
<https://developer.hashicorp.com/vault/docs/auth/kubernetes>

**[VAULT-KV]** HashiCorp, "KV Secrets Engine - Version 2".
<https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2>

**[ESO-DOCS]** External Secrets Operator, "External Secrets Documentation".
<https://external-secrets.io/latest/>

**[ESO-VAULT]** External Secrets Operator, "HashiCorp Vault Provider".
<https://external-secrets.io/latest/provider/hashicorp-vault/>

### Infrastructure

**[CROSSPLANE-DOCS]** Crossplane, "Crossplane Documentation".
<https://docs.crossplane.io/>

**[CROSSPLANE-CONCEPTS]** Crossplane, "Crossplane Concepts".
<https://docs.crossplane.io/latest/concepts/>

**[ARGOCD-DOCS]** Argo Project, "Argo CD Documentation".
<https://argo-cd.readthedocs.io/en/stable/>

**[HELM-DOCS]** Helm, "Helm Documentation".
<https://helm.sh/docs/>

### Example Platform Applications

These references provide examples of OIDC-compatible applications that can integrate with the architecture described in this RFC.

**[HARBOR-DOCS]** Harbor, "Harbor Documentation". (Container Registry)
<https://goharbor.io/docs/>

**[HARBOR-OIDC]** Harbor, "Configure OIDC Provider Authentication".
<https://goharbor.io/docs/latest/administration/configure-authentication/oidc-auth/>

**[VERDACCIO-DOCS]** Verdaccio, "Verdaccio Documentation". (Package Registry)
<https://verdaccio.org/docs/what-is-verdaccio>

**[BACKSTAGE-DOCS]** Spotify, "Backstage Documentation". (Developer Portal)
<https://backstage.io/docs/overview/what-is-backstage>

**[BACKSTAGE-AUTH]** Spotify, "Backstage Authentication".
<https://backstage.io/docs/auth/>

**[GRAFANA-OIDC]** Grafana, "Configure Grafana OAuth Authentication". (Monitoring)
<https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/generic-oauth/>

---

## B.3 Informative References

Background and context references that informed this RFC.

### Security Guidance

**[NIST-IAM]** NIST, "Digital Identity Guidelines", Special Publication 800-63.
<https://pages.nist.gov/800-63-3/>

**[OWASP-AUTHZ]** OWASP, "Authorization Cheat Sheet".
<https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html>

**[ZERO-TRUST]** NIST, "Zero Trust Architecture", Special Publication 800-207.
<https://csrc.nist.gov/publications/detail/sp/800-207/final>

### Architecture Patterns

**[GITOPS]** Weaveworks, "Guide to GitOps".
<https://www.weave.works/technologies/gitops/>

**[PLATFORM-ENG]** CNCF, "Platforms White Paper".
<https://tag-app-delivery.cncf.io/whitepapers/platforms/>

**[SECRETS-MGMT]** CNCF, "Secrets Management Best Practices".
<https://www.cncf.io/blog/2021/04/12/kubernetes-secrets-management-best-practices/>

### Cloud Native

**[K8S-DOCS]** Kubernetes, "Kubernetes Documentation".
<https://kubernetes.io/docs/home/>

**[K8S-SECRETS]** Kubernetes, "Secrets".
<https://kubernetes.io/docs/concepts/configuration/secret/>

**[K8S-RBAC]** Kubernetes, "Using RBAC Authorization".
<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>

---

## B.4 Internal References

References to other organizational documents.

### Normative Internal References

**[RFC-SECOPS-0001]** Platform Engineering, "A GitOps-Native, Vault-First Secret Management Architecture", RFC-SECOPS-0001, January 2026.
`docs/platform/rfcs/secret-ops/00-index.md`

This RFC is **normative** for all secrets management concerns. RFC-IAM-0001 defers to RFC-SECOPS-0001 for:
- Secret lifecycle management (bootstrap, runtime, rotation)
- Cross-namespace secret distribution
- Vault as runtime authority
- PushSecret/ExternalSecret patterns

Where RFC-IAM-0001 and RFC-SECOPS-0001 address overlapping concerns, RFC-SECOPS-0001 is authoritative for secrets and RFC-IAM-0001 is authoritative for identity.

### Informative Internal References

**[RFC-STANDARDS]** Platform Engineering, "RFC Authoring Standards", Internal Documentation.
`docs/standards/rfcs.md`

### Anticipated Future References

The following RFCs are anticipated but not yet written:

**[RFC-DEVELOPER-PLATFORM]** (Planned) "Developer Platform Architecture"
- Backstage as the developer portal
- Capability-based UI (users see only what they can do)
- Permission-aware component rendering
- Self-service workflows for resource creation
- Integration with Crossplane for resource provisioning
- Template and scaffolder architecture

This RFC will define how the developer portal presents a permission-aware interface where users only see actions they are authorized to perform. Authentication flows through Keycloak (per RFC-IAM-0001), but the portal adapts its UI based on the user's permission claims rather than blocking unauthorized actions at runtime. Primary question: "How do developers interact with the platform?"

**[RFC-WORKLOAD-IDENTITY-0001]** Platform Engineering, "Workload Identity Architecture", RFC-WORKLOAD-IDENTITY-0001, February 2026.
`docs/platform/rfcs/workload-identity/00-index.md`

RFC-WORKLOAD-IDENTITY-0001 defines non-human identity concerns that are explicitly out of scope for RFC-IAM-0001:
- SPIFFE/SPIRE as primary workload identity framework
- Kubernetes workload identity via ServiceAccounts
- CI/CD pipeline identity via OIDC federation
- GitOps operator identity
- AI agent identity and delegation chains (OAuth 2.0 Token Exchange)
- Machine identity via Teleport Machine ID (tbot)
- Service mesh identity via Linkerd mTLS

Primary question: "Who is this workload and can it authenticate to other services?"

**[RFC-TENANT-SECURITY]** (Planned) "Tenant Application Security"
- Web Application Firewall (WAF) configuration and policies
- Network policies (Kubernetes NetworkPolicy, Calico, Cilium)
- Ingress/egress security policies
- API gateway security and routing policies
- Rate limiting and DDoS protection
- Security standards for tenant namespaces
- Traffic management and routing security

This RFC will define how tenant applications (applications deployed by business units on the platform) are protected from external threats and how network boundaries are enforced. Primary question: "How do we protect tenant applications?"

**[RFC-PAM-0001]** (Planned) "Privileged Access Management Architecture"

RFC-PAM-0001 defines how human users access infrastructure resources (SSH, databases, Kubernetes) through a centralized access broker with full session recording and audit capabilities.

**Scope**:
- SSH access to Linux/Unix servers via certificate authentication
- Database access for developers (PostgreSQL, MySQL, MongoDB) via dynamic credentials
- Kubernetes exec/attach/port-forward governance
- Windows RDP access
- Session recording and playback for compliance
- Just-in-time (JIT) access request workflows
- Command and query auditing

**Key Components**:
- **Teleport**: Zero-trust access broker for all privileged access
- **Vault SSH Engine**: Certificate authority for SSH authentication
- **Vault Database Engine**: Dynamic, ephemeral database credentials
- **Keycloak**: Identity source (per RFC-IAM-0001)
- **ESO**: Distribution of agent enrollment secrets

**Relationship to RFC-IAM-0001**:
- RFC-IAM-0001 provides the identity layer (Keycloak SSO)
- RFC-PAM-0001 consumes Keycloak tokens for user authentication
- Teleport roles are constrained by Keycloak groups (which are constrained by Azure AD)
- The authorization ceiling principle (INV-1) extends to privileged access

**Primary Question**: "Can this human access this infrastructure resource?"

**Plan Document**: `docs/platform/rfcs/pam/PLAN.md`

---

## B.5 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-10 | Initial draft |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-IAM-0001*
