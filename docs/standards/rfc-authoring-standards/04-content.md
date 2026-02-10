```
RFC Authoring Standards                                           Section 4
Category: Standards Track                            Content Requirements
```

# 4. Content Requirements

[← Structure](./03-structure.md) | [Index](./00-index.md) | [Next →](./05-formatting.md)

---

## 4.1 Originality

Each RFC MUST contain original content specific to its problem domain.

### Authors MUST NOT

| Prohibited | Reason |
|------------|--------|
| Copy prose from other RFCs | Content must be domain-specific |
| Reuse context-specific narratives | Each RFC has unique context |
| Duplicate problem statements | Problems differ between domains |

### Authors MAY

| Permitted | Reason |
|-----------|--------|
| Follow the same structural patterns | Consistency aids comprehension |
| Use consistent formatting conventions | Standard format improves readability |
| Reference other RFCs | Avoids duplication |

---

## 4.2 What RFCs MUST Include

### 4.2.1 Context and Motivation

RFCs MUST:

- Define the problem space unique to this RFC
- Explain why this architecture is necessary
- Describe the specific operational pain points being addressed

### 4.2.2 Guarantees and Contracts

RFCs MUST:

- Specify what the system guarantees
- Define interfaces and their contracts
- Document behavioral expectations

### 4.2.3 Invariants

RFCs MUST:

- List rules that MUST always hold true
- Use RFC 2119 keywords for requirement levels
- Explain consequences of invariant violation

### 4.2.4 Multi-Level Documentation

RFCs MUST document design at multiple levels:

| Level | Content |
|-------|---------|
| High | Overall system behavior and properties |
| Medium | Component interactions and relationships |
| Low | Internal component details and mechanics |

### 4.2.5 Rationale

RFCs MUST:

- Document alternatives considered
- Explain why alternatives were rejected
- Reference which invariants each alternative violated

### 4.2.6 Glossary and References

RFCs MUST:

- Define all domain-specific terms
- Cite normative and informative sources
- Index architectural decisions

---

## 4.3 What RFCs MUST NOT Include

### 4.3.1 Implementation Code

| Prohibited | Why |
|------------|-----|
| Code examples or snippets | RFCs describe behavior, not implementation |
| Configuration samples | Configuration belongs in implementation repos |
| Shell commands or scripts | RFCs are not runbooks |

Implementation details belong in separate documents.

### 4.3.2 Timelines or Durations

| Prohibited | Why |
|------------|-----|
| Time estimates for tasks | Focus on sequence, not timing |
| Scheduling predictions | Timing is implementation-specific |
| Phase duration specifications | Dependencies matter, not duration |

### 4.3.3 Implementation Tasks

| Prohibited | Why |
|------------|-----|
| Step-by-step implementation guides | RFCs describe what, not how |
| Task lists or checklists | Implementation planning is separate |
| "How to implement" instructions | Belongs in Specification RFCs or runbooks |

### 4.3.4 Implicit Assumptions

| Rule | Reason |
|------|--------|
| Every assumption MUST be explicit | Prevents misunderstanding |
| No reliance on tribal knowledge | RFC must stand alone |
| No "obvious" prerequisites left unstated | Nothing is obvious to newcomers |
| All dependencies MUST be documented | Enables reproducibility |

### 4.3.5 Emotional or Promotional Language

| Prohibited | Why |
|------------|-----|
| Superlatives ("best", "fastest") | Not objective |
| Marketing language | RFCs are technical documents |
| Enthusiasm over precision | Technical accuracy matters |
| Advocacy over assessment | Present facts neutrally |

---

## 4.4 Behavioral Specification

RFCs describe **what** systems do and **why**, not **how** to build them.

| RFC Scope | Implementation Scope |
|-----------|---------------------|
| System behavior | Code structure |
| Guarantees provided | Algorithms used |
| Interfaces exposed | Data structures |
| Failure semantics | Error handling code |
| State transitions | State machine implementation |

---

*End of Section 4 — RFC Authoring Standards*
