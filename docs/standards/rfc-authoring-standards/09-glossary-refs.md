```
RFC Authoring Standards                                           Section 9
Category: Standards Track                       Glossary and References
```

# 9. Glossary and Reference Requirements

[← Rationale](./08-rationale.md) | [Index](./00-index.md) | [Next →](./10-review.md)

---

## 9.1 Term Definitions

Each term MUST include:

| Component | Description |
|-----------|-------------|
| Term | The term in bold |
| Definition | A concise definition |
| Qualification | "As used in this RFC" where meaning differs from common usage |

### Format

```markdown
**Term Name**
Definition of the term. As used in this RFC, this term specifically means...
```

---

## 9.2 ADR Index

Document all significant decisions with:

| Component | Description |
|-----------|-------------|
| Decision ID | ADR-NNN format |
| Summary | Brief decision summary |
| Rationale | Reference to rationale section |
| Definition | Reference to defining section |

### Format

| ADR | Decision | Rationale | Defined In |
|-----|----------|-----------|------------|
| ADR-001 | Use Keycloak for platform identity | 9.1.2 | 3.2.1 |
| ADR-002 | Vault as sole secret source | 9.2.1 | 4.1.1 |

---

## 9.3 Diagram Index

List all diagrams with:

| Component | Description |
|-----------|-------------|
| Name | Diagram name |
| Type | Diagram type (flowchart, sequence, etc.) |
| Location | Section location |

### Format

| Diagram | Type | Section |
|---------|------|---------|
| System Overview | flowchart | 3.1 |
| Authentication Flow | sequenceDiagram | 5.2 |
| Secret Sync | flowchart | 6.1 |

---

## 9.4 Reference Categories

Organize references into:

| Category | Description |
|----------|-------------|
| Normative References | Required for implementation |
| Technology Documentation | Tools and systems referenced |
| Informative References | Background and context |
| Internal References | Other organizational documents |

---

## 9.5 Citation Format

### External Reference

```markdown
**[ABBREV]** Author(s), "Title", Publication, Date.
<URL>
```

### Internal Reference

```markdown
**[INTERNAL-ID]** Team, "Document Title", Internal Documentation.
`path/to/document.md`
```

---

*End of Section 9 — RFC Authoring Standards*
