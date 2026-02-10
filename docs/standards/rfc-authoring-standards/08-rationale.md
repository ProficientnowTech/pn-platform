```
RFC Authoring Standards                                           Section 8
Category: Standards Track                          Rationale Requirements
```

# 8. Rationale Section Requirements

[← Invariants](./07-invariants.md) | [Index](./00-index.md) | [Next →](./09-glossary-refs.md)

---

## 8.1 Purpose

The rationale section documents why alternatives were rejected. This:

| Purpose | Benefit |
|---------|---------|
| Prevents re-litigation | Decisions don't need to be justified again |
| Provides context | Future architects understand constraints |
| Documents trade-offs | Shows what was considered |
| Links to invariants | Explains which rules drove decisions |

---

## 8.2 Required Structure for Each Alternative

Each rejected alternative MUST include:

| Component | Description |
|-----------|-------------|
| Description | What the alternative is |
| Why It Was Attractive | Genuine benefits considered |
| Why It Was Rejected | Specific failures or violations |
| Invariants Violated | Reference to specific invariants |
| Conclusion | Summary judgment |

### Format

```markdown
### N.N.N <Alternative Name>

**Description**: What the alternative is.

**Why It Was Attractive**:
- Genuine benefit 1
- Genuine benefit 2

**Why It Was Rejected**:
- Specific failure 1
- Specific failure 2
- Violates Invariant N

**Conclusion**: Summary judgment.
```

---

## 8.3 Example

```markdown
### 9.1.2 Direct Azure AD Integration

**Description**: Each application integrates directly with Azure AD
without a platform identity layer.

**Why It Was Attractive**:
- Simpler initial setup—no Keycloak to maintain
- Native Microsoft tooling support
- One fewer component in the stack

**Why It Was Rejected**:
- Each application requires separate Azure AD configuration
- No centralized platform-level authorization
- Cannot add platform-specific claims or roles
- Violates Invariant 2 (Authentication Chain)

**Conclusion**: Direct integration prevents unified platform identity
and would require each team to implement authentication separately.
```

---

## 8.4 Intellectual Honesty

| Rule | Description |
|------|-------------|
| Acknowledge benefits | Acknowledge genuine benefits of rejected alternatives |
| Context matters | Explain context where alternatives might be appropriate |
| No dismissiveness | Avoid dismissive language |
| Document attempts | Document if alternative was actually tried |

---

*End of Section 8 — RFC Authoring Standards*
