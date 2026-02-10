```
RFC-RFCSTD-0004                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

[← Requirements](./02-requirements.md) | [Index](./00-index.md) | [Next →](./04-formatting.md)

---

## 3.1 Required Sections for BCP Kind

BCP RFCs MAY be single-file or multi-file depending on complexity:

| Section | File | Requirement | Purpose |
|---------|------|-------------|---------|
| Index | 00-index.md or inline | REQUIRED | Metadata, abstract, applicability |
| Scope | 01-scope.md or inline | REQUIRED | When this BCP applies |
| Background | 02-background.md or inline | RECOMMENDED | Context and motivation |
| Guidelines | 03-guidelines.md or inline | REQUIRED | Recommended practices |
| Procedures | 04-procedures.md or inline | CONDITIONAL | Operational procedures (if applicable) |
| Considerations | 05-considerations.md or inline | RECOMMENDED | Trade-offs and alternatives |
| Glossary | appendix-a-glossary.md | REQUIRED | Terms |
| References | appendix-b-references.md | REQUIRED | Related RFCs, external docs |

---

## 3.2 Section Requirement Levels

| Level | Meaning | Omission Criteria |
|-------|---------|-------------------|
| REQUIRED | Section MUST be present | Cannot be omitted |
| RECOMMENDED | Section SHOULD be present | May omit with justification in Index |
| CONDITIONAL | Section MUST be present if criteria met | May omit if criteria don't apply |

### 3.2.1 Procedures Section Criteria (CONDITIONAL)

The Procedures section is REQUIRED when:

| Criterion | Example |
|-----------|---------|
| BCP includes step-by-step operational tasks | Secret rotation procedure |
| BCP describes how to perform specific actions | Incident response steps |

The Procedures section MAY be omitted when:

| Criterion | Example |
|-----------|---------|
| BCP is purely guidelines-based | Code review guidelines |
| No specific operational tasks are described | Security principles |

---

## 3.3 Section Content Requirements

### 3.3.1 Index Section

The index MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Metadata Table | REQUIRED | All fields including Kind: BCP |
| Abstract | REQUIRED | Brief summary of practices covered |
| Applicability Statement | REQUIRED | Who should follow this BCP |
| Table of Contents | REQUIRED | Links to all sections |

### 3.3.2 Scope Section

The scope section MUST define:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| In Scope | REQUIRED | What practices this BCP covers |
| Out of Scope | REQUIRED | What is explicitly excluded |
| Audience | REQUIRED | Who should follow these practices |
| Prerequisites | RECOMMENDED | Knowledge or access required |

### 3.3.3 Background Section

The background section SHOULD include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Context | RECOMMENDED | Why these practices exist |
| History | OPTIONAL | How practices evolved |
| Motivation | RECOMMENDED | Problems these practices solve |

### 3.3.4 Guidelines Section

Each guideline MUST follow this structure:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Recommendation | REQUIRED | Statement using SHOULD/RECOMMENDED |
| Rationale | REQUIRED | Why this is recommended |
| Applicability | REQUIRED | When to apply |
| Exceptions | REQUIRED | When this may not apply |

### 3.3.5 Procedures Section (Conditional)

If included, each procedure MUST follow this structure:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| When to Use | REQUIRED | Trigger conditions |
| Prerequisites | REQUIRED | What must be true before starting |
| Steps | REQUIRED | Sequential actions |
| Verification | REQUIRED | How to confirm success |
| Recovery | REQUIRED | What to do if procedure fails |

### 3.3.6 Considerations Section

The considerations section SHOULD include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Trade-offs | RECOMMENDED | Costs and benefits of recommendations |
| Alternatives | RECOMMENDED | Other valid approaches |
| Context Dependencies | RECOMMENDED | How context affects applicability |
| Evolution Notes | OPTIONAL | How these practices may change |

### 3.3.7 Glossary

The glossary MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Term Definitions | REQUIRED | All BCP-specific terms |
| Consistent Format | REQUIRED | Each term follows same format |

### 3.3.8 References

The references section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Related RFCs | REQUIRED | Architecture, Specification RFCs |
| External References | RECOMMENDED | Industry standards, documentation |
| Version History | REQUIRED | Change log for this BCP |

---

## 3.4 File Naming Convention

For multi-file BCPs:

| Pattern | Usage |
|---------|-------|
| `00-index.md` | Index |
| `01-scope.md` | Scope |
| `02-background.md` | Background |
| `03-guidelines.md` | Guidelines |
| `04-procedures.md` | Procedures (if applicable) |
| `05-considerations.md` | Considerations |
| `appendix-<letter>-<name>.md` | Appendices |

For single-file BCPs:

| Pattern | Usage |
|---------|-------|
| `RFC-BCP-<DOMAIN>-NNNN.md` | Complete BCP in one file |

---

*End of Section 3 — RFC-RFCSTD-0004*
