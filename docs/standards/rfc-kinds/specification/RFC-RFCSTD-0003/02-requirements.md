```
RFC-RFCSTD-0003                                                   Section 2
Category: Standards Track                          Normative Requirements
```

# 2. Normative Requirements

[← Scope](./01-scope.md) | [Index](./00-index.md) | [Next →](./03-structure.md)

---

## 2.1 Architecture Reference Requirement

Specification RFCs MUST reference their governing Architecture RFC.

| Requirement | Format |
|-------------|--------|
| Reference in metadata | `Implements: RFC-<ARCH-ID> v<VERSION>` |
| Reference in introduction | Link to Architecture RFC |
| Invariant compliance | State which invariants this spec satisfies |

---

## 2.2 Prerequisites Requirement

Specification RFCs MUST document prerequisites in tabular form:

| Column | Requirement | Description |
|--------|-------------|-------------|
| Prerequisite | REQUIRED | What is needed |
| Type | REQUIRED | Required or Optional |
| Version | REQUIRED | Minimum version if applicable |
| Verification | REQUIRED | How to verify prerequisite is met |

Prerequisites MUST be categorized:

| Category | Examples |
|----------|----------|
| Infrastructure | Kubernetes cluster, network access |
| Access | Credentials, permissions, certificates |
| Knowledge | Documentation familiarity, training |
| Tooling | CLI tools, IDE plugins |

---

## 2.3 Phased Implementation Requirement

Specification RFCs MUST organize implementation into phases.

Each phase MUST follow the structure:

```
Phase N: <Phase Name>
├── Tasks (what to do)
├── Test (how to verify)
└── Iterate (what to check before proceeding)
```

Phase requirements:

| Requirement | Description |
|-------------|-------------|
| Sequential | Phases MUST be completed in order |
| Checkpoint | Each phase ends with verification |
| Isolation | Phase failure does not corrupt previous phases |
| Rollback | Each phase documents rollback procedure |

---

## 2.4 Resource Definition Requirement

Specification RFCs MUST define resources in tabular form.

| Column | Requirement | Description |
|--------|-------------|-------------|
| Resource | REQUIRED | What to create |
| Type | REQUIRED | Resource type (ConfigMap, Secret, Service, etc.) |
| Purpose | REQUIRED | Why this resource exists |
| Dependencies | CONDITIONAL | What must exist first (if any) |
| Validation | REQUIRED | How to verify correct creation |

Resource definitions MUST NOT contain:

| Prohibited | Permitted Alternative |
|------------|----------------------|
| YAML/JSON content | Table describing structure |
| Actual values | Placeholder descriptions |
| Implementation code | Conceptual descriptions |

---

## 2.5 Validation Criteria Requirement

Specification RFCs MUST define deterministic validation criteria.

Each criterion MUST:

| Requirement | Description |
|-------------|-------------|
| Be observable | Can be verified by inspection or test |
| Be binary | Either passes or fails (no partial pass) |
| Be objective | Different validators reach same conclusion |
| Include method | How to perform the validation |

---

## 2.6 Test Requirements Requirement

Specification RFCs MUST define test requirements.

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Test Categories | REQUIRED | Types of tests (unit, integration, e2e) |
| Acceptance Criteria | REQUIRED | What defines passing |
| Test Environment | RECOMMENDED | Where tests run |
| Test Data | RECOMMENDED | What data is needed |

---

## 2.7 Risk Documentation Requirement

Specification RFCs MUST document risks.

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Features | REQUIRED | What the implementation provides |
| Caveats | REQUIRED | Known limitations or constraints |
| Loopholes | RECOMMENDED | Edge cases that may not be covered |
| Risks | REQUIRED | What can go wrong |
| Mitigations | REQUIRED | How risks are addressed |

---

## 2.8 Non-Code Requirement

Specification RFCs MUST NOT contain working code.

| Permitted | Not Permitted |
|-----------|---------------|
| Structural descriptions | YAML/JSON content |
| Table-based resource definitions | Configuration files |
| Conceptual pseudocode | Shell scripts |
| Mermaid diagrams | API implementations |

---

*End of Section 2 — RFC-RFCSTD-0003*
