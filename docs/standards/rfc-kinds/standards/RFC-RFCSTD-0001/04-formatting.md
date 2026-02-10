```
RFC-RFCSTD-0001                                                   Section 4
Category: Standards Track                           Formatting Standards
```

# 4. Formatting Standards

[← Structure](./03-structure.md) | [Index](./00-index.md) | [Next →](./05-validation.md)

---

## 4.1 Document Header

Each file in a Standards RFC MUST begin with:

```
```
RFC-RFCSTD-NNNN                                                   Section N
Category: Standards Track                               <Section Title>
```

# N. Section Title

[← Previous](./prev.md) | [Index](./00-index.md) | [Next →](./next.md)

---
```

The header block MUST:

| Requirement | Description |
|-------------|-------------|
| Use triple backticks | Creates monospace formatting |
| Include RFC ID | Left-aligned |
| Include section number | Right-aligned |
| Include Category | Left-aligned on second line |
| Include section title | Right-aligned on second line |

---

## 4.2 Metadata Table

Standards RFCs MUST include a metadata table with:

| Field | Requirement | Description |
|-------|-------------|-------------|
| RFC ID | REQUIRED | Unique identifier (RFC-RFCSTD-NNNN) |
| Title | REQUIRED | Full RFC title |
| Status | REQUIRED | Draft, Review, Accepted, Implemented, Superseded, Withdrawn |
| Category | REQUIRED | Standards Track, Informational, etc. |
| Kind | REQUIRED | Standards, Architecture, Specification, BCP |
| Version | REQUIRED | Semantic version (MAJOR.MINOR.PATCH) |
| Author | REQUIRED | Author or team name |
| Created | REQUIRED | ISO 8601 date (YYYY-MM-DD) |
| Last Updated | REQUIRED | ISO 8601 date (YYYY-MM-DD) |
| Supersedes | CONDITIONAL | If this RFC replaces another |
| Superseded By | CONDITIONAL | If this RFC has been replaced |

---

## 4.3 Table Usage

Tables SHOULD be used for:

| Use Case | Example |
|----------|---------|
| Requirement matrices | Section requirement levels |
| Section definitions | File names and purposes |
| Validation criteria | Criterion and verification method |
| Reference indexes | RFC ID and description |
| Comparison matrices | Option A vs Option B |

Tables MUST have:

| Requirement | Description |
|-------------|-------------|
| Headers | First row is always headers |
| Consistent alignment | Use `|---|` separators |
| Concise content | Tables are for structured data, not prose |

Tables SHOULD NOT be used for:

| Avoid | Use Instead |
|-------|-------------|
| Long prose | Paragraphs |
| Nested structures | Subsections |
| Code examples | Code blocks |

---

## 4.4 Heading Hierarchy

| Level | Markdown | Usage |
|-------|----------|-------|
| H1 | `#` | Document title only (once per file) |
| H2 | `##` | Major sections |
| H3 | `###` | Subsections |
| H4 | `####` | Sub-subsections (maximum depth) |

H5 and H6 headings SHOULD NOT be used. If needed, restructure content.

---

## 4.5 Navigation Links

Each file MUST include navigation links:

| Position | Format |
|----------|--------|
| After header | `[← Previous](./prev.md) | [Index](./00-index.md) | [Next →](./next.md)` |
| Before footer | Optional: repeat navigation |

The Index file uses:

```
[Index](./00-index.md) | [Next →](./01-scope.md)
```

---

## 4.6 Section Separators

Use horizontal rules (`---`) to separate:

| Usage | Placement |
|-------|-----------|
| After navigation links | Before content begins |
| Before section footer | After content ends |
| Between major subsections | When logical break needed |

---

## 4.7 Code Block Usage

Code blocks (triple backticks) SHOULD be used for:

| Use Case | Language Hint |
|----------|---------------|
| Format specifications | `markdown` or none |
| Mermaid diagrams | `mermaid` |
| File paths | none |
| Example structures | `markdown` or none |

Code blocks MUST NOT contain:

| Prohibited Content | Reason |
|--------------------|--------|
| Working code | Standards RFCs are meta-documents |
| Shell commands | Not implementation documents |
| Configuration files | Not implementation documents |

---

## 4.8 Footer Format

Each file MUST end with:

```markdown
---

*End of Section N — RFC-RFCSTD-NNNN*
```

---

*End of Section 4 — RFC-RFCSTD-0001*
