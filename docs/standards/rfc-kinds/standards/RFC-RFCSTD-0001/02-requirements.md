```
RFC-RFCSTD-0001                                                   Section 2
Category: Standards Track                          Normative Requirements
```

# 2. Normative Requirements

[← Scope](./01-scope.md) | [Index](./00-index.md) | [Next →](./03-structure.md)

---

## 2.1 Self-Reference Requirement

Standards RFCs that define RFC kinds MUST follow the structure they define.

RFC-RFCSTD-0001 demonstrates this by following the Standards kind structure it defines. This self-referential property ensures that:

- Authors can use the RFC itself as an example
- The RFC proves its own structure is viable
- Inconsistencies between rules and practice are immediately visible

---

## 2.2 Completeness Requirement

Standards RFCs MUST specify for each section they define:

| Attribute | Description | Verification |
|-----------|-------------|--------------|
| Requirement Level | REQUIRED, RECOMMENDED, or OPTIONAL | Check presence of level |
| Purpose | What the section achieves | Review for clarity |
| Content Requirements | What MUST, SHOULD, or MAY be included | Check for specificity |
| Validation Method | How compliance is verified | Review for testability |

---

## 2.3 Testability Requirement

All normative requirements in Standards RFCs MUST be testable.

A requirement is testable when:

| Criterion | Description |
|-----------|-------------|
| Observable | Compliance can be determined by examining the document |
| Binary | The document either complies or does not comply |
| Objective | Different reviewers reach the same conclusion |

**Example of testable requirement:**
> The RFC MUST include at least one invariant.

Verification: Count invariants. Pass if count ≥ 1.

**Example of non-testable requirement (avoid):**
> The RFC should be well-written.

This cannot be objectively verified.

---

## 2.4 Non-Code Requirement

Standards RFCs MUST NOT contain implementation code, configuration files, or shell commands.

| Permitted in Code Blocks | Not Permitted |
|--------------------------|---------------|
| Format specifications (structure only) | Working code |
| Diagram syntax (Mermaid) | Configuration files (YAML, JSON, etc.) |
| File path examples | Shell commands or scripts |
| Placeholder examples with obvious non-functional values | Database schemas with actual values |

---

## 2.5 RFC 2119 Keyword Requirement

All normative statements MUST use RFC 2119 keywords in ALL CAPITALS.

| Keyword | Usage |
|---------|-------|
| MUST, REQUIRED, SHALL | Absolute requirement |
| MUST NOT, SHALL NOT | Absolute prohibition |
| SHOULD, RECOMMENDED | Strong recommendation with exceptions |
| SHOULD NOT, NOT RECOMMENDED | Strong discouragement with exceptions |
| MAY, OPTIONAL | Truly optional |

---

## 2.6 Multi-File Requirement

Standards RFCs SHOULD use multi-file structure when:

| Condition | Rationale |
|-----------|-----------|
| RFC exceeds 300 lines | Improves navigability |
| RFC has distinct, independent sections | Enables focused reading |
| RFC serves as template for other RFCs | Demonstrates expected structure |

Standards RFCs MAY use single-file structure when:

| Condition | Rationale |
|-----------|-----------|
| RFC is under 300 lines | Single file is more convenient |
| All sections are closely related | Splitting would reduce coherence |

---

*End of Section 2 — RFC-RFCSTD-0001*
