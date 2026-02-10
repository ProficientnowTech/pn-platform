```
RFC-RFCSTD-0002                                                  Appendix A
Category: Standards Track                                         Glossary
```

# Appendix A: Glossary

[← Examples](./06-examples.md) | [Index](./00-index.md) | [Next →](./appendix-b-references.md)

---

## Term Definitions

### Architecture RFC

An RFC of Kind: Architecture that describes system design conceptually without implementation details. Architecture RFCs focus on what a system does and why, not how it is implemented.

### Authority Domain

A bounded context within which a specific system or component holds decision-making authority. In a multi-system architecture, different authority domains may govern different aspects:

| Example Domain | Authority |
|----------------|-----------|
| Enterprise Identity | Azure AD |
| Platform Identity | Keycloak |
| Secret Management | HashiCorp Vault |

### Falsifiable

An invariant is falsifiable if it is possible to determine when it has been violated. A non-falsifiable invariant is not useful because compliance cannot be verified.

| Falsifiable | Example |
|-------------|---------|
| Yes | "Vault MUST be the sole secret source" |
| No | "The system should be reliable" |

### Invariant

A rule that MUST always hold true in the architecture. Violation represents a system failure or design violation. Invariants are:

- Numbered for reference (Invariant 1, 2, 3...)
- Expressed using RFC 2119 keywords
- Falsifiable (can detect violation)
- Accompanied by rationale

### Trust Boundary

A point where security context changes and validation MUST occur. Trust boundaries separate different authority domains and require:

- Authentication at crossing
- Validation of assertions
- Audit logging

### Component

A building block of the architecture with defined responsibilities, interfaces, and failure modes. Components are the "pieces" that together form the system.

### Rationale

Documentation of why design decisions were made, including:

- Alternatives that were considered
- Why alternatives were rejected
- Which invariants alternatives would violate

---

## Abbreviations

| Abbreviation | Expansion |
|--------------|-----------|
| ADR | Architecture Decision Record |
| BCP | Best Current Practice |
| CRD | Custom Resource Definition |
| RFC | Request for Comments |
| TOC | Table of Contents |

---

## Diagram Index

Architecture RFCs MUST maintain a diagram index. Example:

| Diagram | Location | Description |
|---------|----------|-------------|
| System Overview | 03-architecture.md | High-level system diagram |
| Trust Boundaries | 03-architecture.md | Security boundary visualization |
| Authentication Flow | 05-identity.md | User authentication sequence |
| Secret Sync Flow | 06-secrets.md | Vault to Kubernetes sync |

---

*End of Appendix A — RFC-RFCSTD-0002*
