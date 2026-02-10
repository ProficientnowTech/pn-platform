```
RFC-RFCSTD-0004                                                   Section 4
Category: Standards Track                           Formatting Standards
```

# 4. Formatting Standards

[← Structure](./03-structure.md) | [Index](./00-index.md) | [Next →](./05-validation.md)

---

## 4.1 Document Header

BCP files MUST begin with:

```
```
RFC-BCP-<DOMAIN>-NNNN                                             Section N
Category: Best Current Practice                             <Section Title>
```

# N. Section Title

[← Previous](./prev.md) | [Index](./00-index.md) | [Next →](./next.md)

---
```

---

## 4.2 BCP Identifier Format

BCP RFCs use the identifier format:

```
RFC-BCP-<DOMAIN>-<NUMBER>
```

Examples:

| ID | Domain |
|----|--------|
| RFC-BCP-SECOPS-0001 | Security Operations |
| RFC-BCP-DEPLOY-0001 | Deployment |
| RFC-BCP-ONCALL-0001 | On-Call Practices |

---

## 4.3 Guideline Format

Guidelines MUST follow this format:

```markdown
### Guideline N — Title

**Recommendation**: [Statement using SHOULD/RECOMMENDED]

**Rationale**: [Why this is recommended]

**Applicability**: [When to apply]

**Exceptions**: [When this may not apply]
```

---

## 4.4 Procedure Format

Procedures SHOULD use:

| Element | Format |
|---------|--------|
| Sequential actions | Numbered steps |
| Parallel options | Bullet points |
| Command descriptions | Prose (not actual commands) |
| Decision points | Tables |

```markdown
### Procedure N — Title

**When to Use**: [Trigger conditions]

**Prerequisites**:
- [What must be true before starting]

**Steps**:
1. [First step - describe action, not command]
2. [Second step]
...

**Verification**: [How to confirm success]

**Recovery**: [What to do if procedure fails]
```

**Note**: Procedures describe WHAT to do, not exact commands. Exact commands belong in runbooks or automation, not BCPs.

---

## 4.5 Keyword Usage

BCPs SHOULD follow this keyword distribution:

| Keyword | Usage | Frequency |
|---------|-------|-----------|
| SHOULD | Primary keyword for recommendations | High |
| RECOMMENDED | Alternative to SHOULD | Medium |
| MAY | For optional practices | Medium |
| MUST | Reserved for safety/compliance | Low |
| MUST NOT | Reserved for safety/compliance | Low |

---

## 4.6 Consideration Format

Trade-offs SHOULD be presented in tables:

```markdown
## Trade-offs

### Automated vs Manual Rotation

| Factor | Automated | Manual |
|--------|-----------|--------|
| Consistency | High | Variable |
| Operator burden | Low | High |
| Flexibility | Low | High |
| Audit trail | Automatic | Requires discipline |

**Recommendation**: Prefer automated rotation. Use manual rotation for
secrets that cannot be automated or during automation failures.
```

---

## 4.7 Exception Format

Exceptions SHOULD be clearly structured:

```markdown
**Exceptions**:
- Emergency rotations due to suspected compromise SHOULD proceed
  immediately regardless of traffic levels.
- Automated rotations with proven reliability MAY proceed during
  any period.
- First-time rotations SHOULD be scheduled during low-traffic
  periods even if automation is used.
```

---

## 4.8 Navigation and Footer

Same as other RFC kinds:

- Navigation links after header
- Footer with RFC identifier at end

---

*End of Section 4 — RFC-RFCSTD-0004*
