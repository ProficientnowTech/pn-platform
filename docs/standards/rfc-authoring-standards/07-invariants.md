```
RFC Authoring Standards                                           Section 7
Category: Standards Track                      Invariants and Requirements
```

# 7. Invariants and Requirements

[← Language](./06-language.md) | [Index](./00-index.md) | [Next →](./08-rationale.md)

---

## 7.1 Invariant Specification

Invariants MUST be:

| Property | Description |
|----------|-------------|
| Numbered | Sequentially (Invariant 1, Invariant 2, etc.) |
| Normative | Stated using RFC 2119 keywords |
| Falsifiable | Can be tested for violation |
| Referenced | Referenced when rejecting alternatives |

### Format

```markdown
### Invariant N — <Short Title>

<Statement using MUST/MUST NOT>

<Brief explanation of why this invariant exists>
```

### Example

```markdown
### Invariant 3 — Secret Authority

HashiCorp Vault MUST be the sole authoritative source for secrets
required by platform applications.

This invariant ensures centralized secret lifecycle management
and auditability. Violation would create untracked secrets
outside the rotation and audit framework.
```

---

## 7.2 Design Goal Specification

Design goals describe desired properties without absolute requirements.

### Format

```markdown
### N.N.N <Goal Title>

<Description of the goal>

<Why this goal matters>
```

### Example

```markdown
### 2.1.1 Unified Identity

All platform users and services authenticate through a single
identity chain, enabling consistent authorization across all
platform applications.

Unified identity reduces operational complexity and ensures
consistent security policy enforcement.
```

---

## 7.3 Non-Goal Specification

Non-goals explicitly exclude concerns from the RFC scope.

### Format

```markdown
### N.N.N <Non-Goal Title>

<What is excluded>

<Why it is excluded or where it is addressed>
```

### Example

```markdown
### 2.2.1 User Provisioning

This architecture does NOT define how users are created or
deprovisioned. User lifecycle management is out of scope.

See RFC-IDENTITY-LIFECYCLE-0001 for user provisioning.
```

---

## 7.4 Success Criteria

Success criteria define how to validate the architecture achieves its goals.

### Format

| Criterion | Metric | Target |
|-----------|--------|--------|
| All authentications via Keycloak | Audit log analysis | 100% |
| Secret rotation automated | Manual intervention count | 0 per rotation |
| Deployment rollback time | Time from decision to completion | < 5 minutes |

---

*End of Section 7 — RFC Authoring Standards*
