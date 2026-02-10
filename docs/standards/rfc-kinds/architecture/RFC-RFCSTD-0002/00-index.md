```
RFC-RFCSTD-0002                                                   Section 0
Category: Standards Track                                             Index
```

# RFC-RFCSTD-0002: RFC Kind — Architecture

[Index](./00-index.md) | [Next →](./01-scope.md)

---

## RFC Metadata

| Field | Value |
|-------|-------|
| RFC ID | RFC-RFCSTD-0002 |
| Title | RFC Kind: Architecture |
| Status | Draft |
| Category | Standards Track |
| Kind | Standards |
| Version | 1.1.0 |
| Author | [Shaik Noorullah](https://github.com/shaik-noorullah) |
| Created | 2026-02-10 |
| Last Updated | 2026-02-10 |

---

## Abstract

This RFC defines the Architecture kind—conceptual RFCs that describe system design without implementation details. Architecture RFCs establish what a system does and why, defining trust boundaries, invariants, components, and design rationale.

Architecture RFCs describe the "what" and "why" of a system. They do NOT describe the "how"—implementation details belong in Specification RFCs (RFC-RFCSTD-0003).

The Architecture kind draws from industry standards for architecture description, including ISO/IEC/IEEE 42010 and established templates like arc42, adapted for platform engineering documentation needs.

---

## Scope Boundaries

| Aspect | In Scope | Out of Scope |
|--------|----------|--------------|
| Content | System design, invariants, trust boundaries | Implementation code, configurations |
| Focus | What and why | How |
| Audience | Architects, senior engineers, decision-makers | Implementers (see Specification RFCs) |
| Abstraction | Conceptual, technology-agnostic where possible | Specific commands, scripts |

---

## Table of Contents

### Core Sections

| Section | File | Description |
|---------|------|-------------|
| 0. Index | [00-index.md](./00-index.md) | This file — metadata, abstract, navigation |
| 1. Scope | [01-scope.md](./01-scope.md) | Applicability and what Architecture RFCs cover |
| 2. Normative Requirements | [02-requirements.md](./02-requirements.md) | Rules for writing Architecture RFCs |
| 3. Structure Definition | [03-structure.md](./03-structure.md) | Required and optional sections |
| 4. Formatting Standards | [04-formatting.md](./04-formatting.md) | Style and presentation |
| 5. Validation Criteria | [05-validation.md](./05-validation.md) | How to verify compliance |
| 6. Examples | [06-examples.md](./06-examples.md) | Sample invariants, trust boundaries, rationale |

### Appendices

| Appendix | File | Description |
|----------|------|-------------|
| A. Glossary | [appendix-a-glossary.md](./appendix-a-glossary.md) | Term definitions |
| B. References | [appendix-b-references.md](./appendix-b-references.md) | Citations and version history |

---

## Reading Paths

### For Architecture RFC Authors

1. Start with [Scope](./01-scope.md) to understand what Architecture RFCs cover
2. Read [Normative Requirements](./02-requirements.md) for mandatory rules
3. Follow [Structure Definition](./03-structure.md) for section organization
4. Use [Examples](./06-examples.md) for practical guidance

### For RFC Reviewers

1. Use [Validation Criteria](./05-validation.md) as review checklist
2. Reference [Normative Requirements](./02-requirements.md) for compliance
3. Check [Structure Definition](./03-structure.md) for completeness

### For Quick Reference

- [Glossary](./appendix-a-glossary.md) for Architecture-specific terminology
- [Examples](./06-examples.md) for invariant and trust boundary samples

---

*End of Index — RFC-RFCSTD-0002*
