```
RFC-RFCSTD-0001                                                   Section 6
Category: Standards Track                                         Examples
```

# 6. Examples

[← Validation](./05-validation.md) | [Index](./00-index.md) | [Next →](./appendix-a-glossary.md)

---

## 6.1 Requirement Level Specification Example

When defining sections for a new RFC kind, specify requirement levels as follows:

**Well-Formed Section Definition:**

| Section | Requirement | Purpose | Content Requirements |
|---------|-------------|---------|----------------------|
| Introduction | REQUIRED | Establish problem context | Background, motivation, current state |
| Requirements | REQUIRED | Define invariants and constraints | Numbered requirements with RFC 2119 keywords |
| Implementation | OPTIONAL | Additional implementation notes | Only if needed for clarity |

This example demonstrates:
- Clear requirement level for each section
- Purpose description
- Content guidance

---

## 6.2 Testable Requirement Example

**Testable Requirement (correct):**

> The RFC MUST include at least three invariants.

| Aspect | Value |
|--------|-------|
| Observable | Yes - can count invariants |
| Binary | Yes - either ≥3 or <3 |
| Objective | Yes - anyone can count |

Verification: Count invariants. Pass if count ≥ 3.

**Non-Testable Requirement (incorrect):**

> The RFC should be well-written.

| Aspect | Value |
|--------|-------|
| Observable | Partially - subjective |
| Binary | No - degrees of "well-written" |
| Objective | No - reviewers may disagree |

This cannot be objectively verified. Avoid such requirements.

---

## 6.3 Metadata Table Example

**Complete Metadata Table:**

| Field | Value |
|-------|-------|
| RFC ID | RFC-RFCSTD-0005 |
| Title | RFC Kind: Tutorial |
| Status | Draft |
| Category | Standards Track |
| Kind | Standards |
| Version | 1.0.0 |
| Author | Platform Engineering |
| Created | 2026-03-15 |
| Last Updated | 2026-03-15 |

**Incomplete Metadata Table (incorrect):**

| Field | Value |
|-------|-------|
| RFC ID | RFC-RFCSTD-0005 |
| Title | RFC Kind: Tutorial |

Missing: Status, Category, Kind, Version, Author, Created, Last Updated.

---

## 6.4 Section Header Example

**Correct Header:**

```
```
RFC-RFCSTD-0005                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

[← Requirements](./02-requirements.md) | [Index](./00-index.md) | [Next →](./04-formatting.md)

---
```

**Incorrect Header (missing navigation):**

```
```
RFC-RFCSTD-0005                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

---
```

Missing navigation links make it difficult to navigate the document.

---

## 6.5 Glossary Entry Example

**Well-Formed Entry:**

**Invariant**
A rule that MUST always hold true in the architecture. Violation represents a system failure. Invariants are numbered for reference and use RFC 2119 keywords.

**Poorly-Formed Entry (avoid):**

**Invariant** - a rule

Too brief; does not provide sufficient context for understanding.

---

## 6.6 Reference Entry Example

**Normative Reference (must follow):**

**[RFC2119]** Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.
<https://datatracker.ietf.org/doc/html/rfc2119>

**Informative Reference (for context):**

**[arc42]** Starke, G., Hruschka, P., "arc42 Template", arc42.org.
<https://arc42.org/overview>

---

## 6.7 Version History Example

**Well-Maintained Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-10 | Platform Engineering | Initial release |
| 1.1.0 | 2026-03-15 | Platform Engineering | Added Section 6.7 for new examples |
| 1.1.1 | 2026-03-20 | Platform Engineering | Fixed typo in Section 2.3 |

Demonstrates:
- Semantic versioning (MAJOR.MINOR.PATCH)
- Clear change descriptions
- Chronological order

---

*End of Section 6 — RFC-RFCSTD-0001*
