```
RFC Authoring Standards                                          Section 10
Category: Standards Track                        Review and Maintenance
```

# 10. Review and Maintenance

[← Glossary](./09-glossary-refs.md) | [Index](./00-index.md) | [Next →](./appendix-a-glossary.md)

---

## 10.1 Review Checklist

Before submitting for review, verify:

### Structure

- [ ] RFC identifier is unique and properly formatted
- [ ] All required sections are present for the RFC kind
- [ ] Navigation links are correct
- [ ] Multi-file structure follows naming conventions

### Content

- [ ] No implementation code or timelines included
- [ ] All invariants are numbered and use RFC 2119 keywords
- [ ] All assumptions are explicitly stated
- [ ] Rationale section documents all considered alternatives
- [ ] Content is original (not copied from other RFCs)

### Glossary and References

- [ ] Glossary defines all domain-specific terms
- [ ] All diagrams are indexed
- [ ] References are properly formatted
- [ ] Version history is included

---

## 10.2 Reviewer Responsibilities

Reviewers SHOULD verify:

| Aspect | What to Check |
|--------|---------------|
| Technical accuracy | Are statements correct? |
| Completeness | Are all required sections present? |
| Invariants | Are invariants falsifiable and well-reasoned? |
| Rationale | Are alternatives adequately documented? |
| Clarity | Is the RFC clear and unambiguous? |
| Standards | Does it adhere to these standards? |

---

## 10.3 RFC Updates

When updating an RFC:

| Step | Action |
|------|--------|
| 1 | Increment the version number appropriately |
| 2 | Update the "Last Updated" date |
| 3 | Document changes in version history |
| 4 | Maintain backward compatibility where possible |

---

## 10.4 RFC Supersession

When an RFC is superseded:

| Step | Action |
|------|--------|
| 1 | Change status to "Superseded" |
| 2 | Add "Superseded By" field to metadata |
| 3 | Reference the superseding RFC |
| 4 | Do not delete the original |
| 5 | Freeze content (no further changes) |

---

## 10.5 Deprecation Notice

When deprecating portions of an RFC:

```markdown
> **DEPRECATED**: This section is deprecated as of v2.0.0.
> See [RFC-NEW-0001](./path) for the replacement approach.
```

---

*End of Section 10 — RFC Authoring Standards*
