```
RFC-PAM-0001                                                  Appendix B
Category: Standards Track                                   References
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

**[RFC4252]** Ylonen, T. and C. Lonvick, "The Secure Shell (SSH) Authentication Protocol", RFC 4252, January 2006.
<https://datatracker.ietf.org/doc/html/rfc4252>

**[OPENSSH-CERT]** OpenSSH, "PROTOCOL.certkeys — OpenSSH certificates".
<https://github.com/openssh/openssh-portable/blob/master/PROTOCOL.certkeys>

---

## B.2 Technology Documentation

Documentation for technologies referenced in this RFC.

### Teleport

**[TELEPORT-DOCS]** Teleport, "Teleport Documentation".
<https://goteleport.com/docs/>

**[TELEPORT-SSH]** Teleport, "SSH Server Access".
<https://goteleport.com/docs/server-access/>

**[TELEPORT-DB]** Teleport, "Database Access".
<https://goteleport.com/docs/database-access/>

**[TELEPORT-K8S]** Teleport, "Kubernetes Access".
<https://goteleport.com/docs/kubernetes-access/>

**[TELEPORT-RECORDING]** Teleport, "Session Recording".
<https://goteleport.com/docs/architecture/session-recording/>

**[TELEPORT-ACCESS-REQUESTS]** Teleport, "Access Requests".
<https://goteleport.com/docs/access-controls/access-requests/>

**[TELEPORT-OIDC]** Teleport, "OIDC Authentication".
<https://goteleport.com/docs/access-controls/sso/oidc/>

### HashiCorp Vault

**[VAULT-DOCS]** HashiCorp, "Vault Documentation".
<https://developer.hashicorp.com/vault/docs>

**[VAULT-SSH]** HashiCorp, "SSH Secrets Engine".
<https://developer.hashicorp.com/vault/docs/secrets/ssh>

**[VAULT-SSH-CA]** HashiCorp, "SSH Secrets Engine (Signed Certificates)".
<https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates>

**[VAULT-DATABASE]** HashiCorp, "Database Secrets Engine".
<https://developer.hashicorp.com/vault/docs/secrets/databases>

**[VAULT-K8S-AUTH]** HashiCorp, "Vault Kubernetes Auth Method".
<https://developer.hashicorp.com/vault/docs/auth/kubernetes>

### External Secrets Operator

**[ESO-DOCS]** External Secrets Operator, "External Secrets Documentation".
<https://external-secrets.io/latest/>

**[ESO-VAULT]** External Secrets Operator, "HashiCorp Vault Provider".
<https://external-secrets.io/latest/provider/hashicorp-vault/>

### Keycloak

**[KEYCLOAK-DOCS]** Red Hat, "Keycloak Documentation".
<https://www.keycloak.org/documentation>

**[KEYCLOAK-OIDC]** Red Hat, "Keycloak OpenID Connect".
<https://www.keycloak.org/docs/latest/server_admin/#_oidc>

---

## B.3 Informative References

Background and context references that informed this RFC.

### Security Guidance

**[NIST-PAM]** NIST, "Guide to Secure Shell (SSH)", Special Publication 800-123.
<https://csrc.nist.gov/publications/detail/sp/800-123/final>

**[NIST-ZERO-TRUST]** NIST, "Zero Trust Architecture", Special Publication 800-207.
<https://csrc.nist.gov/publications/detail/sp/800-207/final>

**[CIS-SSH]** CIS, "CIS Benchmark for SSH".
<https://www.cisecurity.org/benchmark/distribution_independent_linux>

### Compliance Standards

**[SOC2]** AICPA, "SOC 2 - Trust Services Criteria".
<https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2>

**[ISO27001]** ISO, "ISO/IEC 27001 Information Security Management".
<https://www.iso.org/standard/27001>

**[PCI-DSS]** PCI Security Standards Council, "PCI DSS v4.0".
<https://www.pcisecuritystandards.org/document_library/>

**[HIPAA]** HHS, "HIPAA Security Rule".
<https://www.hhs.gov/hipaa/for-professionals/security/index.html>

### Architecture Patterns

**[GITOPS]** Weaveworks, "Guide to GitOps".
<https://www.weave.works/technologies/gitops/>

**[ZERO-STANDING-PRIVILEGES]** Gartner, "Implement Zero Standing Privileges".
<https://www.gartner.com/en/documents/3991679>

---

## B.4 Internal References

References to other organizational documents.

### Normative Internal References

**[RFC-IAM-0001]** Platform Engineering, "Federated Identity and Access Management Architecture", RFC-IAM-0001, February 2026.
`docs/platform/rfcs/iam/00-index.md`

This RFC is **normative** for identity concerns. RFC-PAM-0001 MUST:
- Authenticate users through Keycloak (per RFC-IAM-0001)
- Respect the authorization ceiling established by Azure AD groups
- Map Keycloak groups to Teleport roles

**[RFC-SECOPS-0001]** Platform Engineering, "A GitOps-Native, Vault-First Secret Management Architecture", RFC-SECOPS-0001, January 2026.
`docs/platform/rfcs/secret-ops/00-index.md`

This RFC is **normative** for credential management. RFC-PAM-0001 MUST:
- Use Vault SSH secrets engine for SSH certificates
- Use Vault database secrets engine for database credentials
- Distribute secrets through ESO per RFC-SECOPS-0001 patterns

### Informative Internal References

**[RFC-WORKLOAD-IDENTITY-0001]** Platform Engineering, "Workload Identity Architecture", RFC-WORKLOAD-IDENTITY-0001, February 2026.
`docs/platform/rfcs/workload-identity/00-index.md`

RFC-PAM-0001 governs human access to infrastructure. RFC-WORKLOAD-IDENTITY-0001 governs service/machine access. The two RFCs share:
- Teleport infrastructure (Machine ID for VMs in RFC-WORKLOAD-IDENTITY)
- Vault credential engines (SSH, database)
- Keycloak for AI agent delegation (Token Exchange)

But implement different access patterns:
- RFC-PAM-0001: Interactive human sessions with recording
- RFC-WORKLOAD-IDENTITY: Programmatic workload authentication

**[RFC-DEVELOPER-PLATFORM-0001](../developer-platform/00-index.md)** "Developer Platform Architecture"

RFC-DEVELOPER-PLATFORM-0001 provides self-service UI for JIT access requests via Backstage integration.

**[RFC-TENANT-SECURITY-0001](../tenant-security/00-index.md)** "Tenant Application Security"

Network-level controls that complement PAM access controls.

---

## B.5 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-10 | Initial release |

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-PAM-0001*
