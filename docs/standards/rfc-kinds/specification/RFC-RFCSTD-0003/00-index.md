```
RFC-RFCSTD-0003                                                   Section 0
Category: Standards Track                                             Index
```

# RFC-RFCSTD-0003: RFC Kind — Specification

[Index](./00-index.md) | [Next →](./01-scope.md)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-RFCSTD-0003 |
| Title | RFC Kind: Specification |
| Status | Draft |
| Category | Standards Track |
| Kind | Standards |
| Version | 1.1.0 |
| Author | Platform Engineering |
| Created | 2026-02-10 |
| Last Updated | 2026-02-10 |

---

## Abstract

This RFC defines the Specification kind—implementation-focused RFCs that define how to implement an architecture without containing code. Specification RFCs bridge the gap between Architecture RFCs (conceptual design) and actual implementation.

Specification RFCs define the "how" of implementation through:

- Prerequisites (required and optional dependencies)
- Phased implementation plans (task → test → iterate)
- Resource definitions (tabular, not code)
- Validation criteria (deterministic verification)
- Test requirements (categories and acceptance criteria)
- Risk documentation (features, caveats, loopholes, mitigations)

Specification RFCs do NOT contain working code. They provide sufficient detail for an implementer to build the system correctly without embedding implementation artifacts.

---

## Scope Boundaries

| Aspect | In Scope | Out of Scope |
|--------|----------|--------------|
| Content | Implementation requirements, validation criteria | Working code, configuration files |
| Focus | How to implement | What to implement (Architecture) |
| Audience | Implementers, operators | Architects (see Architecture RFCs) |
| Format | Tabular resource definitions | YAML, JSON, shell scripts |

---

## Table of Contents

### Core Sections

| Section | File | Description |
|---------|------|-------------|
| 0. Index | [00-index.md](./00-index.md) | This file — metadata, abstract, navigation |
| 1. Scope | [01-scope.md](./01-scope.md) | Applicability and what Specification RFCs cover |
| 2. Normative Requirements | [02-requirements.md](./02-requirements.md) | Rules for writing Specification RFCs |
| 3. Structure Definition | [03-structure.md](./03-structure.md) | Required and optional sections |
| 4. Formatting Standards | [04-formatting.md](./04-formatting.md) | Style and presentation |
| 5. Validation Criteria | [05-validation.md](./05-validation.md) | How to verify compliance |
| 6. Examples | [06-examples.md](./06-examples.md) | Sample prerequisites, phases, resources, validation |

### Appendices

| Appendix | File | Description |
|----------|------|-------------|
| A. Glossary | [appendix-a-glossary.md](./appendix-a-glossary.md) | Term definitions |
| B. References | [appendix-b-references.md](./appendix-b-references.md) | Citations and version history |

---

## Reading Paths

### For Specification RFC Authors

1. Start with [Scope](./01-scope.md) to understand what Specification RFCs cover
2. Read [Normative Requirements](./02-requirements.md) for mandatory rules
3. Follow [Structure Definition](./03-structure.md) for section organization
4. Review [Examples](./06-examples.md) for practical guidance on tabular formats

### For RFC Reviewers

1. Use [Validation Criteria](./05-validation.md) as review checklist
2. Reference [Normative Requirements](./02-requirements.md) for compliance
3. Check [Structure Definition](./03-structure.md) for completeness

### For Implementers Reading Specification RFCs

1. Start with Prerequisites to understand what you need
2. Follow Phases sequentially (task → test → iterate)
3. Use Resource tables as implementation guides
4. Validate using Validation Criteria

---

*End of Index — RFC-RFCSTD-0003*
