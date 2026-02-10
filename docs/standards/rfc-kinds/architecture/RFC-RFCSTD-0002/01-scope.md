```
RFC-RFCSTD-0002                                                   Section 1
Category: Standards Track                                             Scope
```

# 1. Scope

[← Index](./00-index.md) | [Index](./00-index.md) | [Next →](./02-requirements.md)

---

## 1.1 Purpose

Architecture RFCs define system architecture conceptually. They establish:

| Aspect | Description |
|--------|-------------|
| System Behavior | What the system does and its observable properties |
| Trust Boundaries | Where security context changes and validation must occur |
| Invariants | Rules that MUST always hold true |
| Component Responsibilities | What each building block is responsible for |
| Design Rationale | Why design decisions were made and alternatives rejected |

Architecture RFCs answer "What does this system do?" and "Why was it designed this way?"—not "How do I implement it?"

---

## 1.2 Applicability

This RFC applies to all Architecture kind RFCs, including but not limited to:

| Example RFC | Domain |
|-------------|--------|
| RFC-IAM-0001 | Identity and Access Management Architecture |
| RFC-SECOPS-0001 | Secret Operations Architecture |
| RFC-DEPLOY-0001 | Deployment Operations Architecture |

Any RFC with `Kind: Architecture` in its metadata MUST follow this standard.

---

## 1.3 What Architecture RFCs MUST NOT Include

Architecture RFCs MUST NOT include:

| Prohibited Content | Reason | Belongs In |
|--------------------|--------|------------|
| Implementation code | Architecture describes behavior, not code | Specification RFC or implementation repo |
| Configuration values | Architecture defines structure, not values | Specification RFC or Helm values |
| Shell commands | Architecture is declarative, not procedural | Specification RFC or runbooks |
| Step-by-step procedures | Architecture describes what, not how | Specification RFC or BCP |

---

## 1.4 Relationship to Specification RFCs

Architecture RFCs define WHAT a system does. Specification RFCs (RFC-RFCSTD-0003) define HOW to implement that architecture:

```
Architecture RFC                    Specification RFC
───────────────                    ─────────────────
• Trust boundaries                 • Prerequisites
• Invariants                       • Resource tables
• Component interfaces             • Validation criteria
• Design rationale                 • Test requirements
                    │
                    ▼
            Specification RFC
            SHOULD reference
            Architecture RFC
```

---

## 1.5 Relationship to BCP RFCs

Architecture RFCs define system design. BCP RFCs (RFC-RFCSTD-0004) define operational practices:

| Architecture RFC | BCP RFC |
|------------------|---------|
| Describes secret management architecture | Describes secret rotation procedures |
| Defines authentication flow | Defines access review practices |
| Establishes monitoring requirements | Provides incident response guidelines |

---

## 1.6 Conformance

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174].

---

*End of Section 1 — RFC-RFCSTD-0002*
