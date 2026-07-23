```
RFC-DEVELOPER-PLATFORM-0001                                      Appendix B
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
| [RFC-IAM-0001] | Federated Identity and Access Management Architecture | Internal |
| [RFC-SECOPS-0001] | GitOps-Native, Vault-First Secret Management Architecture | Internal |
| [RFC-PAM-0001] | Privileged Access Management Architecture | Internal |

---

## B.2 Technology Documentation

### B.2.1 Backstage Documentation

| ID | Title | URL |
|----|-------|-----|
| [BACKSTAGE-OVERVIEW] | What is Backstage? | https://backstage.io/docs/overview/what-is-backstage |
| [BACKSTAGE-TECHNICAL] | Technical Overview | https://backstage.io/docs/overview/technical-overview |
| [BACKSTAGE-AUTH] | Authentication | https://backstage.io/docs/auth/ |
| [BACKSTAGE-PERMISSIONS] | Permission Framework | https://backstage.io/docs/permissions/overview |
| [BACKSTAGE-CATALOG] | Software Catalog | https://backstage.io/docs/features/software-catalog/ |
| [BACKSTAGE-TEMPLATES] | Software Templates | https://backstage.io/docs/features/software-templates/ |
| [BACKSTAGE-TECHDOCS] | TechDocs | https://backstage.io/docs/features/techdocs/ |
| [BACKSTAGE-KUBERNETES] | Kubernetes Plugin | https://backstage.io/docs/features/kubernetes/ |
| [BACKSTAGE-OIDC] | OIDC Provider Setup | https://backstage.io/docs/auth/oidc/ |

### B.2.2 Platform Tool Documentation

| ID | Title | URL |
|----|-------|-----|
| [ARGOCD-DOCS] | ArgoCD Documentation | https://argo-cd.readthedocs.io/ |
| [CROSSPLANE-DOCS] | Crossplane Documentation | https://docs.crossplane.io/ |
| [GRAFANA-DOCS] | Grafana Documentation | https://grafana.com/docs/ |
| [HARBOR-DOCS] | Harbor Documentation | https://goharbor.io/docs/ |
| [KEYCLOAK-DOCS] | Keycloak Documentation | https://www.keycloak.org/documentation |
| [STRIMZI-DOCS] | Strimzi Documentation | https://strimzi.io/documentation/ |
| [APICURIO-DOCS] | Apicurio Registry Documentation | https://www.apicur.io/registry/docs/ |
| [TELEPORT-DOCS] | Teleport Documentation | https://goteleport.com/docs/ |
| [TEMPORAL-DOCS] | Temporal Documentation | https://docs.temporal.io/ |

### B.2.3 Database Operator Documentation

| ID | Title | URL |
|----|-------|-----|
| [CNPG-DOCS] | CloudNativePG Documentation | https://cloudnative-pg.io/documentation/ |
| [ZALANDO-PG] | Zalando Postgres Operator | https://postgres-operator.readthedocs.io/ |
| [PERCONA-EVEREST] | Percona Everest | https://docs.percona.com/everest/ |
| [CLICKHOUSE-OP] | ClickHouse Operator | https://github.com/Altinity/clickhouse-operator |

---

## B.3 Informative References

References that provide background information and context.

### B.3.1 Industry Standards

| ID | Title | URL |
|----|-------|-----|
| [CNCF-PLATFORMS] | CNCF Platforms White Paper | https://tag-app-delivery.cncf.io/whitepapers/platforms/ |
| [BACKSTAGE-CNCF] | Backstage CNCF Incubation | https://www.cncf.io/projects/backstage/ |
| [OPENID-CONNECT] | OpenID Connect Core | https://openid.net/specs/openid-connect-core-1_0.html |

### B.3.2 Backstage Plugins

| ID | Title | URL |
|----|-------|-----|
| [BACKSTAGE-GITHUB] | Backstage GitHub Repository | https://github.com/backstage/backstage |
| [ROADIE-PLUGINS] | Roadie Plugin Directory | https://roadie.io/backstage/plugins/ |
| [TERASKY-PLUGINS] | TeraSky Backstage Plugins | https://github.com/terasky-oss/backstage-plugins |

### B.3.3 Alternative Platforms Evaluated

| ID | Title | URL |
|----|-------|-----|
| [PORT] | Port Developer Portal | https://www.getport.io/ |
| [OPSLEVEL] | OpsLevel | https://www.opslevel.com/ |
| [CORTEX] | Cortex Internal Developer Portal | https://www.cortex.io/ |

---

## B.4 Internal References

### B.4.1 Normative Internal References

| ID | Title | Relationship |
|----|-------|--------------|
| RFC-IAM-0001 | Federated Identity and Access Management Architecture | Provides Keycloak authentication |
| RFC-SECOPS-0001 | GitOps-Native, Vault-First Secret Management Architecture | Provides secret management |
| RFC-PAM-0001 | Privileged Access Management Architecture | Provides JIT access backend |

### B.4.2 Informative Internal References

| ID | Title | Relationship |
|----|-------|--------------|
| RFC-TENANT-SECURITY | Tenant Application Security Architecture | Provides WAF and network policies |
| RFC-WORKLOAD-IDENTITY | Workload Identity Architecture (Planned) | Future: service mesh, AI agent identity |
| RFC-DEPLOY-OPS | Deployment Operations Architecture (Planned) | Future: deployment orchestration |

---

## B.5 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-12 | Platform Engineering Team | Initial release |

---

## B.6 Document Status

| Field | Value |
|-------|-------|
| Status | Draft |
| Review State | Pending |
| Last Review | — |
| Next Review | — |

---

## B.7 Acknowledgments

This RFC builds upon work from:

- Backstage project and CNCF community
- Platform Engineering team for requirements and review
- Security Engineering for authorization model review
- DevOps team for integration patterns

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← Appendix A: Glossary](./appendix-a-glossary.md) | [Table of Contents](./00-index.md#table-of-contents) | — |

---

*End of Appendix B — RFC-DEVELOPER-PLATFORM-0001*

---

*End of RFC-DEVELOPER-PLATFORM-0001*
