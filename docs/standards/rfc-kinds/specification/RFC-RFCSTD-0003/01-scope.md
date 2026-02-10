```
RFC-RFCSTD-0003                                                   Section 1
Category: Standards Track                                             Scope
```

# 1. Scope

[← Index](./00-index.md) | [Index](./00-index.md) | [Next →](./02-requirements.md)

---

## 1.1 Purpose

Specification RFCs define how to implement an architecture. They establish:

| Aspect | Description |
|--------|-------------|
| Prerequisites | Required and optional dependencies before implementation |
| Phased Implementation | Checkpoint-focused plans (task → test → iterate) |
| Resource Definitions | What must be created, in tabular form |
| Validation Criteria | Deterministic verification requirements |
| Test Requirements | Categories of tests and acceptance criteria |
| Risk Documentation | Features, caveats, loopholes, and mitigations |

Specification RFCs answer "How do I implement this architecture?" without providing code.

---

## 1.2 Applicability

This RFC applies to all Specification kind RFCs, including but not limited to:

| Example RFC | Domain |
|-------------|--------|
| RFC-SPEC-IAM-0001 | IAM Implementation Specification |
| RFC-SPEC-SECRETS-0001 | Secret Management Implementation |
| RFC-SPEC-DEPLOY-0001 | Deployment Pipeline Implementation |

Any RFC with `Kind: Specification` in its metadata MUST follow this standard.

---

## 1.3 What Specification RFCs MUST NOT Include

Specification RFCs MUST NOT include:

| Prohibited Content | Reason | Belongs In |
|--------------------|--------|------------|
| Working code | Specifications define requirements, not code | Implementation repository |
| Configuration files (YAML, JSON, etc.) | Specifications describe, not configure | Helm charts, Terraform |
| Shell commands or scripts | Specifications guide, not execute | Runbooks, automation |
| Passwords, API keys, tokens | Security risk | Vault, sealed secrets |

---

## 1.4 What Specification RFCs MUST Include

Specification RFCs MUST include sufficient detail for:

| Requirement | Purpose |
|-------------|---------|
| Unambiguous implementation | Any implementer reaches same result |
| Deterministic validation | Any validator can verify correctness |
| Reproducible testing | Tests can be run independently |
| Risk awareness | Implementers understand edge cases |

---

## 1.5 Relationship to Architecture RFCs

Specification RFCs implement Architecture RFCs:

```
Architecture RFC                    Specification RFC
───────────────                    ─────────────────
• What the system does             • How to build it
• Why design decisions made        • Prerequisites needed
• Trust boundaries                 • Phased implementation
• Invariants                       • Validation criteria
                    │
                    ▼
            Specification RFC
            MUST reference
            Architecture RFC
```

Every Specification RFC MUST reference its governing Architecture RFC.

---

## 1.6 Relationship to BCP RFCs

Specification RFCs define implementation. BCP RFCs define ongoing operation:

| Specification RFC | BCP RFC |
|-------------------|---------|
| How to deploy the system | How to operate the system |
| Initial configuration | Ongoing maintenance |
| Setup validation | Operational monitoring |

---

## 1.7 Conformance

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174].

---

*End of Section 1 — RFC-RFCSTD-0003*
