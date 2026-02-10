```
RFC-RFCSTD-0004                                                   Section 1
Category: Standards Track                                             Scope
```

# 1. Scope

[← Index](./00-index.md) | [Index](./00-index.md) | [Next →](./02-requirements.md)

---

## 1.1 Purpose

BCP RFCs document operational guidelines and recommended practices. They establish:

| Aspect | Description |
|--------|-------------|
| Recommended Approaches | Practices based on operational experience |
| Guidelines | What SHOULD be followed unless context requires otherwise |
| Procedures | Steps for common operational tasks |
| Considerations | Trade-offs and decision-making guidance |

BCPs answer "How should we operate this system effectively?" rather than "What should we build?" or "How do we implement it?"

---

## 1.2 Applicability

This RFC applies to all BCP kind RFCs, typically addressing:

| Domain | Example BCPs |
|--------|--------------|
| Operational Procedures | Incident response, on-call, deployments |
| Security Practices | Access reviews, secret rotation schedules |
| Development Practices | Code review, testing strategies |
| Infrastructure Practices | Monitoring, alerting, capacity planning |

Any RFC with `Kind: BCP` in its metadata MUST follow this standard.

---

## 1.3 BCP vs Architecture vs Specification

| Aspect | Architecture | Specification | BCP |
|--------|--------------|---------------|-----|
| Focus | System design | Implementation requirements | Operational practices |
| Keyword emphasis | MUST/MUST NOT | MUST with validation | SHOULD/RECOMMENDED |
| Change frequency | Rare | Per implementation | Evolves with experience |
| Strictness | Absolute | Deterministic | Flexible |
| Audience | Architects | Implementers | Operators |

---

## 1.4 When to Use BCP

Use BCP when documenting:

| Scenario | Example |
|----------|---------|
| Operational procedures | "How to perform secret rotation" |
| Recommended practices | "Security review guidelines" |
| Guidelines with exceptions | "Deployment practices (with context-specific variations)" |
| Community consensus | "Agreed approaches for incident handling" |

Do NOT use BCP for:

| Scenario | Use Instead |
|----------|-------------|
| Architectural decisions | Architecture RFC |
| Strict implementation requirements | Specification RFC |
| One-time procedures | Runbooks or playbooks |

---

## 1.5 BCP Flexibility

BCPs acknowledge that practices may need adaptation:

| Situation | BCP Response |
|-----------|--------------|
| Context differs | Document exceptions |
| New information | Update BCP with experience |
| Team preference | Allow RECOMMENDED alternatives |
| Emergency | Document emergency overrides |

This flexibility is why BCPs use SHOULD rather than MUST.

---

## 1.6 Conformance

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174].

**Note**: BCPs primarily use SHOULD, RECOMMENDED, and MAY. BCPs SHOULD avoid MUST except for safety-critical requirements.

---

*End of Section 1 — RFC-RFCSTD-0004*
