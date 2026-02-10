```
RFC-RFCSTD-0004                                                   Section 2
Category: Standards Track                          Normative Requirements
```

# 2. Normative Requirements

[← Scope](./01-scope.md) | [Index](./00-index.md) | [Next →](./03-structure.md)

---

## 2.1 Recommendation Focus Requirement

BCP RFCs SHOULD use SHOULD/RECOMMENDED rather than MUST/REQUIRED.

MUST is appropriate in BCPs only for:

| Scenario | Example |
|----------|---------|
| Safety-critical requirements | "Production changes MUST be reviewed" |
| Legal or compliance requirements | "Audit logs MUST be retained for 7 years" |
| Requirements preventing data loss | "Backups MUST be verified before rotation" |
| Security breach prevention | "Secrets MUST NOT be logged" |

For general operational practices, prefer SHOULD:

| Instead Of | Use |
|------------|-----|
| "Deployments MUST happen during low traffic" | "Deployments SHOULD happen during low traffic" |
| "You MUST have two reviewers" | "You SHOULD have two reviewers" |

---

## 2.2 Rationale Requirement

Each guideline or recommendation MUST include:

| Component | Requirement | Description |
|-----------|-------------|-------------|
| Rationale | REQUIRED | Why this practice is recommended |
| Applicability | REQUIRED | When to apply this practice |
| Exceptions | REQUIRED | When this practice may not apply |

This ensures readers understand context and can make informed decisions about applicability.

---

## 2.3 Procedure Repeatability Requirement

If a BCP includes operational procedures, each procedure MUST be:

| Requirement | Description |
|-------------|-------------|
| Repeatable | Someone unfamiliar with the system can follow it |
| Self-contained | Clear entry and exit conditions |
| Recoverable | Include recovery steps for common failure scenarios |

---

## 2.4 Evolution Acknowledgment Requirement

BCPs MUST acknowledge that practices evolve:

| Component | Requirement |
|-----------|-------------|
| Version History | MUST be included |
| Change Documentation | Document when practices changed and why |
| Deprecation Notes | Note deprecated practices and their replacements |

---

## 2.5 Reference Requirement

BCPs SHOULD reference related Architecture or Specification RFCs where applicable, establishing context without duplicating content.

| Reference Type | Usage |
|----------------|-------|
| Architecture RFC | Link to explain why system works this way |
| Specification RFC | Link to explain how system was implemented |
| Other BCPs | Link to related operational practices |

---

## 2.6 Keyword Distribution Requirement

BCPs SHOULD follow this keyword distribution:

| Keyword | Frequency | Usage |
|---------|-----------|-------|
| SHOULD | Primary | Most recommendations |
| RECOMMENDED | Secondary | Alternative to SHOULD |
| MAY | Common | Optional practices |
| MUST | Rare | Safety/compliance only |
| MUST NOT | Rare | Safety/compliance only |

A BCP with more MUST than SHOULD may be misclassified and might be a Specification RFC instead.

---

## 2.7 Multi-File Structure Requirement

BCPs MAY use single-file or multi-file structure depending on complexity:

| Condition | Recommendation |
|-----------|----------------|
| BCP under 300 lines | Single file acceptable |
| BCP over 300 lines | Multi-file recommended |
| BCP with multiple independent sections | Multi-file recommended |
| BCP serving as template | Multi-file recommended |

---

*End of Section 2 — RFC-RFCSTD-0004*
