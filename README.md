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
6. [Distributed Transaction and Saga](#distributed-transactions-and-saga)
7. [Observability: Trace, Log, Metrics](#observability-trace-log-metrics)
8. [Cloud Native Deployment](#cloud-native-deployment)
9. [Repository Structure](#repository-structure)
10. [Learning Goals](#learning-goals)
11. [Future Experiments](#future-experiments)
12. [License](#license)


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

## Messaing Infrastructure 

Relevant brokers and services: 

- **Apache Kafka** - high-throughput event streaming 
- **RabbitMQ** - reliable messaging and flexible routing 
- **Axon Server** - event store for CQRS and event sourcing 
- **Cloud messaging** - AWS SNS/SQS, GCP Pub/Sub, Azure Event Grid 

Supporting patterns: Event Bus / Event Stream , Publish/Subscribe, message-driven workflows. 

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

