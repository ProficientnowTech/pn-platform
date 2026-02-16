```
RFC-WORKLOAD-IDENTITY-0001                                      Appendix B
Category: Standards Track                                      References
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

**[RFC8693]** Jones, M., Nadalin, A., Campbell, B., Bradley, J., and C. Mortimore, "OAuth 2.0 Token Exchange", RFC 8693, January 2020.
<https://datatracker.ietf.org/doc/html/rfc8693>

**[OIDC-CORE]** OpenID Foundation, "OpenID Connect Core 1.0", November 2014.
<https://openid.net/specs/openid-connect-core-1_0.html>

### SPIFFE Specification

**[SPIFFE]** CNCF, "SPIFFE Specification".
<https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/>

**[SPIFFE-ID]** CNCF, "SPIFFE ID Specification".
<https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE-ID.md>

**[SPIFFE-X509-SVID]** CNCF, "SPIFFE X.509 SVID Specification".
<https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md>

**[SPIFFE-JWT-SVID]** CNCF, "SPIFFE JWT-SVID Specification".
<https://github.com/spiffe/spiffe/blob/main/standards/JWT-SVID.md>

**[SPIFFE-FEDERATION]** CNCF, "SPIFFE Federation Specification".
<https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE_Federation.md>

---

## B.2 Technology Documentation

Documentation for technologies referenced in this RFC.

### SPIRE

**[SPIRE-DOCS]** CNCF, "SPIRE Documentation".
<https://spiffe.io/docs/latest/spire-about/spire-concepts/>

**[SPIRE-K8S]** CNCF, "SPIRE Kubernetes Quickstart".
<https://spiffe.io/docs/latest/try/getting-started-k8s/>

**[SPIRE-FEDERATION]** CNCF, "SPIRE Federation Configuration".
<https://spiffe.io/docs/latest/architecture/federation/>

**[SPIRE-VAULT]** CNCF, "SPIRE and Vault Integration".
<https://spiffe.io/docs/latest/keyless/vault/>

### HashiCorp Vault

**[VAULT-DOCS]** HashiCorp, "Vault Documentation".
<https://developer.hashicorp.com/vault/docs>

**[VAULT-K8S-AUTH]** HashiCorp, "Vault Kubernetes Auth Method".
<https://developer.hashicorp.com/vault/docs/auth/kubernetes>

**[VAULT-JWT-AUTH]** HashiCorp, "Vault JWT/OIDC Auth Method".
<https://developer.hashicorp.com/vault/docs/auth/jwt>

**[VAULT-APPROLE]** HashiCorp, "Vault AppRole Auth Method".
<https://developer.hashicorp.com/vault/docs/auth/approle>

**[VAULT-APPROLE-PATTERN]** HashiCorp, "AppRole Best Practices".
<https://developer.hashicorp.com/vault/docs/auth/approle/approle-pattern>

### Teleport

**[TELEPORT-DOCS]** Teleport, "Teleport Documentation".
<https://goteleport.com/docs/>

**[TELEPORT-MACHINE-ID]** Teleport, "Machine ID Introduction".
<https://goteleport.com/docs/machine-workload-identity/introduction/>

**[TELEPORT-TBOT-K8S]** Teleport, "tbot Kubernetes Deployment".
<https://goteleport.com/docs/machine-workload-identity/deployment/kubernetes/>

**[TELEPORT-ACCESS-CONTROLS]** Teleport, "Access Controls".
<https://goteleport.com/docs/access-controls/>

### Linkerd

**[LINKERD-DOCS]** Linkerd, "Linkerd Documentation".
<https://linkerd.io/2-edge/overview/>

**[LINKERD-MTLS]** Linkerd, "Automatic mTLS".
<https://linkerd.io/2-edge/features/automatic-mtls/>

**[LINKERD-AUTHZ]** Linkerd, "Server Policy and Authorization".
<https://linkerd.io/2-edge/features/server-policy/>

**[LINKERD-MULTICLUSTER]** Linkerd, "Multi-cluster Communication".
<https://linkerd.io/2-edge/features/multicluster/>

### Kubernetes

**[K8S-SA]** Kubernetes, "Service Accounts".
<https://kubernetes.io/docs/concepts/security/service-accounts/>

**[K8S-PROJECTED-TOKENS]** Kubernetes, "Configure Service Accounts for Pods".
<https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/>

**[K8S-RBAC]** Kubernetes, "Role-Based Access Control".
<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>

**[K8S-NETWORK-POLICY]** Kubernetes, "Network Policies".
<https://kubernetes.io/docs/concepts/services-networking/network-policies/>

### External Secrets Operator

**[ESO-DOCS]** External Secrets Operator, "External Secrets Documentation".
<https://external-secrets.io/latest/>

**[ESO-VAULT]** External Secrets Operator, "HashiCorp Vault Provider".
<https://external-secrets.io/latest/provider/hashicorp-vault/>

### Cloud Provider Identity

**[AWS-IRSA]** AWS, "IAM Roles for Service Accounts".
<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>

**[GCP-WI]** GCP, "Workload Identity".
<https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity>

**[AZURE-WI]** Azure, "Azure Workload Identity".
<https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview>

**[GITHUB-OIDC]** GitHub, "About Security Hardening with OpenID Connect".
<https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect>

### Keycloak

**[KEYCLOAK-DOCS]** Red Hat, "Keycloak Documentation".
<https://www.keycloak.org/documentation>

**[KEYCLOAK-TOKEN-EXCHANGE]** Red Hat, "Token Exchange".
<https://www.keycloak.org/docs/latest/securing_apps/#_token-exchange>

---

## B.3 Informative References

Background and context references that informed this RFC.

### Security Guidance

**[NIST-800-207]** NIST, "Zero Trust Architecture", Special Publication 800-207.
<https://csrc.nist.gov/publications/detail/sp/800-207/final>

**[NIST-800-63]** NIST, "Digital Identity Guidelines", Special Publication 800-63.
<https://csrc.nist.gov/publications/detail/sp/800-63/3/final>

### Compliance Standards

**[SOC2]** AICPA, "SOC 2 - Trust Services Criteria".
<https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2>

**[ISO27001]** ISO, "ISO/IEC 27001 Information Security Management".
<https://www.iso.org/standard/27001>

**[PCI-DSS]** PCI Security Standards Council, "PCI DSS v4.0".
<https://www.pcisecuritystandards.org/document_library/>

### AI Agent Identity Research

**[AGENTIC-IDENTITY]** Strata Identity, "8 Strategies for AI Agent Security in 2025".
<https://www.strata.io/blog/agentic-identity/8-strategies-for-ai-agent-security-in-2025/>

**[WORKOS-AGENTS]** WorkOS, "Identity for AI Agents".
<https://workos.com/blog/identity-for-ai-agents>

**[CROWDSTRIKE-AGENTS]** CrowdStrike, "Unified Identity Security for Human and AI Agents".
<https://www.crowdstrike.com/en-us/press-releases/crowdstrike-launches-unified-identity-security-human-ai-agents/>

### GitOps

**[ARGOCD-SECURITY]** Argo Project, "ArgoCD Security Considerations".
<https://argo-cd.readthedocs.io/en/stable/operator-manual/security/>

**[FLUX-WI]** Flux, "Flux 2.6 with Workload Identity".
<https://fluxcd.io/blog/2025/05/flux-v2.6.0/>

---

## B.4 Internal References

References to other organizational documents.

### Normative Internal References

**[RFC-IAM-0001]** Platform Engineering, "Federated Identity and Access Management Architecture", RFC-IAM-0001, February 2026.
`docs/platform/rfcs/iam/00-index.md`

This RFC is **normative** for human identity concerns. RFC-WORKLOAD-IDENTITY-0001 MUST:
- Respect the authorization ceiling established by Azure AD
- Use Keycloak for AI agent Token Exchange
- Integrate with existing identity infrastructure

**[RFC-SECOPS-0001]** Platform Engineering, "A GitOps-Native, Vault-First Secret Management Architecture", RFC-SECOPS-0001, January 2026.
`docs/platform/rfcs/secret-ops/00-index.md`

This RFC is **normative** for credential management. RFC-WORKLOAD-IDENTITY-0001 MUST:
- Use Vault as the credential authority
- Distribute secrets through ESO per RFC-SECOPS-0001 patterns
- Follow Vault policy conventions

**[RFC-PAM-0001]** Platform Engineering, "Privileged Access Management Architecture", RFC-PAM-0001, February 2026.
`docs/platform/rfcs/pam/00-index.md`

This RFC shares infrastructure. RFC-WORKLOAD-IDENTITY-0001:
- Uses Teleport Machine ID (tbot) for VM identity
- Shares Vault SSH and database engines
- Complements human access patterns with machine access patterns

### Informative Internal References

**[RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md)** "Developer Platform Architecture"

RFC-DEVELOPER-PLATFORM-0001 provides self-service UI for workload identity configuration via Backstage integration.

**[RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md)** "Tenant Application Security"

Network-level controls that complement workload identity controls.

---

## B.5 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-11 | Initial release |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-WORKLOAD-IDENTITY-0001*

---

*End of RFC-WORKLOAD-IDENTITY-0001*
