```
RFC-RFCSTD-0002                                                   Section 5
Category: Standards Track                            Validation Criteria
```

# 5. Validation Criteria

[← Formatting](./04-formatting.md) | [Index](./00-index.md) | [Next →](./06-examples.md)

---

## 5.1 Structural Validation

An Architecture RFC is structurally valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All REQUIRED sections present | Check against Section 3.1 | All REQUIRED files exist |
| Multi-file structure used | Verify separate .md files | Directory with multiple files |
| Navigation links functional | Test all internal links | All links resolve |
| Metadata complete | All fields in metadata table | All REQUIRED fields present |
| Kind field correct | Check metadata Kind value | Kind = "Architecture" |

---

## 5.2 Content Validation

An Architecture RFC is content-valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| At least one invariant defined | Count invariants | Count ≥ 1 |
| Invariants numbered sequentially | Check Invariant N format | Sequential numbering |
| Invariants use RFC 2119 keywords | Search for MUST/SHOULD/MAY | Keywords present |
| Invariants are falsifiable | For each, can violation be detected? | All falsifiable |
| No implementation code | Review all code blocks | No working code |
| Rationale documents alternatives | Check for rejected alternatives | At least one alternative |

---

## 5.3 Completeness Validation

An Architecture RFC is complete when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All domain sections present | Domain-specific review | Relevant domains covered |
| All components documented | Cross-reference architecture diagram | All diagram components documented |
| Trust boundaries identified | Security review | Boundaries defined if security-relevant |
| Glossary defines all terms | Cross-reference term usage | All terms defined |
| All diagrams indexed | Check Appendix A | Diagram index complete |

---

## 5.4 Validation Checklist

Use this checklist when reviewing an Architecture RFC:

### Structural Checks

- [ ] 00-index.md exists with complete metadata
- [ ] 01-introduction.md exists with background and motivation
- [ ] 02-requirements.md exists with invariants
- [ ] 03-architecture.md exists with system overview
- [ ] 04-components.md exists with component list
- [ ] Rationale section exists with rejected alternatives
- [ ] Glossary appendix exists with term definitions
- [ ] References appendix exists with citations

### Content Checks

- [ ] At least one invariant is defined
- [ ] Invariants are numbered (Invariant 1, 2, 3...)
- [ ] Invariants use RFC 2119 keywords (MUST, SHOULD, MAY)
- [ ] Each invariant is falsifiable
- [ ] No working code in any section
- [ ] At least one rejected alternative documented
- [ ] Rejected alternatives explain why rejected

### Diagram Checks

- [ ] System overview diagram present (RECOMMENDED)
- [ ] All diagrams use Mermaid syntax
- [ ] Diagrams are indexed in glossary
- [ ] Trust boundaries shown if security-relevant

### Reference Checks

- [ ] All internal links work
- [ ] External URLs are accessible
- [ ] Architecture RFC version is in references if citing another

---

## 5.5 Falsifiability Test

For each invariant, apply this test:

| Question | Expected Answer |
|----------|-----------------|
| Can this invariant be violated? | Yes |
| Would violation be observable? | Yes |
| Can an automated check detect violation? | Ideally yes |
| Is the invariant binary (holds or doesn't)? | Yes |

If any answer is "No", the invariant needs refinement.

**Good Example:**
> HashiCorp Vault MUST be the sole authoritative source for secrets.

Falsifiable: Yes—find a secret stored elsewhere, invariant is violated.

**Poor Example:**
> The system should be secure.

Not falsifiable: "Secure" is subjective and cannot be definitively verified.

---

*End of Section 5 — RFC-RFCSTD-0002*
