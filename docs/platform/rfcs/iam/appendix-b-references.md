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

### Applications

**[HARBOR-DOCS]** Harbor, "Harbor Documentation".
<https://goharbor.io/docs/>

**[HARBOR-OIDC]** Harbor, "Configure OIDC Provider Authentication".
<https://goharbor.io/docs/latest/administration/configure-authentication/oidc-auth/>

**[VERDACCIO-DOCS]** Verdaccio, "Verdaccio Documentation".
<https://verdaccio.org/docs/what-is-verdaccio>

**[BACKSTAGE-DOCS]** Spotify, "Backstage Documentation".
<https://backstage.io/docs/overview/what-is-backstage>

**[BACKSTAGE-AUTH]** Spotify, "Backstage Authentication".
<https://backstage.io/docs/auth/>

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

**[RFC-WORKLOAD-IDENTITY]** (Planned) "Workload Identity Architecture"
- Machine identity for VMs and physical hosts
- Workload identity for Kubernetes pods and containers
- Service-to-service authentication (mTLS, SPIFFE/SPIRE)
- AI agent identity management
- CI/CD pipeline identity
- Service mesh identity integration

This RFC will define non-human identity concerns that are explicitly out of scope for RFC-IAM-0001. Primary question: "Who is this workload and can it authenticate to other services?"

**[RFC-TENANT-SECURITY]** (Planned) "Tenant Application Security"
- Web Application Firewall (WAF) configuration and policies
- Network policies (Kubernetes NetworkPolicy, Calico, Cilium)
- Ingress/egress security policies
- API gateway security and routing policies
- Rate limiting and DDoS protection
- Security standards for tenant namespaces
- Traffic management and routing security

This RFC will define how tenant applications (applications deployed by business units on the platform) are protected from external threats and how network boundaries are enforced. Primary question: "How do we protect tenant applications?"

**[RFC-PAM]** (Planned) "Privileged Access Management"
- SSH access to infrastructure
- Database port access for developers
- VPC and network perimeter access
- Kubernetes exec/attach governance
- Command auditing on infrastructure
- Session recording and access brokering

This RFC will define how identity (established by RFC-IAM-0001) translates into infrastructure access rights, potentially using tools like Teleport, Boundary, or Vault's SSH/database secrets engines. Primary question: "Can this human access this infrastructure resource?"

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

*End of Appendix B*

---

*End of RFC-IAM-0001*
