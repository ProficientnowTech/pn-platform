```
RFC-TENANT-SECURITY-0001                                        Appendix B
Category: Standards Track                                       References
```

# Appendix B: References

[← Appendix A: Glossary](./appendix-a-glossary.md) | [Index](./00-index.md#table-of-contents)

---

## B.1 Normative References

References that MUST be followed for compliance with this RFC.

| ID | Title | URL |
|----|-------|-----|
| [RFC2119] | Key words for use in RFCs to Indicate Requirement Levels | https://www.rfc-editor.org/rfc/rfc2119 |
| [RFC8174] | Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words | https://www.rfc-editor.org/rfc/rfc8174 |
| [OWASP-TOP10] | OWASP Top 10 2021 | https://owasp.org/Top10/ |
| [OWASP-API-TOP10] | OWASP API Security Top 10 2023 | https://owasp.org/API-Security/ |
| [OWASP-CRS] | OWASP Core Rule Set | https://coreruleset.org/ |
| [K8S-NETPOL] | Kubernetes Network Policies | https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| [GATEWAY-API] | Kubernetes Gateway API | https://gateway-api.sigs.k8s.io/ |

---

## B.2 Informative References

References that provide background information and context.

### B.2.1 Technology Documentation

| ID | Title | URL |
|----|-------|-----|
| [BUNKERWEB] | BunkerWeb Documentation | https://docs.bunkerweb.io/ |
| [BUNKERWEB-GH] | BunkerWeb GitHub Repository | https://github.com/bunkerity/bunkerweb |
| [BUNKERWEB-HELM] | BunkerWeb Helm Chart | https://github.com/bunkerity/bunkerweb-helm |
| [CALICO-DOCS] | Calico Documentation | https://docs.tigera.io/calico/latest/ |
| [CALICO-NETPOL] | Calico Network Policy | https://docs.tigera.io/calico/latest/network-policy/ |
| [CERT-MANAGER] | cert-manager Documentation | https://cert-manager.io/docs/ |
| [LETSENCRYPT] | Let's Encrypt Documentation | https://letsencrypt.org/docs/ |

### B.2.2 Alternatives Evaluated

| ID | Title | URL |
|----|-------|-----|
| [SAFELINE] | SafeLine WAF | https://github.com/chaitin/SafeLine |
| [CORAZA] | Coraza WAF | https://coraza.io/ |
| [MODSECURITY] | ModSecurity | https://github.com/SpiderLabs/ModSecurity |

### B.2.3 Industry Standards

| ID | Title | URL |
|----|-------|-----|
| [NGINX-RETIRE] | Ingress NGINX Retirement Announcement | https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/ |
| [CRS-DOCS] | OWASP CRS Documentation | https://coreruleset.org/docs/ |
| [OWASP-WAF] | OWASP WAF Projects | https://waf.owasp.org/ |

### B.2.4 Compliance Standards

| ID | Title | Description |
|----|-------|-------------|
| [SOC2] | SOC 2 | Service Organization Control 2 |
| [ISO27001] | ISO/IEC 27001 | Information security management |
| [PCI-DSS] | PCI DSS | Payment Card Industry Data Security Standard |

---

## B.3 Internal References

References to other RFCs and internal documentation.

### B.3.1 Normative Internal References

| ID | Title | Relationship |
|----|-------|--------------|
| RFC-IAM-0001 | Federated Identity and Access Management Architecture | Keycloak integration patterns; WAF exceptions for auth flows |
| RFC-SECOPS-0001 | GitOps-Native, Vault-First Secret Management Architecture | Vault for secrets; ESO for TLS certificate distribution |

### B.3.2 Informative Internal References

| ID | Title | Relationship |
|----|-------|--------------|
| RFC-WORKLOAD-IDENTITY | Workload Identity Architecture | Service mesh boundary; East-West traffic handling |
| RFC-PAM-0001 | Privileged Access Management Architecture | Network policies may affect privileged access |
| RFC-DEVELOPER-PLATFORM | Developer Platform Architecture (Planned) | Future self-service integration |

---

## B.4 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-11 | Platform Engineering Team | Initial release |

---

## B.5 Document Status

| Field | Value |
|-------|-------|
| Status | Draft |
| Review State | Pending |
| Last Review | — |
| Next Review | — |

---

## B.6 Acknowledgments

This RFC builds upon work from:

- OWASP Foundation for the Core Rule Set and security guidance
- BunkerWeb project for the WAF solution
- Kubernetes community for NetworkPolicy and Gateway API specifications
- cert-manager project for certificate automation

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-TENANT-SECURITY-0001*

---

*End of RFC-TENANT-SECURITY-0001*
