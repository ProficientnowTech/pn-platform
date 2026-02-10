```
RFC-RFCSTD-0002                                                   Section 3
Category: Standards Track                            Structure Definition
```

# 3. Structure Definition

[← Requirements](./02-requirements.md) | [Index](./00-index.md) | [Next →](./04-formatting.md)

---

## 3.1 Required Sections for Architecture Kind

Architecture RFCs MUST be organized as multi-file directories with the following structure:

| Section | File | Requirement | Purpose |
|---------|------|-------------|---------|
| Index | 00-index.md | REQUIRED | Metadata, abstract, TOC, reading paths |
| Introduction | 01-introduction.md | REQUIRED | Background, current state, motivation |
| Requirements | 02-requirements.md | REQUIRED | Design goals, non-goals, invariants, success criteria |
| Architecture | 03-architecture.md | REQUIRED | System overview, authority domains, trust boundaries |
| Components | 04-components.md | REQUIRED | Building blocks, responsibilities, interfaces, failures |
| Domain Sections | 05-*.md through NN-*.md | CONDITIONAL | Domain-specific mechanics |
| Rationale | NN-rationale.md | REQUIRED | Rejected alternatives with invariant references |
| Evolution | NN-evolution.md | RECOMMENDED | Future considerations, extensibility |
| Glossary | appendix-a-glossary.md | REQUIRED | Terms, ADR index, diagram index |
| References | appendix-b-references.md | REQUIRED | Normative, informative, internal references |

---

## 3.2 Section Requirement Levels

| Level | Meaning | Omission Criteria |
|-------|---------|-------------------|
| REQUIRED | Section MUST be present | Cannot be omitted |
| CONDITIONAL | Section MUST be present if criteria met | May be omitted if criteria do not apply |
| RECOMMENDED | Section SHOULD be present | May be omitted with documented justification |

### 3.2.1 Domain Section Criteria (CONDITIONAL)

Domain sections (05-*.md through NN-*.md) are REQUIRED when:

| Criterion | Example |
|-----------|---------|
| Architecture spans multiple domains | IAM + Secrets + Networking |
| Domain has unique mechanics | Identity federation, secret rotation |
| Domain requires separate invariants | Domain-specific rules |

Domain sections MAY be omitted when:

| Criterion | Example |
|-----------|---------|
| Architecture is single-domain | Simple API gateway |
| All mechanics fit in Architecture section | Minimal complexity |

---

## 3.3 Section Content Requirements

### 3.3.1 Index Section (00-index.md)

The index MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| RFC Header | REQUIRED | Standard header block |
| Metadata Table | REQUIRED | All metadata fields including Kind: Architecture |
| Abstract | REQUIRED | 2-4 paragraph summary |
| Scope Boundaries | REQUIRED | In-scope and out-of-scope table |
| Table of Contents | REQUIRED | Links to all sections |
| Reading Paths | RECOMMENDED | Audience-specific navigation guides |

### 3.3.2 Introduction Section (01-introduction.md)

The introduction MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Background | REQUIRED | Context and history |
| Current State | REQUIRED | What exists today (if anything) |
| Motivation | REQUIRED | Why this architecture is needed |
| Scope Statement | REQUIRED | What this RFC covers |

### 3.3.3 Requirements Section (02-requirements.md)

The requirements section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Design Goals | REQUIRED | What the architecture aims to achieve |
| Non-Goals | REQUIRED | Explicit exclusions from scope |
| Invariants | REQUIRED | Numbered rules that MUST always hold |
| Success Criteria | RECOMMENDED | How to validate architecture success |

### 3.3.4 Architecture Section (03-architecture.md)

The architecture section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| System Overview | REQUIRED | High-level description of the system |
| Authority Domains | CONDITIONAL | Who controls what (if multiple authorities) |
| Trust Boundaries | CONDITIONAL | Where security context changes (if security-relevant) |
| Data Flow | RECOMMENDED | How data moves through the system |

### 3.3.5 Components Section (04-components.md)

The components section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Component List | REQUIRED | All major building blocks |
| Responsibilities | REQUIRED | What each component does |
| Interfaces | RECOMMENDED | Inbound and outbound interfaces |
| Failure Modes | RECOMMENDED | How components fail and recover |

### 3.3.6 Rationale Section (NN-rationale.md)

The rationale section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Alternatives | REQUIRED | At least one alternative considered |
| Why Rejected | REQUIRED | Specific reasons for rejection |
| Invariant Violations | RECOMMENDED | Which invariants the alternative would violate |
| Conclusion | REQUIRED | Summary judgment |

### 3.3.7 Evolution Section (NN-evolution.md)

The evolution section SHOULD include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Future Considerations | RECOMMENDED | Known future needs |
| Extension Points | RECOMMENDED | How architecture can be extended |
| Deprecation Paths | OPTIONAL | How to phase out components |

### 3.3.8 Glossary (appendix-a-glossary.md)

The glossary MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Term Definitions | REQUIRED | All architecture-specific terms |
| Diagram Index | REQUIRED | List of all diagrams with locations |
| ADR Index | OPTIONAL | Architecture Decision Records if maintained separately |

### 3.3.9 References (appendix-b-references.md)

The references section MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Normative References | REQUIRED | Standards that MUST be followed |
| Informative References | RECOMMENDED | Background and context |
| Internal References | REQUIRED | Related internal RFCs |
| Version History | REQUIRED | Change log for this RFC |

---

## 3.4 File Naming Convention

| Pattern | Usage |
|---------|-------|
| `00-index.md` | Always the index file |
| `01-introduction.md` | Introduction section |
| `02-requirements.md` | Requirements section |
| `03-architecture.md` | Architecture section |
| `04-components.md` | Components section |
| `05-<domain>.md` through `NN-<domain>.md` | Domain-specific sections |
| `NN-rationale.md` | Rationale (number based on domain sections) |
| `NN-evolution.md` | Evolution (after rationale) |
| `appendix-<letter>-<name>.md` | Appendices |

---

*End of Section 3 — RFC-RFCSTD-0002*
