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
