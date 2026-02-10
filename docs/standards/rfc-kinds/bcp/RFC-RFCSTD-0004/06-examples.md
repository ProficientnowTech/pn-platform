```
RFC-RFCSTD-0004                                                   Section 6
Category: Standards Track                                         Examples
```

# 6. Examples

[← Validation](./05-validation.md) | [Index](./00-index.md) | [Next →](./appendix-a-glossary.md)

---

## 6.1 Guideline Example

**Well-Formed Guideline:**

```markdown
### Guideline 3 — Secret Rotation Scheduling

**Recommendation**: Secret rotation SHOULD be scheduled during low-traffic
periods with at least two operators available.

**Rationale**: Rotation during high-traffic periods increases the blast
radius of potential failures. Having two operators ensures immediate
response capability if issues arise.

**Applicability**: All production secret rotations. Development and staging
environments have more flexibility.

**Exceptions**:
- Emergency rotations due to suspected compromise SHOULD proceed immediately
  regardless of traffic levels.
- Automated rotations with proven reliability MAY proceed during any period.
```

This guideline demonstrates:

| Property | Value |
|----------|-------|
| Uses SHOULD | Yes—not an absolute requirement |
| Has rationale | Yes—explains why |
| Has applicability | Yes—production environments |
| Has exceptions | Yes—emergency and automation cases |

---

## 6.2 Procedure Example

**Well-Formed Procedure:**

```markdown
### Procedure 2 — Manual Secret Rotation

**When to Use**: When automated rotation fails or for secrets not covered
by automated rotation.

**Prerequisites**:
- Operator has Vault admin access
- Change request approved
- Communication sent to affected teams

**Steps**:
1. Verify current secret is accessible and working
2. Generate new secret value following security requirements
3. Store new secret in Vault
4. Trigger application reload or restart
5. Verify applications using new secret successfully
6. Revoke old secret after grace period

**Verification**: All dependent applications report healthy status with
new secret. No authentication errors in logs.

**Recovery**: If applications fail to start with new secret, restore
previous secret from Vault version history and investigate root cause
before retry.
```

This procedure demonstrates:

| Property | Value |
|----------|-------|
| Clear trigger | When automated rotation fails |
| Prerequisites | Access, approval, communication |
| Numbered steps | Sequential actions |
| Verification | How to confirm success |
| Recovery | What to do if it fails |

---

## 6.3 Consideration Example

**Well-Formed Trade-off:**

```markdown
## Trade-offs

### Automated vs Manual Rotation

| Factor | Automated | Manual |
|--------|-----------|--------|
| Consistency | High | Variable |
| Operator burden | Low | High |
| Flexibility | Low | High |
| Audit trail | Automatic | Requires discipline |
| Error rate | Low (once working) | Higher (human error) |
| Initial setup | Complex | Simple |

**Recommendation**: Prefer automated rotation. Use manual rotation for
secrets that cannot be automated or during automation failures.

**Context Dependencies**:
- Small teams with few secrets MAY find manual rotation acceptable
- Large deployments with many secrets SHOULD automate
- Secrets with complex rotation requirements MAY require manual procedures
```

---

## 6.4 Exception Documentation Example

**Well-Documented Exceptions:**

```markdown
### Guideline 5 — Change Review Requirements

**Recommendation**: All production changes SHOULD be reviewed by at least
one person other than the author before deployment.

**Rationale**: Second-person review catches errors, ensures knowledge
sharing, and provides accountability.

**Applicability**: All changes to production systems including
configuration, code, and infrastructure.

**Exceptions**:
- **Emergency fixes**: During active incidents (Sev1/Sev2), changes MAY
  be deployed without prior review. Post-incident review MUST occur
  within 24 hours.
- **Automated rollbacks**: Automated rollback to a previously-approved
  state does not require additional review.
- **Time-sensitive security patches**: Critical security patches MAY
  be expedited with post-deployment review if delay increases risk.
- **Scheduled automated changes**: Changes deployed by approved automation
  (e.g., GitOps) are reviewed at PR time, not deployment time.
```

---

## 6.5 Scope Example

**Well-Defined Scope:**

```markdown
## Scope

### In Scope

| Practice Area | Description |
|---------------|-------------|
| Secret rotation | Procedures for rotating secrets |
| Rotation scheduling | When and how to schedule rotations |
| Rotation verification | How to verify successful rotation |
| Rotation recovery | How to recover from failed rotation |

### Out of Scope

| Area | Reason | Reference |
|------|--------|-----------|
| Secret creation | Covered by initial provisioning | RFC-SPEC-SECRETS-0001 |
| Secret storage architecture | Covered by architecture | RFC-SECRETS-0001 |
| Application secret consumption | Application-specific | Application docs |

### Audience

| Role | Relevance |
|------|-----------|
| Platform operators | Primary—perform rotations |
| Application developers | Secondary—understand impact |
| Security team | Review—audit rotation practices |
```

---

## 6.6 Background Example

**Well-Written Background:**

```markdown
## Background

### Context

Secret rotation is a critical security practice that limits the window
of exposure if a secret is compromised. Regular rotation ensures that
even if a secret is leaked, its useful lifetime is limited.

### History

Prior to this BCP, secret rotation was performed ad-hoc by individual
teams. This led to:
- Inconsistent rotation schedules
- Missing rotations for some secrets
- Lack of verification after rotation
- No standardized recovery procedures

### Motivation

This BCP establishes consistent practices for secret rotation across
all platform services, ensuring:
- Predictable rotation schedules
- Verified rotation procedures
- Documented recovery paths
- Audit trail for compliance
```

---

*End of Section 6 — RFC-RFCSTD-0004*
