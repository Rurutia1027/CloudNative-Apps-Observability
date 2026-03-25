# Event-Driven Architecture Review

## Scope

This document summarize what this project already demonstrates for event-driven microservices, what it only partially
covers, and what we should add/adapt when applying the same approach to our payment system.

## What this project already covers (good reusable baseline)

### Event contracts (schema-first)

- Uses Avro models (e.g., `PaymentRequestAvroModel`, `PaymentResponseAvroModel` ) as strong cross-service message
  contracts.
- Encourages a shared "contract module" approach (similar to `infrastructure/kafka/kafka-model`).

### Ports & Adapters (Clean Architecture) around messaging

- Kafka consumers/publishers live in `*-messaging` modules and call **domain input ports** (e.g., ...`MessageListener`)
  rather than embedding business logic in Kafka listeners.
- Mapping layer (ACL) isolates domain from Avro/Kafka DTOs (e.g., `PaymentMessagingDataMapper`).

### Outbox pattern (transactional reliability)

- Publishing uses outbox message + outbox status callback (e.g., `OutboxStatus`) to coordinate "send message" and "mark
  status".

### Saga / long-running business process

- Uses a sagaId to correlate request/response flows across services.
- Orchestrated flow pattern in clearly visible (Order -> Payment -> Order -> Restaurant -> Order).

### At-least-once delivery + idempotency tactics

- Consumer-side idempotency/dup handling via DB unique constraints and optimistic locking patterns to avoid harmful
  re-processing.

---

## What is present conceptually but not fully implemented end-to-end here

### CDC (Change Data Capture)

- Mentioned in README.md as a future/alternative to scheduler-based outbox publishing.
- The codebase clearly supports Outbox; CDC appears more like an intended evolution than a fully produced pipeline in
  the sample.

## What is missing / not deeply covered (typical production-grade event-driven gaps)

- Event versioning & schema evolution governance
    - Compatibility rules, versioning strategy, deprecation policy, multi-version consumers.
- DLQ + position message strategy
    - Dead-letter topics/queues, retries limits, quarantining bad messages, human-in-the-loop remediation.
- Replay & reprocess discipline
    - Backfills, replays by time/window, reprocessing safety rules, rebuild read models, audit trails.
- End-to-end observability for async systems
    - Standardized `eventId`, `correlationId`, `causationId`, `traceId`, metrics (lag, retries), structured logs,
      tracing across services.
- Exactly-once boundaries (explicitly defined)
    - Clear stance on "at-least-once + idempotency" vs Kafka EOS; offset commit strategy; atomicity
- Ordering & partitioning strategy (systematically designed)
    - When to key by `sagaId` vs `paymentId` vs `orderId`; cross-topic ordering expectations; out-of-order handling.
- Security & compliance
    - Pll handling, encryption, topic ACLs, redaction, retention policies, GDPR/PCI concerns (highly relevant for
      payment systems.)
- Loading shedding & backpressure
    - Consumer concurrency, rate limits, graceful degradation, rebalancing stability patterns.
- Clear split: Domain Events vs Integration Events
    - Naming conventions, semantics, event granularity guidelines, and when to publish which kind.
- CQRS read-model projection implementation details
    - How projections are built, stored, validated, rebuilt, and monitored (the repo mentions CQRS but doesn't fully
      operationalize it.)

---

# TODOs for adopting this pattern in our Payment System 
## Define event contracts and ownership 

## Apply Ports & Adapters separation for messaging 

## Outbox (minimum production baseline)


## Idempotency & Deduplication Guarantees 


