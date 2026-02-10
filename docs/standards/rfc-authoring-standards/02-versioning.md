```
RFC Authoring Standards                                           Section 2
Category: Standards Track                                       Versioning
```

# 2. Versioning and Change History

[← Identity](./01-identity.md) | [Index](./00-index.md) | [Next →](./03-structure.md)

---

## 2.1 Version Format

RFCs use Semantic Versioning adapted for documents:

```
MAJOR.MINOR.PATCH
```

| Component | Increment When |
|-----------|----------------|
| MAJOR | Breaking changes to invariants, structure, or normative requirements |
| MINOR | New sections, non-breaking additions, clarifications |
| PATCH | Typo fixes, formatting, minor corrections |

---

## 2.2 RFC Metadata

Each RFC MUST include version information in its metadata table:

| Field | Description | Required |
|-------|-------------|----------|
| Version | Current semantic version (e.g., 1.0.0) | REQUIRED |
| Last Updated | Date of last modification | REQUIRED |
| Previous Version | Prior version number (if applicable) | CONDITIONAL |
| Supersedes | RFC ID and version this RFC replaces | CONDITIONAL |
| Superseded By | RFC ID and version that replaces this RFC | CONDITIONAL |

---

## 2.3 Version History

Every RFC MUST include a Version History section in appendix-b-references.md:

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | YYYY-MM-DD | Author | Initial release |
| 1.1.0 | YYYY-MM-DD | Author | Added Section X |
| 1.1.1 | YYYY-MM-DD | Author | Fixed typo in Section Y |

---

## 2.4 Change Tracking

Changes are tracked at two levels:

### Git History (Source of Truth)

- All RFCs are stored in Git
- Each change is a commit with descriptive message
- Tags mark releases: `rfc-<ID>-v<VERSION>` (e.g., `rfc-iam-0001-v1.0.0`)

### RFC Metadata (Human-Readable)

- Version number in metadata table
- Version history in appendix
- Last Updated date

---

## 2.5 Status Mutability

| Status | Mutable | Allowed Changes |
|--------|---------|-----------------|
| Draft | Yes | Any changes |
| Review | Yes | Changes based on feedback |
| Accepted | PATCH only | Typo fixes, clarifications |
| Implemented | PATCH only | Typo fixes, clarifications |
| Superseded | No | Frozen |
| Withdrawn | No | Frozen |

---

## 2.6 Supersession Process

When RFC-A supersedes RFC-B:

| Step | Action |
|------|--------|
| 1 | RFC-A metadata includes `Supersedes: RFC-B vX.Y.Z` |
| 2 | RFC-B metadata updated with `Status: Superseded` and `Superseded By: RFC-A vX.Y.Z` |
| 3 | RFC-B content is frozen (no further changes) |

---

## 2.7 Cross-RFC References

### Normative Reference (must be followed)

```markdown
This RFC implements [RFC-IAM-0001 v1.0.0](../iam/00-index.md).
Implementation MUST conform to RFC-IAM-0001 invariants.
```

### Informative Reference (for context)

```markdown
For background, see [RFC-IAM-0001](../iam/00-index.md).
```

### Version Pinning

| Rule | Description |
|------|-------------|
| Specification → Architecture | Specification RFCs MUST pin to specific Architecture RFC versions |
| Updates | Updates to Architecture RFC may require Specification RFC updates |

---

*End of Section 2 — RFC Authoring Standards*
