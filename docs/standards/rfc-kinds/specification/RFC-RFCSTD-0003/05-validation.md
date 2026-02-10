```
RFC-RFCSTD-0003                                                   Section 5
Category: Standards Track                            Validation Criteria
```

# 5. Validation Criteria

[← Formatting](./04-formatting.md) | [Index](./00-index.md) | [Next →](./06-examples.md)

---

## 5.1 Structural Validation

A Specification RFC is structurally valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All sections present | Check file list against Section 3.1 | All 7 sections + 2 appendices exist |
| Kind field correct | Check metadata | Kind = "Specification" |
| Architecture reference present | Check metadata/intro | Implements field present |
| Navigation links work | Test all links | All links resolve |

---

## 5.2 Content Validation

A Specification RFC is content-valid when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| Prerequisites complete | Check all categories | Required/Optional types present |
| Phases follow structure | Check each phase | Task/Test/Iterate/Rollback present |
| Resources tabular | Review resource section | No YAML/JSON code blocks |
| Validation deterministic | Review each criterion | All criteria are binary |
| Tests categorized | Check test section | At least one category defined |
| Risks documented | Check risk section | Likelihood/Impact/Mitigation present |
| No working code | Review all code blocks | No executable code |

---

## 5.3 Completeness Validation

A Specification RFC is complete when:

| Criterion | Verification Method | Pass Condition |
|-----------|---------------------|----------------|
| All prerequisites verifiable | Each has verification method | No unverifiable prerequisites |
| All phases testable | Each phase has test section | No untestable phases |
| All resources traceable | Each resource has purpose | No unexplained resources |
| All validations actionable | Each has method | No unmeasurable criteria |
| All risks mitigated | Each risk has mitigation | No unaddressed risks |

---

## 5.4 Validation Checklist

Use this checklist when reviewing a Specification RFC:

### Structural Checks

- [ ] 00-index.md exists with Implements field
- [ ] 01-prerequisites.md exists with categorized prerequisites
- [ ] 02-phases.md exists with task/test/iterate structure
- [ ] 03-resources.md exists with tabular definitions
- [ ] 04-validation.md exists with deterministic criteria
- [ ] 05-testing.md exists with test categories
- [ ] 06-risks.md exists with risks and mitigations
- [ ] appendix-a-glossary.md exists
- [ ] appendix-b-references.md exists with Architecture RFC reference

### Content Checks

- [ ] Architecture RFC is referenced
- [ ] All prerequisites have verification methods
- [ ] All phases have rollback procedures
- [ ] No YAML, JSON, or shell scripts in document
- [ ] All validation criteria are deterministic
- [ ] All risks have mitigations

### Quality Checks

- [ ] An implementer can follow phases without external guidance
- [ ] Validation criteria are unambiguous
- [ ] Resource tables are complete
- [ ] Risks reflect realistic scenarios

---

## 5.5 Determinism Test

For each validation criterion, apply this test:

| Question | Required Answer |
|----------|-----------------|
| Can this be verified by inspection or automated test? | Yes |
| Will two different validators get the same result? | Yes |
| Is there exactly one pass condition? | Yes |
| Does the method describe how to verify? | Yes |

**Good Example:**

| ID | Criterion | Method | Pass Condition |
|----|-----------|--------|----------------|
| V1 | Keycloak health | HTTP GET /health/ready | Returns 200 |

**Poor Example:**

| ID | Criterion | Method | Pass Condition |
|----|-----------|--------|----------------|
| V1 | System is healthy | Check system | System looks healthy |

"Looks healthy" is not deterministic.

---

## 5.6 Code-Free Verification

Review all code blocks in the Specification RFC:

| Permitted | Not Permitted |
|-----------|---------------|
| Mermaid diagrams | YAML/JSON content |
| Table examples | Shell commands |
| Format templates | Configuration files |
| Structural descriptions | Working code |

If a code block could be executed to produce a result, it MUST NOT be in the Specification RFC.

---

*End of Section 5 — RFC-RFCSTD-0003*
