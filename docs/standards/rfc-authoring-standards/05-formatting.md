```
RFC Authoring Standards                                           Section 5
Category: Standards Track                           Formatting Standards
```

# 5. Formatting Standards

[← Content](./04-content.md) | [Index](./00-index.md) | [Next →](./06-language.md)

---

## 5.1 Document Header

Each file MUST begin with a header block:

```markdown
```
RFC-<ID>                                              Section N
Category: <Category>                              <Section Title>
```

# N. Section Title

[← Previous: Title](./file.md) | [Index](./00-index.md) | [Next: Title →](./file.md)

---
```

---

## 5.2 Section Numbering

| Level | Format | Example |
|-------|--------|---------|
| Top-level | Single integers | 1, 2, 3 |
| Subsections | Decimal notation | 1.1, 1.2, 2.1 |
| Sub-subsections | Three levels max | 1.1.1 |

Maximum depth SHOULD be three levels (1.1.1).

---

## 5.3 Navigation Footer

Each file MUST end with a navigation footer:

```markdown
---

## Document Navigation

| Previous | Index | Next |
|----------|-------|------|
| [← N-1. Title](./file.md) | [Table of Contents](./00-index.md) | [N+1. Title →](./file.md) |

---

*End of Section N*
```

---

## 5.4 Tables

Tables SHOULD be used for:

| Use Case | Example |
|----------|---------|
| Requirement matrices | Section requirement levels |
| Component comparisons | Feature comparison |
| Status mappings | Status definitions |
| Reference indexes | RFC cross-references |

Tables MUST have:

- Headers
- Consistent column alignment
- Concise content (not prose)

---

## 5.5 Diagrams

Diagrams MUST use Mermaid syntax for:

| Diagram Type | Use For |
|--------------|---------|
| flowchart | Architecture overviews, trust boundaries |
| sequenceDiagram | Sequence flows, interactions |
| stateDiagram-v2 | State machines |

All diagrams MUST be indexed in Appendix A (Glossary).

---

## 5.6 Code Blocks

### Permitted

| Use | Language Hint |
|-----|---------------|
| Mermaid diagrams | `mermaid` |
| File paths and identifiers | none |
| Configuration keys (without values) | none |
| Format specifications | `markdown` |

### Prohibited

| Content | Why |
|---------|-----|
| Implementation code | RFCs describe behavior |
| Working configuration | Belongs in repos |
| Shell commands | RFCs are not runbooks |
| Scripts | Implementation detail |

---

*End of Section 5 — RFC Authoring Standards*
