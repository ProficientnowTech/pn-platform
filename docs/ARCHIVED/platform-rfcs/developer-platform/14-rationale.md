```
RFC-DEVELOPER-PLATFORM-0001                                      Section 14
Category: Standards Track                                       Rationale
```

# 14. Rationale

[← Platform Integrations](./13-platform-integrations.md) | [Index](./00-index.md#table-of-contents) | [Next: Evolution →](./15-evolution.md)

---

## 14.1 Portal Framework Selection

### 14.1.1 Decision

**Selected: Backstage (CNCF Incubating)**

Backstage is selected as the developer portal framework. Backstage is an open platform for building developer portals, originally created by Spotify and now a CNCF Incubating project.

### 14.1.2 Selection Criteria

| Criterion | Weight | Rationale |
|-----------|--------|-----------|
| Open source | High | No vendor lock-in |
| CNCF governance | High | Community-driven roadmap |
| Plugin ecosystem | High | Extensibility for platform tools |
| Production adoption | High | Proven at scale |
| Kubernetes-native | Medium | Aligns with platform |
| Self-hosted | Medium | Data sovereignty |
| Active community | Medium | Support and contributions |

### 14.1.3 Decision Rationale

Backstage was selected because:

| Factor | Rationale | Invariant Support |
|--------|-----------|-------------------|
| Open source | No licensing costs, auditable code | Cost, transparency |
| Plugin architecture | Enables platform-specific integrations | INV-14 |
| Permission framework | Built-in capability-based authorization | INV-2, INV-3 |
| Catalog model | Entity-based service registry | INV-7 |
| Template system | Golden path implementation | INV-5 |
| TechDocs | Documentation-as-code | INV-8 |
| OIDC support | Keycloak integration | INV-1 |
| Adoption | Over 3,400 organizations, proven patterns | Risk reduction |

---

## 14.2 Rejected Alternatives

### 14.2.1 Port

**Description**: Port is a commercial Internal Developer Platform with visual no-code configuration.

**Why It Was Attractive**:
- No-code configuration for rapid setup
- Built-in data model for common patterns
- Visual workflow builder
- Managed service option

**Why It Was Rejected**:

| Reason | Impact | Invariant Violation |
|--------|--------|---------------------|
| Commercial licensing | Recurring costs, budget dependency | Cost |
| Vendor lock-in | Tied to vendor roadmap | Operational risk |
| Limited extensibility | Cannot implement custom integrations | INV-14 |
| Managed service | Less control over data and security | Security |

**Conclusion**: Port's commercial model and limited extensibility conflict with platform requirements for open, extensible infrastructure.

### 14.2.2 OpsLevel

**Description**: OpsLevel is a commercial service catalog and developer portal focused on service ownership and operational maturity.

**Why It Was Attractive**:
- Strong service ownership model
- Maturity scoring
- Built-in standards enforcement
- Integration marketplace

**Why It Was Rejected**:

| Reason | Impact | Invariant Violation |
|--------|--------|---------------------|
| Commercial licensing | Recurring costs | Cost |
| Limited customization | Cannot implement platform-specific workflows | INV-5 |
| Less flexible templates | Constrained golden path implementation | INV-5 |
| Closed source | Cannot audit or extend core functionality | Transparency |

**Conclusion**: OpsLevel's commercial model and customization limitations do not align with platform extensibility requirements.

### 14.2.3 Cortex

**Description**: Cortex is a commercial Internal Developer Portal with AI-powered features and analytics.

**Why It Was Attractive**:
- AI-powered insights
- Strong analytics and reporting
- Service maturity tracking
- Automated documentation

**Why It Was Rejected**:

| Reason | Impact | Invariant Violation |
|--------|--------|---------------------|
| Commercial licensing | Recurring costs | Cost |
| Black-box AI | Cannot audit decision logic | Transparency |
| Vendor dependency | Platform evolution tied to vendor | Operational risk |
| Limited self-hosting | Data sovereignty concerns | Security |

**Conclusion**: Cortex's AI-first approach and commercial model introduce unacceptable vendor dependency and transparency limitations.

### 14.2.4 Custom Build

**Description**: Building a custom developer portal from scratch using standard web frameworks.

**Why It Was Attractive**:
- Complete control over functionality
- Exact fit for requirements
- No external dependencies
- Custom user experience

**Why It Was Rejected**:

| Reason | Impact | Invariant Violation |
|--------|--------|---------------------|
| Development effort | Significant engineering investment | Resource |
| Maintenance burden | Ongoing feature development | Resource |
| No ecosystem | Must build all integrations | INV-14 |
| Reinventing patterns | Duplicating solved problems | INV-5 |

**Conclusion**: Custom development would require significant investment to replicate functionality already proven in Backstage, violating the golden path principle of building on established patterns.

### 14.2.5 Flightdeck (Arctir)

**Description**: Flightdeck is an open-source simplified Backstage deployment wrapper.

**Why It Was Attractive**:
- Simplified Backstage deployment
- Pre-configured plugins
- Reduced setup complexity
- Open source

**Why It Was Rejected**:

| Reason | Impact |
|--------|--------|
| Smaller community | Fewer plugins, less support |
| Less documentation | Higher learning curve |
| Dependency layer | Additional abstraction to maintain |
| Backstage subset | May limit future extensibility |

**Conclusion**: While Flightdeck simplifies deployment, direct Backstage usage provides greater flexibility and community support.

---

## 14.3 Design Decisions

### 14.3.1 Capability-Based UI

**Decision**: Implement capability-based UI rendering instead of runtime authorization blocking.

**Rationale**:

| Factor | Justification |
|--------|---------------|
| User experience | Users not confused by unavailable options |
| Error reduction | No "access denied" scenarios |
| Security model | Authorization through visibility |
| Alignment | Matches RFC-IAM-0001 authorization model |

**Alternatives Considered**:
- Runtime authorization blocking: Rejected due to poor UX and error scenarios
- Role-based UI templates: Rejected due to maintenance complexity

### 14.3.2 GitOps-Only Output

**Decision**: All self-service actions produce Git commits, no direct API modifications.

**Rationale**:

| Factor | Justification |
|--------|---------------|
| Audit trail | All changes tracked in version control |
| Peer review | Optional review for sensitive changes |
| Rollback | Git-based rollback capability |
| Consistency | Single deployment pathway |

**Alternatives Considered**:
- Direct API calls: Rejected due to audit trail gaps and bypass risk
- Hybrid approach: Rejected due to inconsistent operational model

### 14.3.3 Documentation Colocation

**Decision**: Require documentation in code repositories (TechDocs), not external wikis.

**Rationale**:

| Factor | Justification |
|--------|---------------|
| Currency | Documentation updated with code |
| Ownership | Same team owns code and docs |
| Review | Documentation changes in PRs |
| Discovery | Docs visible in developer workflow |

**Alternatives Considered**:
- External wiki: Rejected due to drift and ownership issues
- Hybrid approach: Rejected due to discoverability fragmentation

---

## 14.4 Trade-offs

### 14.4.1 Self-Hosting Trade-off

**Trade-off**: Self-hosted Backstage requires operational investment.

| Benefit | Cost |
|---------|------|
| Data sovereignty | Infrastructure management |
| Customization freedom | Upgrade responsibility |
| No licensing fees | Engineering time |

**Mitigation**: Helm chart deployment, GitOps management, documented runbooks.

### 14.4.2 Plugin Development Trade-off

**Trade-off**: Platform-specific plugins require development effort.

| Benefit | Cost |
|---------|------|
| Exact integration fit | Development time |
| Platform-specific UX | Maintenance burden |
| No external dependency | Testing requirements |

**Mitigation**: Start with community plugins, develop custom plugins incrementally.

### 14.4.3 Golden Path Trade-off

**Trade-off**: Opinionated templates reduce flexibility.

| Benefit | Cost |
|---------|------|
| Consistency | Less flexibility |
| Compliance by default | Cannot deviate from standard |
| Faster onboarding | May not fit all use cases |

**Mitigation**: Multiple templates for common scenarios, escape hatches for exceptions.

---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← 13. Platform Integrations](./13-platform-integrations.md) | [Table of Contents](./00-index.md#table-of-contents) | [15. Evolution →](./15-evolution.md) |

---

*End of Section 14 — RFC-DEVELOPER-PLATFORM-0001*
