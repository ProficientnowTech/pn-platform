```
RFC-RFCSTD-0003                                                  Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Examples](./06-examples.md) | [Index](./00-index.md) | [Next →](./appendix-b-references.md)

---

## Term Definitions

### Specification RFC

An RFC of Kind: Specification that defines how to implement an architecture without containing code. Specification RFCs bridge Architecture RFCs (conceptual) and actual implementation.

### Prerequisite

Something that MUST or SHOULD exist before implementation can begin. Prerequisites are categorized as:

| Type | Meaning |
|------|---------|
| Required | Implementation fails without this |
| Optional | Implementation works but with reduced functionality |
| Conditional | Required only if specific feature is enabled |

### Phase

A sequential unit of implementation work. Each phase follows the structure:

```
Task → Test → Iterate
```

Phases are:

- Sequential (must complete in order)
- Checkpoint-based (verification before proceeding)
- Isolated (failure doesn't corrupt previous phases)
- Reversible (rollback procedure documented)

### Resource

Something created during implementation—typically a Kubernetes resource, configuration, or infrastructure component. Resources are documented in tables, not code.

### Validation Criterion

A deterministic, binary check that verifies implementation correctness. Criteria are:

| Property | Description |
|----------|-------------|
| Observable | Can be verified by inspection or test |
| Binary | Either passes or fails |
| Objective | Different validators reach same conclusion |

### Test Category

A classification of tests with defined purpose, scope, and acceptance criteria. Common categories:

| Category | Purpose |
|----------|---------|
| Smoke | Basic functionality verification |
| Integration | Component interaction verification |
| End-to-end | Full workflow verification |
| Failure | Graceful degradation verification |

### Risk

Something that can go wrong during or after implementation. Risks have:

| Attribute | Description |
|-----------|-------------|
| Likelihood | How likely (High/Medium/Low) |
| Impact | How severe (High/Medium/Low) |
| Mitigation | How to address |

### Caveat

A known limitation or constraint of the implementation. Caveats are not risks—they are expected behaviors that users should be aware of.

### Loophole

An edge case that the implementation may not fully address. Loopholes should document how they are addressed (or acknowledge if unaddressed).

### Deterministic

A validation is deterministic if it produces the same result regardless of who performs it or when. Deterministic validations:

- Have a single, unambiguous pass condition
- Use objective measurements
- Are reproducible

---

## Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| BCP | Best Current Practice |
| CRD | Custom Resource Definition |
| ESO | External Secrets Operator |
| RFC | Request for Comments |
| YAML | YAML Ain't Markup Language |

---

*End of Appendix A — RFC-RFCSTD-0003*
