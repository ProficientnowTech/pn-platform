```
RFC-RFCSTD-0004                                                   Section 5
Category: Standards Track                            Validation Criteria
```

# 5. Validation Criteria

[← Formatting](./04-formatting.md) | [Index](./00-index.md) | [Next →](./06-examples.md)

---

## 5.1 Structural Validation

A BCP RFC is structurally valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| REQUIRED sections present | Check against Section 3.1 | All REQUIRED files/sections exist |
| Kind field correct | Check metadata | Kind = "BCP" |
| Applicability stated | Check Scope section | Applicability is defined |
| Version history present | Check References | Version history exists |

---

## 5.2 Content Validation

A BCP RFC is content-valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| Guidelines have rationale | Each guideline includes "Rationale" | All guidelines have rationale |
| Guidelines have applicability | Each guideline includes "Applicability" | All guidelines have applicability |
| Guidelines have exceptions | Each guideline includes "Exceptions" | All guidelines have exceptions |
| Procedures are repeatable | Review by unfamiliar person | Procedures can be followed |
| SHOULD preferred over MUST | Count keyword usage | SHOULD count > MUST count |

---

## 5.3 Practicality Validation

A BCP RFC is practical when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| Guidelines are actionable | Can someone act on them? | Clear actions defined |
| Procedures are testable | Can they be rehearsed? | Steps can be practiced |
| Exceptions are realistic | Do they match real scenarios? | Exceptions reflect actual use cases |
| Trade-offs are honest | Do they acknowledge downsides? | Both sides presented |

---

## 5.4 Validation Checklist

Use this checklist when reviewing a BCP RFC:

### Structural Checks

- [ ] Index/metadata section exists with Kind: BCP
- [ ] Scope section exists with applicability
- [ ] Guidelines section exists
- [ ] Procedures section exists (if operational tasks described)
- [ ] Glossary appendix exists
- [ ] References appendix exists with version history

### Content Checks

- [ ] Each guideline has Recommendation, Rationale, Applicability, Exceptions
- [ ] Each procedure has When to Use, Prerequisites, Steps, Verification, Recovery
- [ ] SHOULD is used more than MUST
- [ ] MUST is used only for safety/compliance requirements
- [ ] Exceptions are documented for each guideline

### Quality Checks

- [ ] An operator can follow the BCP without external guidance
- [ ] Trade-offs are honestly presented
- [ ] Exceptions cover realistic scenarios
- [ ] Related RFCs are referenced

---

## 5.5 Keyword Balance Test

Count RFC 2119 keywords in the BCP:

| Keyword | Expected Frequency |
|---------|-------------------|
| SHOULD | Highest |
| RECOMMENDED | High |
| MAY | Medium |
| MUST | Low (safety/compliance only) |
| MUST NOT | Low (safety/compliance only) |

If MUST appears more frequently than SHOULD, the BCP may be misclassified:

| If | Then Consider |
|----|---------------|
| Most statements are MUST | This may be a Specification RFC |
| Most statements are SHOULD | Correctly classified as BCP |
| Mix of MUST and SHOULD | Ensure MUST is for safety/compliance |

---

## 5.6 Actionability Test

For each guideline, ask:

| Question | Expected Answer |
|----------|-----------------|
| What action should be taken? | Clear action defined |
| When should this action be taken? | Applicability is clear |
| Why should this action be taken? | Rationale is provided |
| When might this NOT apply? | Exceptions are documented |

If any answer is unclear, the guideline needs improvement.

---

*End of Section 5 — RFC-RFCSTD-0004*
