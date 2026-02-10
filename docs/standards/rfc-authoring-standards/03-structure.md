```
RFC Authoring Standards                                           Section 3
Category: Standards Track                              Document Structure
```

# 3. Document Structure

[← Versioning](./02-versioning.md) | [Index](./00-index.md) | [Next →](./04-content.md)

---

## 3.1 Multi-File Organization

Each RFC MUST be organized as a directory containing multiple markdown files. The specific structure depends on the RFC Kind (see Section 1.4).

**General Directory Structure:**

| Path Pattern | RFC Type |
|--------------|----------|
| `docs/platform/rfcs/<domain>/` | Architecture RFCs |
| `docs/platform/rfcs/spec-<domain>/` | Specification RFCs |
| `docs/platform/rfcs/bcp-<domain>/` | BCP RFCs |
| `docs/standards/rfc-kinds/<kind>/` | Standards RFCs |

---

## 3.2 File Naming Conventions

| Rule | Description |
|------|-------------|
| Case | Files MUST use lowercase with hyphens as separators |
| Prefix | Files MUST be prefixed with two-digit section numbers |
| Sequence | Section numbers MUST be sequential starting from 00 |
| Appendices | Appendices MUST use format `appendix-<letter>-<name>.md` |

---

## 3.3 Section Requirement Levels

Each section in an RFC has a requirement level:

| Level | Meaning | File Presence |
|-------|---------|---------------|
| REQUIRED | Section MUST be present | File MUST exist |
| CONDITIONAL | Section MUST be present if criteria met | File MUST exist if criteria apply |
| RECOMMENDED | Section SHOULD be present | File SHOULD exist |
| OPTIONAL | Section MAY be present | File MAY exist |

---

## 3.4 Omission Criteria for Non-Required Sections

A RECOMMENDED or OPTIONAL section MAY be omitted when ALL of the following criteria are met:

| Criterion | Description |
|-----------|-------------|
| Irrelevance | The section content does not apply to this RFC's scope |
| No Loss of Clarity | Omission does not create ambiguity about the RFC's intent |
| Documented Justification | The omission is noted in the Index with brief rationale |
| Reviewer Agreement | RFC reviewers agree the omission is appropriate |

**Omission Documentation Format** (in 00-index.md):

```markdown
### Omitted Sections

| Section | Reason for Omission |
|---------|---------------------|
| NN-evolution.md | RFC defines a static process with no planned extensions |
```

---

## 3.5 Common Sections Across All Kinds

Regardless of Kind, every RFC MUST include these sections:

| Section | File | Requirement | Purpose |
|---------|------|-------------|---------|
| Index | 00-index.md | REQUIRED | Metadata, abstract, TOC |
| Glossary | appendix-a-glossary.md | REQUIRED | Term definitions |
| References | appendix-b-references.md | REQUIRED | Citations and version history |

---

## 3.6 Kind-Specific Section Requirements

Section requirements vary by RFC Kind. See the governing RFC for each kind:

| Kind | Governing RFC | Section Requirements |
|------|---------------|---------------------|
| Standards | RFC-RFCSTD-0001 | `docs/standards/rfc-kinds/standards/RFC-RFCSTD-0001/` |
| Architecture | RFC-RFCSTD-0002 | `docs/standards/rfc-kinds/architecture/RFC-RFCSTD-0002/` |
| Specification | RFC-RFCSTD-0003 | `docs/standards/rfc-kinds/specification/RFC-RFCSTD-0003/` |
| BCP | RFC-RFCSTD-0004 | `docs/standards/rfc-kinds/bcp/RFC-RFCSTD-0004/` |

---

## 3.7 Architecture Kind Sections

| Section | File | Requirement | Omission Criteria |
|---------|------|-------------|-------------------|
| Index | 00-index.md | REQUIRED | — |
| Introduction | 01-introduction.md | REQUIRED | — |
| Requirements | 02-requirements.md | REQUIRED | — |
| Architecture | 03-architecture.md | REQUIRED | — |
| Components | 04-components.md | REQUIRED | — |
| Domain Sections | 05-*.md | CONDITIONAL | Required if domain has specific mechanics |
| Rationale | NN-rationale.md | REQUIRED | — |
| Evolution | NN-evolution.md | RECOMMENDED | May omit if static, non-extensible system |
| Glossary | appendix-a-glossary.md | REQUIRED | — |
| References | appendix-b-references.md | REQUIRED | — |

---

## 3.8 Specification Kind Sections

| Section | File | Requirement | Omission Criteria |
|---------|------|-------------|-------------------|
| Index | 00-index.md | REQUIRED | — |
| Prerequisites | 01-prerequisites.md | REQUIRED | — |
| Phases | 02-phases.md | REQUIRED | — |
| Resources | 03-resources.md | REQUIRED | — |
| Validation | 04-validation.md | REQUIRED | — |
| Testing | 05-testing.md | REQUIRED | — |
| Risks | 06-risks.md | REQUIRED | — |
| Glossary | appendix-a-glossary.md | REQUIRED | — |
| References | appendix-b-references.md | REQUIRED | — |

---

## 3.9 BCP Kind Sections

| Section | File | Requirement | Omission Criteria |
|---------|------|-------------|-------------------|
| Index | 00-index.md | REQUIRED | — |
| Scope | 01-scope.md | REQUIRED | — |
| Background | 02-background.md | RECOMMENDED | May omit if context is obvious |
| Guidelines | 03-guidelines.md | REQUIRED | — |
| Procedures | 04-procedures.md | CONDITIONAL | Include only if BCP defines procedures |
| Considerations | 05-considerations.md | RECOMMENDED | May omit for simple BCPs |
| Glossary | appendix-a-glossary.md | REQUIRED | — |
| References | appendix-b-references.md | REQUIRED | — |

---

## 3.10 Standards Kind Sections

| Section | File | Requirement | Omission Criteria |
|---------|------|-------------|-------------------|
| Index | 00-index.md | REQUIRED | — |
| Scope | 01-scope.md | REQUIRED | — |
| Requirements | 02-requirements.md | REQUIRED | — |
| Structure | 03-structure.md | REQUIRED | — |
| Formatting | 04-formatting.md | RECOMMENDED | May omit if no kind-specific formatting |
| Validation | 05-validation.md | REQUIRED | — |
| Examples | 06-examples.md | RECOMMENDED | May omit for simple standards |
| Glossary | appendix-a-glossary.md | REQUIRED | — |
| References | appendix-b-references.md | REQUIRED | — |

---

*End of Section 3 — RFC Authoring Standards*
