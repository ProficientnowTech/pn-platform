```
RFC-RFCSTD-0002                                                   Section 2
Category: Standards Track                          Normative Requirements
```

# 2. Normative Requirements

[← Scope](./01-scope.md) | [Index](./00-index.md) | [Next →](./03-structure.md)

---

## 2.1 Invariant Specification Requirement

Architecture RFCs MUST define at least one architectural invariant.

Each invariant MUST:

| Requirement | Description | Verification |
|-------------|-------------|--------------|
| Be numbered | Format: Invariant N — Title | Check for numbered format |
| Use RFC 2119 keywords | MUST, MUST NOT, SHOULD, etc. | Search for keywords |
| Be falsifiable | Possible to determine if violated | Review for testability |
| Include rationale | Explain why invariant exists | Check for explanation |

---

## 2.2 Trust Boundary Requirement

Architecture RFCs SHOULD define trust boundaries when the architecture involves:

| Scenario | Trust Boundary Required |
|----------|------------------------|
| Multiple systems or components | SHOULD |
| Security-sensitive operations | MUST |
| Authorization decisions | MUST |
| Data flow between domains | SHOULD |

Trust boundaries SHOULD be illustrated using Mermaid diagrams.

---

## 2.3 Rationale Requirement

Architecture RFCs MUST include a Rationale section documenting:

| Component | Requirement |
|-----------|-------------|
| Alternatives considered | At least one alternative |
| Why alternatives were rejected | Specific reasons |
| Invariant violations | Which invariants each alternative violated (if applicable) |

---

## 2.4 Component Interface Requirement

Architecture RFCs SHOULD define component interfaces including:

| Interface Aspect | Description |
|------------------|-------------|
| Inbound interfaces | What the component receives |
| Outbound interfaces | What the component produces |
| Failure modes | How the component fails |
| Recovery expectations | How the component recovers |

---

## 2.5 Non-Implementation Requirement

Architecture RFCs MUST NOT contain:

| Prohibited | Permitted Alternative |
|------------|----------------------|
| Working code in any programming language | Pseudocode for conceptual illustration |
| Configuration files (YAML, JSON, TOML, etc.) | Structural descriptions |
| Shell commands or scripts | Capability descriptions |
| Database schemas with actual field values | Schema concepts without values |
| API endpoint implementations | API contracts (input/output only) |

Permitted in code blocks:

| Permitted | Purpose |
|-----------|---------|
| Mermaid diagrams | Visual representation |
| Format specifications (structure only) | Showing expected formats |
| Placeholder examples with obviously non-functional values | Illustrating concepts |

---

## 2.6 Multi-File Requirement

Architecture RFCs MUST be organized as multi-file directories.

Rationale: Architecture RFCs are inherently complex and benefit from:
- Clear section boundaries
- Focused reading paths
- Easier navigation
- Independent section review

---

## 2.7 Diagram Requirement

Architecture RFCs SHOULD include diagrams for:

| Concept | Diagram Type |
|---------|--------------|
| System overview | flowchart |
| Trust boundaries | flowchart with subgraphs |
| Data flows | sequenceDiagram |
| State transitions | stateDiagram-v2 |
| Component relationships | flowchart |

All diagrams MUST use Mermaid syntax.
All diagrams MUST be indexed in Appendix A.

---

*End of Section 2 — RFC-RFCSTD-0002*
