```
RFC-RFCSTD-0001                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

[← Requirements](./02-requirements.md) | [Index](./00-index.md) | [Next →](./04-formatting.md)

---

## 3.1 Required Sections for Standards Kind

| Section | File | Requirement | Purpose |
|---------|------|-------------|---------|
| Index | 00-index.md | REQUIRED | Metadata, abstract, TOC, reading paths |
| Scope | 01-scope.md | REQUIRED | Applicability and boundaries |
| Normative Requirements | 02-requirements.md | REQUIRED | Conformance requirements |
| Structure Definition | 03-structure.md | REQUIRED | Section definitions |
| Formatting Standards | 04-formatting.md | RECOMMENDED | Style and presentation |
| Validation Criteria | 05-validation.md | REQUIRED | Compliance verification |
| Examples | 06-examples.md | RECOMMENDED | Illustrative samples |
| Glossary | appendix-a-glossary.md | REQUIRED | Term definitions |
| References | appendix-b-references.md | REQUIRED | Citations |

---

## 3.2 Section Requirement Levels

| Level | Meaning | Omission Criteria |
|-------|---------|-------------------|
| REQUIRED | Section MUST be present | Cannot be omitted |
| RECOMMENDED | Section SHOULD be present | May be omitted with documented justification |
| OPTIONAL | Section MAY be present | May be omitted without justification |

---

## 3.3 Omission Criteria for RECOMMENDED Sections

A RECOMMENDED section MAY be omitted when ALL of the following criteria are met:

| Criterion | Verification |
|-----------|--------------|
| Irrelevance | Section content does not apply to this RFC's scope |
| No Loss of Clarity | Omission does not create ambiguity |
| Documented | Omission noted in Index with brief rationale |
| Reviewer Agreement | Reviewers agree omission is appropriate |

---

## 3.4 Section Content Requirements

### 3.4.1 Index Section (00-index.md)

The index MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| RFC Header | REQUIRED | Standard header block with RFC ID and category |
| Metadata Table | REQUIRED | All metadata fields including Kind |
| Abstract | REQUIRED | 2-4 paragraph summary |
| Scope Boundaries | REQUIRED | In-scope and out-of-scope table |
| Table of Contents | REQUIRED | Links to all sections |
| Reading Paths | RECOMMENDED | Audience-specific navigation guides |

### 3.4.2 Scope Section (01-scope.md)

The scope section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Purpose | REQUIRED | What the RFC achieves |
| Applicability | REQUIRED | What documents this RFC governs |
| Audience | REQUIRED | Who should read this RFC |
| Non-Goals | RECOMMENDED | What is explicitly excluded |
| Conformance Statement | REQUIRED | RFC 2119 interpretation clause |

### 3.4.3 Requirements Section (02-requirements.md)

The requirements section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Numbered Requirements | REQUIRED | Each requirement with unique identifier |
| RFC 2119 Keywords | REQUIRED | All requirements use proper keywords |
| Rationale | RECOMMENDED | Why each requirement exists |

### 3.4.4 Structure Section (03-structure.md)

The structure section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Section List | REQUIRED | All sections with requirement levels |
| File Naming | REQUIRED | Expected file names for each section |
| Content Requirements | REQUIRED | What each section must contain |

### 3.4.5 Formatting Section (04-formatting.md)

The formatting section SHOULD include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Header Format | REQUIRED | Standard header block format |
| Metadata Format | REQUIRED | Metadata table format |
| Table Standards | RECOMMENDED | When and how to use tables |
| Heading Hierarchy | RECOMMENDED | H1-H4 usage guidelines |

### 3.4.6 Validation Section (05-validation.md)

The validation section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Structural Validation | REQUIRED | How to verify structure compliance |
| Content Validation | REQUIRED | How to verify content compliance |
| Cross-Reference Validation | RECOMMENDED | How to verify links and references |

### 3.4.7 Examples Section (06-examples.md)

The examples section SHOULD include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Positive Examples | RECOMMENDED | Compliant examples |
| Negative Examples | OPTIONAL | Non-compliant examples with explanation |
| Partial Examples | RECOMMENDED | Focused examples of specific aspects |

### 3.4.8 Glossary (appendix-a-glossary.md)

The glossary MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Term Definitions | REQUIRED | All RFC-specific terms defined |
| Consistent Format | REQUIRED | Each term follows same format |

### 3.4.9 References (appendix-b-references.md)

The references section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Normative References | REQUIRED | Standards that MUST be followed |
| Informative References | RECOMMENDED | Background and context |
| Internal References | REQUIRED | Related internal RFCs |
| Version History | REQUIRED | Change log for this RFC |

---

## 3.5 File Naming Convention

| Pattern | Usage |
|---------|-------|
| `00-index.md` | Always the index file |
| `NN-<section>.md` | Numbered sections (01-99) |
| `appendix-<letter>-<name>.md` | Appendices |

---

*End of Section 3 — RFC-RFCSTD-0001*
