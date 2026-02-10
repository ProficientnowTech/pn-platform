```
RFC-RFCSTD-0001                                                   Section 5
Category: Standards Track                            Validation Criteria
```

# 5. Validation Criteria

[← Formatting](./04-formatting.md) | [Index](./00-index.md) | [Next →](./06-examples.md)

---

## 5.1 Structural Validation

A Standards RFC is structurally valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All REQUIRED sections present | Check file list against Section 3.1 | All REQUIRED files exist |
| Sections in correct order | Compare file numbering | Files numbered 00-NN sequentially |
| Metadata complete | Check metadata table | All REQUIRED fields present |
| Kind field correct | Check metadata Kind value | Kind = "Standards" |
| Navigation links present | Check each file | All files have nav links |
| Footers present | Check each file | All files end with footer |

---

## 5.2 Content Validation

A Standards RFC is content-valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| RFC 2119 keywords capitalized | Search for lowercase must/should/may in normative context | No lowercase keywords found |
| No implementation code | Review code blocks | No working code present |
| All requirements testable | For each requirement, can compliance be determined? | All requirements are testable |
| Glossary complete | Cross-reference terms used with glossary | All terms defined |
| Section content matches purpose | Review each section | Content aligns with Section 3.4 requirements |

---

## 5.3 Cross-Reference Validation

A Standards RFC is cross-reference valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All internal links resolve | Test each `[text](link)` | All links work |
| All external references exist | Verify URLs | All URLs accessible |
| Version references specific | Check RFC references | Versions included where required |
| No broken anchors | Test section links | All anchors resolve |

---

## 5.4 Validation Checklist

Use this checklist when reviewing a Standards RFC:

### Structural Checks

- [ ] 00-index.md exists and contains metadata
- [ ] All REQUIRED sections have corresponding files
- [ ] File numbering is sequential (00, 01, 02...)
- [ ] Appendices use correct naming (appendix-a-, appendix-b-)
- [ ] All files have navigation links
- [ ] All files have proper headers and footers

### Content Checks

- [ ] Abstract clearly describes RFC purpose
- [ ] Scope boundaries are defined
- [ ] All normative requirements use RFC 2119 keywords
- [ ] All requirements are testable
- [ ] No working code in code blocks
- [ ] Examples are clearly marked as examples
- [ ] Glossary defines all RFC-specific terms

### Reference Checks

- [ ] All internal links work
- [ ] All external URLs are accessible
- [ ] Normative references include versions
- [ ] Version history is present and current

---

## 5.5 Automated Validation

The following aspects can be validated automatically:

| Check | Method |
|-------|--------|
| File existence | `ls` for required files |
| Link validity | Markdown link checker |
| Keyword capitalization | Regex search for RFC 2119 keywords |
| Header format | Regex pattern matching |
| Metadata completeness | Parse metadata table |

The following aspects require manual review:

| Check | Reason |
|-------|--------|
| Requirement testability | Requires understanding of intent |
| Content appropriateness | Requires domain knowledge |
| Glossary completeness | Requires reading full document |
| Example correctness | Requires understanding of context |

---

*End of Section 5 — RFC-RFCSTD-0001*
