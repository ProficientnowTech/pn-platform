```
RFC Authoring Standards                                          Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Review](./10-review.md) | [Index](./00-index.md) | [Next →](./appendix-b-references.md)

---

## Term Definitions

### Architecture RFC

An RFC of Kind: Architecture that describes system design conceptually without implementation details. Architecture RFCs focus on what a system does and why, not how it is implemented.

### BCP (Best Current Practice)

An RFC of Kind: BCP that documents operational guidelines and recommended practices. BCPs use SHOULD/RECOMMENDED rather than MUST, acknowledging that practices may need adaptation.

### Category

A classification of RFC purpose: Standards Track (intended for implementation), Informational (documentation), or Experimental (evaluation proposals).

### Falsifiable

A property of invariants meaning it is possible to determine when the invariant has been violated. Non-falsifiable invariants cannot be validated.

### Invariant

A rule that MUST always hold true in the architecture. Invariants are numbered, use RFC 2119 keywords, and are falsifiable.

### Kind

A classification of RFC that determines its structure and purpose. Valid kinds: Standards, Architecture, Specification, BCP.

### Normative

Defining requirements that MUST be followed for conformance. Normative statements use RFC 2119 keywords.

### RFC (Request for Comments)

A document proposing, documenting, and preserving architectural decisions for platform systems.

### RFC 2119 Keywords

Standard keywords (MUST, SHOULD, MAY, etc.) for expressing requirement levels in technical documents.

### Specification RFC

An RFC of Kind: Specification that defines how to implement an architecture without containing code. Includes prerequisites, phases, resources, validation, testing, and risks.

### Standards RFC

An RFC of Kind: Standards that defines how to write other RFCs. Standards RFCs are self-referential—they follow the rules they define.

### Superseded

An RFC status indicating the RFC has been replaced by a newer RFC. Superseded RFCs are frozen (no further changes).

---

## Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| ADR | Architecture Decision Record |
| BCP | Best Current Practice |
| RFC | Request for Comments |
| TOC | Table of Contents |

---

*End of Appendix A — RFC Authoring Standards*
