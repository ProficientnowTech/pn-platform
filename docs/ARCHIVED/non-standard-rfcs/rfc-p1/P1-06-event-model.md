# RFC-P1-06 — Event Model

**Status:** Draft
**Audience:** Platform Engineers, Architects, Operations Teams

---

## 1. Introduction

This document defines the event model that underlies the orchestration system. It establishes that events are immutable facts, explains replay semantics, defines idempotency requirements, and specifies how the system tolerates duplicate events. This model provides the foundation for asynchronous, reliable orchestration.

---

## 2. Events as Immutable Facts

### 2.1 What an Event Is

An event is a record that something happened. An event is not a command to do something. An event is not a request for something. An event is a statement of fact: at a specific time, a specific thing occurred.

Events are expressed in past tense because they describe the past. "Resource A was deployed." "Capability X was provided." "Deployment Y was initiated." The event records what has already happened, not what is happening or what will happen.

### 2.2 Immutability

Events are immutable. Once an event is created, it cannot be modified. The event records a fact; facts cannot be changed. If the fact was recorded incorrectly, a new event may be created to correct or supersede it, but the original event remains.

Immutability is essential for reliability. If events could be modified, the system could not reason about what happened. Any event might have been changed since it was last observed. Immutability provides the guarantee that an event, once observed, will remain as observed.

Immutability is essential for replay. If events could be modified, replaying the event stream might produce different results depending on when the replay occurred. Immutability ensures that replay is deterministic: the same events always produce the same interpretation.

### 2.3 Event Content

An event must contain sufficient information to be meaningful in isolation. An event must not require external context to be interpreted. A consumer of the event must be able to understand what happened by examining the event alone.

This self-containment means events include:

**Event Type:** What kind of event this is. The type determines how the event is interpreted.

**Event Subject:** What the event is about. The subject identifies the resource, capability, or entity affected by the event.

**Event Timestamp:** When the event occurred. The timestamp establishes ordering and enables temporal reasoning.

**Event Payload:** Additional data specific to the event type. The payload contains the details of what happened.

### 2.4 Events vs. State

Events record changes. State represents current condition. The relationship is fundamental: state is derived from the accumulation of events.

The orchestrator may maintain current state for operational purposes. But this state is derivative, not authoritative. The authoritative record is the sequence of events. State can always be reconstructed from events; events cannot be reconstructed from state.

This relationship has implications for system design. State may be cached, approximated, or temporarily inconsistent. Events must be persisted, accurate, and durable. State is for performance; events are for correctness.

### 2.5 Fact vs. Command

Events represent facts, not commands. The distinction is critical:

A fact is something that has happened. A fact cannot be rejected or refused. A fact cannot fail. A fact simply is.

A command is a request for something to happen. A command may be rejected. A command may fail. A command may not be executed.

Events do not tell the system what to do. Events tell the system what has happened. The system then decides what to do in response to what has happened. This separation enables loose coupling: event producers do not need to know what event consumers will do with the events.

---

## 3. Replay Semantics

### 3.1 Definition of Replay

Replay is the process of reprocessing a sequence of events. During replay, events are consumed in order, and the system state is reconstructed from the event sequence.

Replay may occur for several reasons:
- System restart after failure
- State reconstruction after corruption
- Testing and validation
- Debugging and analysis

Regardless of the reason, replay must produce correct results. The system must be designed so that replaying events produces the same state as processing those events originally.

### 3.2 Replay Determinism

Replay must be deterministic. Processing the same sequence of events must always produce the same state. If replay produces different results on different executions, the system cannot be trusted to recover correctly.

Determinism requires that event processing have no hidden inputs. The outcome of processing an event must depend only on:
- The event itself
- The state derived from previously processed events

Event processing must not depend on:
- Wall clock time (except as recorded in events)
- Random number generation
- External system state (except as recorded in events)
- Execution environment details

Any dependency on hidden inputs breaks replay determinism. If event processing consulted an external system, replay would need to consult the same external system, which might have changed. The replay would produce different results.

### 3.3 Replay Order

Events must be replayed in the same order they were originally processed. If events were processed in order A, B, C, replay must process them in order A, B, C.

Order matters because events may have dependencies. Processing event B may depend on state established by event A. If B is processed before A during replay, the state will be incorrect.

Event timestamps enable ordering. Events are ordered by timestamp. When timestamps are equal, a secondary ordering criterion must break ties deterministically. The specific secondary criterion is an implementation detail; what matters is that the criterion is deterministic.

### 3.4 Partial Replay

Replay need not always start from the beginning. The system may maintain checkpoints: snapshots of state at specific points in the event stream. Replay may start from a checkpoint and process only events after that checkpoint.

Checkpoints improve replay performance. Replaying thousands of events is slower than loading a checkpoint and replaying a few events. But checkpoints are optimizations, not requirements. The system must be able to replay from the beginning if checkpoints are unavailable or corrupted.

Checkpoint integrity must be verified. A corrupted checkpoint would cause replay to produce incorrect results. The system must detect corrupted checkpoints and fall back to earlier checkpoints or full replay.

### 3.5 Replay Completeness

Replay must process all events. Skipping events produces incorrect state. If event B depends on event A, and A is skipped, B will be processed against incorrect state.

There is no mechanism for "skipping" events during replay. Every event in the sequence must be processed. If an event causes problems during replay, the problem must be addressed; the event cannot be ignored.

---

## 4. Idempotency

### 4.1 Definition of Idempotency

An operation is idempotent if performing it multiple times produces the same result as performing it once. For event processing, idempotency means that processing the same event multiple times produces the same state as processing it once.

Idempotency is required because events may be delivered multiple times. Network failures, retries, and system restarts may cause the same event to be presented for processing more than once. The system must handle this correctly.

### 4.2 Idempotency Requirement

All event processing must be idempotent. There must be no event whose repeated processing produces different results than single processing.

This requirement is absolute. It is not acceptable for "most" events to be idempotent. Every event must be idempotent. A single non-idempotent event breaks system correctness.

### 4.3 Achieving Idempotency

Idempotency is achieved through event identification and state checking.

**Event Identification:** Each event must have a unique identifier. The identifier enables the system to recognize when it has seen an event before. If an event's identifier has been processed, the event is a duplicate.

**State Checking:** Before applying an event's effects, the system must check whether those effects have already been applied. If the state already reflects the event's effects, the event is a duplicate.

Both mechanisms are necessary. Event identification enables quick duplicate detection. State checking provides a safety net when event identification fails or is unavailable.

### 4.4 Idempotency and Side Effects

Idempotency applies to state changes, not to side effects. An event that logs a message may log the message multiple times if processed multiple times. This is acceptable; logs are observational, not authoritative.

But state changes must be idempotent. An event that increments a counter must not increment the counter twice if processed twice. Either the system must recognize the duplicate and skip the increment, or the counter must be set to an absolute value rather than incremented.

The distinction guides implementation. Operations that set absolute values are naturally idempotent. Operations that apply relative changes (increment, append, add) require duplicate detection to be idempotent.

### 4.5 Idempotency Failures

If idempotency fails—if an event is processed twice and produces incorrect state—the failure is silent. The system does not crash; it continues with incorrect state. This makes idempotency failures particularly dangerous.

Testing must verify idempotency. Every event type must be tested for correct behavior under duplicate delivery. The test must process the event, process it again, and verify that state is correct.

---

## 5. Duplication Tolerance

### 5.1 Why Duplicates Occur

Duplicate events occur in distributed systems for several reasons:

**Network Retries:** If an event is sent and no acknowledgment is received, the sender may retry. The original event may have been received; the retry creates a duplicate.

**Producer Restarts:** If a producer fails after sending an event but before recording that it sent it, the producer may resend the event after restart.

**Consumer Restarts:** If a consumer fails after receiving an event but before processing it, the event may be redelivered after restart.

**At-Least-Once Delivery:** Many messaging systems guarantee at-least-once delivery rather than exactly-once delivery. At-least-once means duplicates are possible.

Duplicates are a fact of distributed systems. They cannot be eliminated; they must be tolerated.

### 5.2 Tolerance Requirements

The system must tolerate duplicate events without:

**State Corruption:** Duplicate events must not corrupt state. Processing a duplicate must leave state unchanged (if the original was processed) or must apply the event correctly (if the original was not processed).

**Behavioral Changes:** Duplicate events must not cause different behavior than single events. The system must behave as though it received each event exactly once.

**Operator Intervention:** Duplicate events must not require operator intervention. The system must handle duplicates automatically.

### 5.3 Duplicate Detection

The system must detect duplicate events. Detection uses event identifiers: each event has a unique identifier, and the system tracks which identifiers have been processed.

Duplicate detection requires storage. The system must record processed event identifiers. This record must be durable; it must survive restarts. If the record is lost, duplicates may go undetected.

Duplicate detection has limits. The system cannot store every event identifier forever. Identifiers for old events may be purged. If a very old event is redelivered after its identifier was purged, it may be processed as new. This is acceptable if the event stream has a bounded delay: events redelivered after a long delay are operational anomalies, not normal operation.

### 5.4 Duplicate Handling

When a duplicate is detected, the system must:

**Acknowledge the Event:** The duplicate must be acknowledged to the event source. If the duplicate is not acknowledged, the source will retry, creating more duplicates.

**Skip Processing:** The duplicate must not be processed. Processing would apply effects that have already been applied, violating idempotency.

**Log the Occurrence:** The duplicate detection may be logged for operational visibility. Excessive duplicates indicate a problem worth investigating.

Duplicate handling must be fast. Duplicates are common in healthy systems; handling them must not be expensive.

### 5.5 Duplicates and Ordering

Duplicates may arrive out of order. The original event A might be followed by event B, but the duplicate of A might arrive after B.

This scenario must be handled correctly. If A's duplicate is detected (A was already processed), it is skipped regardless of when it arrives. The ordering of duplicate arrival does not affect correctness because duplicates are not processed.

If duplicates were not detected and were processed, out-of-order duplicates would corrupt state. This is another reason duplicate detection is required, not optional.

---

## 6. Event Model Properties

### 6.1 Events Are the Source of Truth

The event stream is the authoritative record of what happened. State is derived from events. If state and events disagree, events are correct.

This principle enables recovery. If state is corrupted, it can be rebuilt from events. If events were corrupted or lost, recovery would be impossible. Events must be protected accordingly.

### 6.2 Events Enable Loose Coupling

Event producers and consumers are decoupled. A producer emits events without knowing who consumes them. A consumer processes events without knowing who produced them.

This decoupling enables independent evolution. Producers can change without affecting consumers (as long as event schemas are compatible). Consumers can change without affecting producers. New consumers can be added without modifying producers.

### 6.3 Events Enable Temporal Decoupling

Events decouple production time from consumption time. An event may be produced at time T and consumed at time T+N. The consumer does not need to be running when the event is produced.

Temporal decoupling enables asynchronous processing. Consumers process events at their own pace. Producers do not wait for consumers. This asynchrony is fundamental to the orchestration system's design.

### 6.4 Events Enable Auditability

The event stream is a complete audit log. Every significant occurrence is recorded. The sequence can be examined to understand what happened, when, and in what order.

Auditability supports debugging. When something goes wrong, the event stream shows what led to the failure. This visibility is essential for diagnosing complex orchestration problems.

---

## 7. Summary

### 7.1 Core Principles

**Immutability:** Events are facts that cannot be changed.

**Replay:** Events can be reprocessed to reconstruct state.

**Idempotency:** Processing events multiple times produces the same result as processing once.

**Duplication Tolerance:** The system handles duplicate events correctly.

### 7.2 Why These Properties Matter

These properties enable reliable, asynchronous orchestration. Events provide a durable record. Replay enables recovery. Idempotency and duplication tolerance ensure correctness despite the realities of distributed systems.

Without these properties, the system could not recover from failures, could not tolerate network anomalies, and could not provide correctness guarantees. These properties are not optional; they are foundational.

---

*End of RFC-P1-06*
