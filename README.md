# Cloud Native EDA Microservices & Observability 

A research and experimentation repository for **Cloud Native Event-Driven Microservices** with a strong focus on **observability** (trace, log, metrics) and how it integrates into event-driven flows and business operations. 

The emphasis is on **architectural learning and experimentation**: EDA patterns, messaging, infrastructure, distributed transactions, **cloud-native deployment**, and **building and fusing observability into the system**-with minimal business logic to keep patterns reusable and clear. 

---

## Table of Contents 

1. [Purpose](#purpose)
2. [Architecture Overview](#architecture-overview)
3. [Core Concepts](#core-concepts)
4. [Event Patterns](#event-patterns)
5. [Messaging Infrastructure](#messaging-infrastructure)
6. [Message Queue Comparison: RocketMQ, RabbitMQ, Kafka](#message-queue-comparison-rocketmq-rabbitmq-kafka)
7. [Distributed Transaction and Saga](#distributed-transactions-and-saga)
8. [Observability: Trace, Log, Metrics](#observability-trace-log-metrics)
9. [Cloud Native Deployment](#cloud-native-deployment)
10. [Repository Structure](#repository-structure)
11. [Learning Goals](#learning-goals)
12. [Future Experiments](#future-experiments)
13. [License](#license)


---

## Purpose 

Modern microservices face:

- **Distributed transactions and consistency**
- **Service coupling and coordination**
- **Scalability and resilience**
- **Observability in asynchronous, event-driven workflows**


This repository is a **Cloud Native EDA + Observability lab** to study:
- Event-driven communication and classic EDA patterns
- CORS and Event Sourcing 
- Saga-based distributed transactions
- **Observability**: how we establish observability based on EDA microservices , distributed tracing, structured logging, and metrics-and how they integrate with event flows and business use cases
- Cloud-native deployment and operational for EDA microservices 

The goal is **understanding architectural patterns and solutions**, not production-ready business applications. 


---

## Architecture Overview 


```
Cloud Native Infrastructure
         │
         ▼
Event-Driven Architecture (EDA)
         │
         ▼
Microservices + Observability (Trace, Log, Metrics)
```


Principles:
- Services communication via **events**, not direct synchronous calls. 
- **CQRS** separates command and query responsibilities. 
- **Event Sourcing** stores system state as a sequence of events. 
- **Saga patterns** handle distributed transactions. 
- **Observability** is built in: trace, log, and metrics are part of the design and deployment. 
- Infrastructure is **containerized, discoverable, and scalable**. 


---

## Core Concepts 

| Concept | Description |
|--------|-------------|
| **Event-Driven Architecture (EDA)** | Services emit domain events; other services consume them asynchronously. |
| **CQRS** | Separate write (commands) from read (queries). |
| **Event Sourcing** | Store every change to an entity as an immutable event; state is derived by replay. |
| **Saga** | Coordinate long-running distributed transactions with compensations on failure. |
| **Cloud Native** | Containers, orchestration, service discovery, API gateway, observability, resilience. |

---

## Event Patterns 

### Event Notification

Services notify others that something happend (e.g., `OrderCreatedEvent`, `UserRegisteredEvent`)

### Event-Carried State Transfer 
Event carry state so consumers can update local views: 

```json
 {
     "type": "ProductUpdatedEvent",
     "productId": 123,
     "price": 49.99,
     "inventory": 50
}
```

### Event Sourcing 
Entity state is reconstructed by replaying events: full audit trail, time-travel debugging, and replay for recovery for new projections. 


---

## Messaging Infrastructure 

Relevant brokers and services: 

- **Apache Kafka** - high-throughput event streaming 
- **RabbitMQ** - reliable messaging and flexible routing 
- **RocketMQ** - high-throughput, order-friendly messaging (Alibaba ecosystem)
- **Axon Server** - event store for CQRS and event sourcing 
- **Cloud messaging** - AWS SNS/SQS, GCP Pub/Sub, Azure Event Grid 

Supporting patterns: Event Bus / Event Stream, Publish/Subscribe, message-driven workflows. 

---

## Message Queue Comparison: RocketMQ, RabbitMQ, Kafka 

Based on the **messaging and EDA theory** above (event notification, event-carried state transfer, event sourcing, Saga), this section compares three mainstream MQs and the **adjustments** each implies for your solution, plus **trade-offs** in classic scenarios.

### Theoretical Basis (What We Care About)

| Dimension | Why it matters for EDA / microservices |
|-----------|----------------------------------------|
| **Message model** | Queue (competing consumers) vs broadcast (fan-out) vs log (replay, multiple consumers) |
| **Ordering** | Per-partition/queue vs global; critical for Saga and event sourcing |
| **Retention** | Short (deliver & delete) vs long (replay, audit, event sourcing) |
| **Delivery semantics** | At-most-once, at-least-once, exactly-once; affects idempotency and Saga design |
| **Routing** | Topic-only vs exchange + routing keys vs tags; affects event patterns and filtering |

### High-Level Comparison

| Aspect | **Kafka** | **RabbitMQ** | **RocketMQ** |
|--------|-----------|--------------|--------------|
| **Model** | Distributed log (partitioned topic) | Broker-centric: exchanges + queues | Topic + Tag; queue sharding within broker |
| **Ordering** | Per partition (key-based) | Per queue (single consumer per queue for order) | Per queue (same semantics as partition) |
| **Retention** | Long (configurable, days–forever) | Short (ack then discard) | Configurable (minutes–days) |
| **Throughput** | Very high (batch, sequential I/O) | High (but more per-message overhead) | Very high (similar to Kafka, batch-friendly) |
| **Routing** | Topic + partition key | Exchanges (direct, topic, fanout, headers) | Topic + Tag + optional SQL filter |
| **Replay / multiple consumers** | Native (offset per consumer group) | Need multiple queues or fanout | Native (consumer group + offset) |
| **Exactly-once** | Supported (transactions + idempotent producer) | Harder (at-least-once + idempotent consumer) | At-least-once; idempotent consumer pattern |
| **Operational complexity** | Higher (ZooKeeper/KRaft, partition rebalance) | Lower (single broker or cluster) | Medium (NameServer + Broker) |

### Adjustments by Solution Type

Different **solutions** (event notification, event sourcing, Saga, CQRS) require different capabilities; switching MQ often forces design adjustments.

| Solution / pattern | **Kafka(like NoSQL no standard streaming semantics, but flexible)** | **RabbitMQ(like RDBMS full semantics)** | **RocketMQ** |
|--------------------|-----------|--------------|--------------|
| **Event notification (fire-and-forget)** | Use topic; optional key for ordering. No special adjustment. | Use exchange + queue(s). Easy routing by key or pattern. | Topic + Tag; simple pub/sub. |
| **Event-carried state transfer** | Same as above; consumers build local view. Long retention helps replay/correct. | TTL and dead-letter useful; no long replay by default—re-publish if needed. | Good fit; tag filtering and retention support state sync. |
| **Event sourcing** | **Strong fit**: log is the source of truth; replay and new projections by seeking offset. | **Adjustment**: no native log; use separate event store or one queue per aggregate + external store for history. | **Good fit**: ordered queue per aggregate/sharding key; retention allows limited replay. |
| **CQRS (read models)** | Projections as consumer groups; replay by resetting offset. Minimal adjustment. | Each read model = queue(s); fanout from exchange. No replay unless you re-publish. | Similar to Kafka; consumer group + offset for replay. |
| **Saga (choreography)** | Order events by correlation/saga ID via partition key so one partition = one saga order. | Route by correlation_id or routing key; ensure one consumer per saga flow for order (e.g. one queue per saga type). | Use message key (e.g. sagaId) for ordering; same-partition semantics. |
| **Saga (orchestration)** | Orchestrator emits commands/events to topics; same ordering and idempotency concerns. | Orchestrator sends to specific queues; DLQ and retries are built-in. | Same idea; use tags for step type, key for instance id. |

**Takeaway:** Kafka and RocketMQ suit **event log, replay, and event sourcing** with little extra storage; RabbitMQ suits **routing-rich, short-lived task/event distribution** and may need an extra store or re-publish for replay.

### Classic MQ Scenarios: Trade-offs

| Scenario | Best fit | Trade-off |
|----------|----------|-----------|
| **Task queue / job distribution** | RabbitMQ (per-message ack, TTL, DLQ, priority queues) | Kafka/RocketMQ: no “delete after ack” semantics; you commit offset. Use short retention + compact topic or accept “process once by consumer group” as the model. |
| **High-throughput event streaming (e.g. logs, metrics)** | Kafka, RocketMQ | RabbitMQ: higher per-message cost; use batching and more nodes. Kafka/RocketMQ: more ops and rebalance complexity. |
| **Strict ordering per entity (e.g. order ID)** | Kafka (partition by key), RocketMQ (same key → same queue) | RabbitMQ: need single active consumer per “entity stream” or accept out-of-order; scaling is harder. |
| **Pub/sub with many independent subscribers** | Kafka (consumer groups), RocketMQ (consumer groups) | RabbitMQ: one queue per subscriber or fanout; more queues to manage. Kafka/RocketMQ: each group gets full log (storage/cost if retention is long). |
| **Event sourcing / audit log / replay** | Kafka (first-class log) | RabbitMQ: not a log; add event store or re-publish. RocketMQ: good middle ground with retention and offset. |
| **Rich routing (e.g. by event type, region)** | RabbitMQ (exchanges + routing keys) | Kafka/RocketMQ: one topic per “route” or filter in consumer; more topics or application-side filter. |
| **Exactly-once processing** | Kafka (transactions + idempotent producer) | RabbitMQ / RocketMQ: at-least-once + idempotent consumer and dedup; simpler broker, more app logic. |
| **Low ops / quick setup** | RabbitMQ | Kafka/RocketMQ: more components (Kafka: KRaft/ZK; RocketMQ: NameServer); steeper learning curve. |

### Summary

- **Kafka:** Choose when you need a **durable log**, **replay**, **event sourcing**, or **exactly-once**; accept higher operational and conceptual complexity.
- **RabbitMQ:** Choose when you need **flexible routing**, **task queues**, **DLQ**, and **simpler ops**; add your own replay/event store if needed.
- **RocketMQ:** Choose when you need **Kafka-like throughput and ordering** with **tag-based filtering** and often **friendlier ops** (e.g. in Alibaba/Java ecosystems); same “adjustments” as Kafka for event sourcing and Saga, with slightly different semantics (e.g. exactly-once).

In this repo, experiments can **keep the same EDA patterns** (events, Saga, CQRS) and swap the messaging layer while applying the adjustments above so trade-offs are explicit.


Event Handling & Event Replay Topic 
- back fill -> missing recrods, relapy back , replaying no data is lost 
- back pressure -> curcial producer side, 
- event consitency -> toring all state changes as a sequence of immutable events, where different parts of the system reach consistency over time,
- idempotency,  -> which ensures that processing the same event multiple times has no unintended side effects.
- event schema evolution -> flyway(similary -> migration, should be a sequence operation, GRPC prtocols)
- conflluent(schema registry | storagey layer ? ), Apache avro (schema registry | storage layer ? ), json schema ? | checklog files 
- dead letter queues -> providing a fallback for failed events 


Differences of messages and events 
- event somethig already have
- message: for communication 


Saga -> local steps, small isolated operations, avoid distributed blocks, global locking, highly , cloud native env 
TCC, 2PC -> 


---

## Distributed Transactions and Saga 

**Saga** coordinates multi-step flows without global ACID transactions. 

- **Choreography**: Services react to events; no central coordinator. 
- **Orchestration**: A central orchestrator drives steps and compensations. 


Example flow: 
```
Create Order → Reserve Product → Process Payment → Approve Order
```

On failure, compensations (e.g. cancel reservation, reject order, rollback local changes) keep the system eventually consistent. 


---

## Observability: Trace, Log, Metrics

Observability is treated as a first-class concern: **trace**, **log**, and **metrics** are designed into the system and fused with event-driven flows and business operations. 

| Pillar | Role in EDA / Microservices |
|--------|-----------------------------|
| **Trace** | Follow a request or business flow across services and message hops; correlate event publishing and consumption with spans. |
| **Log** | Structured logs (with trace/span IDs) for debugging, audit, and understanding event flow and failures. |
| **Metrics** | Throughput, latency, error rates, queue depths, and business metrics (e.g. orders/sec, saga completion rate). |

**Integration with the business**

- **Trace:** End-to-end visibility for order creation, payment, and saga steps; identify slow or failing services and queues. 
- **Log:** Search by `trace_id` or `correlation_id` to see the full path of an event and related logs. 
- **Metrics:** Dashboards and alerts on saga success/failure, event log, and consumer health to support SLOs and operations. 

Planned or reference tooling (to be refined in experiments): 
- **Tracing**: OpenTelemetry, Jaeger, or vendor equivalents; propagation across HTTP and messaging. 
- **Logging**: Structured JSON logs; aggregations (e.g., Loki, Elasticsearch) and correlation with traces. 
- **Metrics**: Promethus + Grafana (or cloud-native equivalents): exportersand custom metrics for events and sagas. 


---

## Cloud Native Deployment 

```
CloudNative-Apps-Observability/
│
├── services/
│   ├── order-service/
│   ├── product-service/
│   └── payment-service/
│
├── infrastructure/
│   ├── axon-server/
│   ├── kafka/
│   └── docker/
│
├── architecture/
│   ├── eda-patterns/
│   ├── messaging-patterns/
│   ├── saga/
│   ├── cqrs/
│   └── event-sourcing/
│
├── observability/
│   ├── trace/
│   ├── log/
│   └── metrics/
│
├── docs/
│   ├── architecture-notes/
│   ├── event-flows/
│   └── saga-workflows/
│
└── experiments/
    ├── axon-example/
    └── event-driven-demo/
```

This separates **services**, **infrastructure**, **architecture patterns**, **observability**, and **docs/experiments**, so the repo works as both a learning lab and a knowledge base. 

---

## Learning Goals 
- Understand event-driven microservices communication and classic EDA patterns. 
- Explore CQRS and event sourcing (e.g., with Axon).
- Experiment with Saga (choregraphy vs orchestration) for distributed transactions. 
- Learn patterns for eventually consistent systems. 
- **Design and implement observability**: trace, log, metrics, and their fusion with event flows and business scenarios. 
- Study cloud-native deployment and service orchestration. 
- Compare messaging platforms and event patterns. 


---

## Future Experiments 
- Integrate **Kafka** for event streaming. 
- Compare **choregraphy vs orchestration** Sagas with concrete flows. 
- Snapshotting and event replay optimizations. 
- **Kubernetes deployments and Helm charts** (apps + observability stack).
- **Observability:** OpenTelemetry instrumentation, trace propagation across events, structured logging, Prometheus metrics and Grafana dashboards. 
- Idempotency and retry strategies in event-driven consumers. 

---

## Notes 
This repository is for **learning, research, and experimentation**. Code is kept simple for clarity; architecture and observability patterns are prioritized over production hardening. 

---

## License 
MIT License 
