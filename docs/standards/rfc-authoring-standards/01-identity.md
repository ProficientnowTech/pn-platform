```
RFC Authoring Standards                                           Section 1
Category: Standards Track                       Identity and Classification
```

# 1. Identity and Classification

[← Index](./00-index.md) | [Index](./00-index.md) | [Next →](./02-versioning.md)

---

## 1.1 RFC Identifier Format

Each RFC MUST have a unique identifier following this format:

```
RFC-<DOMAIN>-<NUMBER>
```

Where:

| Component | Description | Examples |
|-----------|-------------|----------|
| `<DOMAIN>` | Short uppercase identifier for the problem domain | SECOPS, DEPLOY, NETWORK, IAM |
| `<NUMBER>` | Zero-padded four-digit sequential number | 0001, 0002, 0003 |

**Examples:**

| Identifier | Domain |
|------------|--------|
| RFC-SECOPS-0001 | Secret operations |
| RFC-DEPLOY-0001 | Deployment orchestration |
| RFC-NETOPS-0001 | Network operations |
| RFC-IAM-0001 | Identity and access management |

---

## 1.2 RFC Status Values

Each RFC MUST declare one of the following status values:

| Status | Meaning | Mutable |
|--------|---------|---------|
| Draft | Under active development, subject to change | Yes |
| Review | Complete draft awaiting review | Yes (based on feedback) |
| Accepted | Approved for implementation | PATCH only |
| Implemented | Architecture has been implemented | PATCH only |
| Superseded | Replaced by a newer RFC | No (frozen) |
| Withdrawn | No longer applicable | No (frozen) |

---

## 1.3 RFC Categories

Each RFC MUST declare a category:

| Category | Use |
|----------|-----|
| Standards Track | Architectural specifications intended for implementation |
| Informational | Documentation, guidelines, or background information |
| Experimental | Proposals for evaluation before standardization |

---

## 1.4 RFC Kinds

Each RFC MUST declare a kind that determines its structure and purpose:

| Kind | Purpose | Content Focus |
|------|---------|---------------|
| Standards | Meta-RFCs defining how to write RFCs | RFC process, formatting, validation |
| Architecture | Conceptual system design | What and why, not how to implement |
| Specification | Implementation requirements | Prerequisites, resources, validation criteria |
| BCP | Operational guidelines | Recommended practices and procedures |

---

## 1.5 Kind Selection Criteria

| If describing... | Use Kind |
|------------------|----------|
| How to write RFCs or RFC standards | Standards |
| System behavior, trust boundaries, invariants | Architecture |
| Implementation prerequisites, resources, validation | Specification |
| Operational procedures, guidelines, practices | BCP |

---

## 1.6 Kind Relationships

```
┌──────────────┐
│  Standards   │  Meta-level: Defines how to write other RFCs
│  (RFCSTD)    │  Self-referential: Standards RFCs follow their own rules
└──────┬───────┘
       │ governs
       ▼
┌─────────────────────────────────────────────────────────────────┐
│  Architecture      Specification           BCP                  │
│  (Conceptual)  ─►  (Implementation)  ◄──  (Operations)          │
│                                                                 │
│  • System behavior     • Prerequisites        • Procedures      │
│  • Trust boundaries    • Resource tables      • Guidelines      │
│  • Invariants          • Validation criteria  • Practices       │
│  • Rationale           • Test requirements    • Flexibility     │
└─────────────────────────────────────────────────────────────────┘
```

| Relationship | Description |
|--------------|-------------|
| Specification → Architecture | A Specification RFC SHOULD reference an Architecture RFC as its foundation |
| BCP → Architecture/Specification | A BCP MAY reference Architecture or Specification RFCs for context |
| Standards → All | Standards RFCs govern all other kinds, including themselves |
| Architecture → Specification | An Architecture RFC MAY reference planned Specification RFCs in its Evolution section |

---

## 1.7 Kind-Specific Standards

Each RFC kind has its own structure and validation criteria:

| Kind | Governing RFC | Location |
|------|---------------|----------|
| Standards | RFC-RFCSTD-0001 | `docs/standards/rfc-kinds/standards/RFC-RFCSTD-0001/` |
| Architecture | RFC-RFCSTD-0002 | `docs/standards/rfc-kinds/architecture/RFC-RFCSTD-0002/` |
| Specification | RFC-RFCSTD-0003 | `docs/standards/rfc-kinds/specification/RFC-RFCSTD-0003/` |
| BCP | RFC-RFCSTD-0004 | `docs/standards/rfc-kinds/bcp/RFC-RFCSTD-0004/` |

The RFC Kind Registry at `docs/standards/rfc-kind-registry/` tracks all registered kinds.

---

*End of Section 1 — RFC Authoring Standards*
