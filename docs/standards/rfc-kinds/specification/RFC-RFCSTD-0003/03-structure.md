```
RFC-RFCSTD-0003                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

[← Requirements](./02-requirements.md) | [Index](./00-index.md) | [Next →](./04-formatting.md)

---

## 3.1 Required Sections for Specification Kind

| Section | File | Requirement | Purpose |
|---------|------|-------------|---------|
| Index | 00-index.md | REQUIRED | Metadata, abstract, architecture reference |
| Prerequisites | 01-prerequisites.md | REQUIRED | Required and optional dependencies |
| Phases | 02-phases.md | REQUIRED | Phased implementation (task → test → iterate) |
| Resources | 03-resources.md | REQUIRED | Resource tables (no YAML/JSON) |
| Validation | 04-validation.md | REQUIRED | Deterministic verification criteria |
| Testing | 05-testing.md | REQUIRED | Test categories and acceptance criteria |
| Risks | 06-risks.md | REQUIRED | Features, caveats, loopholes, risks, mitigations |
| Glossary | appendix-a-glossary.md | REQUIRED | Terms |
| References | appendix-b-references.md | REQUIRED | Architecture RFC references |

---

## 3.2 Section Requirement Levels

| Level | Meaning | Omission Criteria |
|-------|---------|-------------------|
| REQUIRED | Section MUST be present | Cannot be omitted |

All Specification RFC sections are REQUIRED because:

- Prerequisites: Implementers need to know dependencies
- Phases: Implementation must be structured
- Resources: Implementers need to know what to create
- Validation: Correctness must be verifiable
- Testing: Quality must be ensured
- Risks: Implementers must understand limitations

---

## 3.3 Section Content Requirements

### 3.3.1 Index Section (00-index.md)

The index MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| RFC Header | REQUIRED | Standard header block |
| Metadata Table | REQUIRED | All fields including `Kind: Specification` |
| Implements Field | REQUIRED | Reference to Architecture RFC |
| Abstract | REQUIRED | Implementation summary |
| Scope Boundaries | REQUIRED | What this spec covers and doesn't |
| Table of Contents | REQUIRED | Links to all sections |

### 3.3.2 Prerequisites Section (01-prerequisites.md)

The prerequisites section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Infrastructure Prerequisites | REQUIRED | Platform requirements |
| Access Prerequisites | REQUIRED | Credentials and permissions |
| Knowledge Prerequisites | RECOMMENDED | Required understanding |
| Tooling Prerequisites | RECOMMENDED | Required tools |

Each prerequisite MUST have:

| Attribute | Description |
|-----------|-------------|
| Name | What is needed |
| Type | Required or Optional |
| Version | Minimum version (if applicable) |
| Verification | How to check if met |

### 3.3.3 Phases Section (02-phases.md)

The phases section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Phase Overview | REQUIRED | Summary of all phases |
| Phase Definitions | REQUIRED | Detailed phase descriptions |
| Rollback Procedures | REQUIRED | How to undo each phase |

Each phase MUST have:

| Attribute | Description |
|-----------|-------------|
| Phase Number | Sequential identifier |
| Phase Name | Descriptive title |
| Tasks | What to do (not how—no commands) |
| Test | How to verify completion |
| Iterate | What to check before proceeding |
| Rollback | How to undo if needed |

### 3.3.4 Resources Section (03-resources.md)

The resources section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Resource Overview | REQUIRED | Summary of all resources |
| Resource Tables | REQUIRED | Detailed resource definitions |
| Dependency Graph | RECOMMENDED | Resource creation order |

Each resource MUST have:

| Attribute | Description |
|-----------|-------------|
| Name | Resource identifier |
| Type | Resource kind (ConfigMap, Secret, etc.) |
| Purpose | Why this resource exists |
| Dependencies | What must exist first |
| Validation | How to verify correct creation |

### 3.3.5 Validation Section (04-validation.md)

The validation section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Validation Overview | REQUIRED | What validation means for this spec |
| Validation Criteria | REQUIRED | Individual criteria |
| Validation Procedure | REQUIRED | How to perform validation |

Each criterion MUST have:

| Attribute | Description |
|-----------|-------------|
| Criterion ID | Unique identifier |
| Description | What is being validated |
| Method | How to validate |
| Pass Condition | What constitutes passing |

### 3.3.6 Testing Section (05-testing.md)

The testing section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Test Categories | REQUIRED | Types of tests |
| Acceptance Criteria | REQUIRED | What defines passing |
| Test Environment | RECOMMENDED | Where tests run |
| Test Data | RECOMMENDED | What data is needed |

Each test category MUST have:

| Attribute | Description |
|-----------|-------------|
| Category Name | Type of test |
| Purpose | What this category verifies |
| Scope | What is included/excluded |
| Acceptance | Pass/fail criteria |

### 3.3.7 Risks Section (06-risks.md)

The risks section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Features | REQUIRED | What the implementation provides |
| Caveats | REQUIRED | Known limitations |
| Loopholes | RECOMMENDED | Edge cases not covered |
| Risks | REQUIRED | What can go wrong |
| Mitigations | REQUIRED | How risks are addressed |

Each risk MUST have:

| Attribute | Description |
|-----------|-------------|
| Risk ID | Unique identifier |
| Description | What the risk is |
| Likelihood | How likely (High/Medium/Low) |
| Impact | How severe (High/Medium/Low) |
| Mitigation | How to address |

---

## 3.4 File Naming Convention

| Pattern | Usage |
|---------|-------|
| `00-index.md` | Index |
| `01-prerequisites.md` | Prerequisites |
| `02-phases.md` | Implementation phases |
| `03-resources.md` | Resource definitions |
| `04-validation.md` | Validation criteria |
| `05-testing.md` | Test requirements |
| `06-risks.md` | Risk documentation |
| `appendix-<letter>-<name>.md` | Appendices |

---

*End of Section 3 — RFC-RFCSTD-0003*
