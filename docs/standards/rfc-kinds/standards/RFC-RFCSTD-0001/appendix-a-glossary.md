```
RFC-RFCSTD-0001                                                  Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Examples](./06-examples.md) | [Index](./00-index.md) | [Next →](./appendix-b-references.md)

---

## Term Definitions

### Kind

A classification of RFC that determines its structure and purpose. Valid kinds in this RFC system are:

| Kind | Purpose |
|------|---------|
| Standards | Meta-RFCs that define how to write RFCs |
| Architecture | Conceptual RFCs that describe system design |
| Specification | Implementation RFCs with prerequisites and validation |
| BCP | Operational guidelines and best practices |

### Meta-RFC

An RFC that defines how to write other RFCs. All Standards kind RFCs are meta-RFCs. The term "meta" indicates that these documents exist at a level above the domain documents they govern.

### Normative

Defining requirements that MUST be followed for conformance. A normative statement uses RFC 2119 keywords (MUST, SHOULD, MAY) and creates binding obligations.

Contrast with **informative**, which provides context without creating requirements.

### RFC 2119 Keywords

Standard keywords for expressing requirement levels in technical documents:

| Keyword | Meaning |
|---------|---------|
| MUST, REQUIRED, SHALL | Absolute requirement |
| MUST NOT, SHALL NOT | Absolute prohibition |
| SHOULD, RECOMMENDED | Strong recommendation |
| SHOULD NOT, NOT RECOMMENDED | Strong discouragement |
| MAY, OPTIONAL | Truly optional |

See [RFC2119] and [RFC8174] in References.

### Self-Referential

A document that follows the rules it defines. RFC-RFCSTD-0001 is self-referential because it follows the Standards kind structure it defines. Self-reference ensures:

- The RFC serves as its own example
- The structure is proven viable by the RFC's existence
- Inconsistencies are immediately visible

### Testable

A requirement is testable if it is possible to determine whether a document complies or does not comply with the requirement. Testable requirements are:

| Property | Description |
|----------|-------------|
| Observable | Compliance can be seen by examining the document |
| Binary | Either complies or does not comply |
| Objective | Different reviewers reach the same conclusion |

### Validation

The process of verifying that an RFC conforms to its governing standards. Validation includes:

| Type | Description |
|------|-------------|
| Structural | Required sections present, correct order |
| Content | Requirements testable, no working code |
| Cross-Reference | Links work, references valid |

---

## Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| BCP | Best Current Practice |
| RFC | Request for Comments |
| TOC | Table of Contents |

---

*End of Appendix A — RFC-RFCSTD-0001*
