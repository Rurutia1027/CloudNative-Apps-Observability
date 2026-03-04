# Microservices

![Screenshot 2021-11-30 at 12 32 51](https://user-images.githubusercontent.com/40702606/144061535-7a42e85b-59d6-4f7f-9c35-18a48b49e6de.png)

---

## Microservices Observability Enhancement

### 1. Background

This project is a Spring Boot–based microservices system (`customer`, `fraud`, `notification`, `apigw`, `amqp`,
`clients`) that has been modernized to be more cloud‑native friendly (Spring Cloud Gateway, Kubernetes‑oriented service
discovery, Zipkin tracing).

This document describes an observability‑focused enhancement of the existing data access and messaging layers by
introducing structured tracing and custom metrics collection.

The focus is strictly on **application‑level observability** and **layered visibility**, without introducing database
sharding, middleware proxies, or infrastructure‑level complexity.

Sharding solutions (e.g., database proxies or distributed database middleware) are intentionally excluded from the
current scope to keep the implementation focused, incremental, and production‑feasible.

---

### 2. Objectives

The goal is to achieve the following:

1. Introduce **layered tracing** across:
    - Controller / HTTP endpoint
    - API Gateway (Spring Cloud Gateway)
    - Service layer
    - Repository / JPA
    - JDBC execution
    - AMQP message handling

2. Implement **custom metrics** to measure:
    - Request and query execution count
    - Request and query latency
    - Error rate per service and per logical layer

3. Ensure:
    - Complete call chain visibility in the distributed tracing UI (Zipkin today, OpenTelemetry‑compatible in the
      future)
    - Service‑level topology visibility in the service mesh UI (e.g., Kiali for Istio / Kubernetes Gateway)
    - Metrics collected and exposed for Prometheus scraping

4. Maintain:
    - Minimal architectural intrusion
    - Low operational complexity
    - Clear separation of tracing and metrics responsibilities

---

### 3. Non‑Goals

The following are explicitly out of scope for this iteration:

- Database sharding
- ShardingSphere integration
- Vitess integration
- Cross‑database routing
- Data partition redesign
- Multi‑tenant data isolation
- Infrastructure‑level database scaling changes

The current iteration focuses exclusively on observability improvements within the application layer of this
microservices system.

---

### 4. High‑Level Architecture

#### 4.1 Logical Call Flow

```text
Client
    ↓
API Gateway (Spring Cloud Gateway)
    ↓
Service (customer / fraud / notification)
    ↓
Repository (Spring Data JPA)
    ↓
Database
```

AMQP‑based flows (for internal events) follow a similar pattern:

```text
Producer Service
    ↓
AMQP Exchange / Queue
    ↓
Consumer Service
    ↓
Handler + Repository
    ↓
Database
```

Observability instrumentation will be applied to each logical layer.

---

### 5. Tracing Design

#### 5.1 Tracing Framework

Current stack:

- Spring Cloud Sleuth
- Zipkin backend for trace visualization

Future‑ready direction:

- OpenTelemetry SDK
- OTLP exporter
- Jaeger or Tempo as a backend (optional migration path)

#### 5.2 Span Hierarchy

Each layer creates or enriches its own span:

```text
HTTP GET /api/v1/customers
  └── Gateway route (api-gateway)
        └── customer-service controller
              └── CustomerService method
                    └── Repository method
                          └── JDBC call (auto‑instrumented)
```

For messaging:

```text
Business action
  └── Publish AMQP message
        └── Consumer handler
              └── Service / Repository
                    └── JDBC call
```

#### 5.3 Implementation Strategy

- Use Sleuth / OpenTelemetry annotations (e.g. `@NewSpan`) or manual span creation where needed.
- Ensure proper parent‑child span context propagation across HTTP and AMQP boundaries.
- Avoid over‑instrumentation; focus on key service and data access boundaries.
- Keep span naming consistent and meaningful.

#### 5.4 Naming Convention

| Layer         | Span Name Example             |
|---------------|-------------------------------|
| Gateway       | `gateway.route.customer`      |
| Controller    | `http.customer.request`       |
| Service       | `service.customer.logic`      |
| Repository    | `repository.customer.execute` |
| JDBC (auto)   | Auto‑instrumented span        |
| AMQP Producer | `amqp.publish.notification`   |
| AMQP Consumer | `amqp.consume.notification`   |

#### 5.5 Key Design Principles

- **Tracing** represents execution flow and causal relationships.
- Tracing does **not** aggregate statistics.
- No business metrics are embedded inside spans.

---

### 6. Custom Metrics Design

#### 6.1 Metrics Framework

- Micrometer (already standard with Spring Boot)
- Prometheus registry
- `/actuator/prometheus` endpoint for scraping

#### 6.2 Core Metrics

1. **Request / Query Counter**

   ```text
   microservice_request_total{service, layer, status}
   ```

   Tracks total attempts per microservice and logical layer.

2. **Latency Histogram**

   ```text
   microservice_request_duration_seconds{service, layer}
   ```

   Tracks latency distribution for HTTP, repository, and messaging operations.

3. **Error Counter**

   ```text
   microservice_request_error_total{service, layer}
   ```

   Tracks failed executions per microservice and layer.

#### 6.3 Label Strategy

Allowed labels:

- `service` (customer, fraud, notification, apigw)
- `layer` (gateway, controller, service, repository, messaging)
- `status` (success, error)

Avoid:

- Dynamic SQL or HQL content
- User identifiers
- Request parameters
- High‑cardinality labels

#### 6.4 Separation of Concerns

- **Tracing** shows individual request paths.
- **Metrics** show aggregated statistical behavior.

They must remain loosely coupled.

---

### 7. Visualization Layer

#### 7.1 Zipkin / Jaeger

Used to visualize:

- End‑to‑end traces across gateway and backend services
- Layered call breakdown
- Span duration comparison
- Bottleneck identification

Expected outcome:

- Clear hierarchical execution chain across `apigw`, `customer`, `fraud`, `notification`
- Visibility into repository and messaging execution cost

#### 7.2 Kiali (Service Mesh Level)

When deployed behind a service mesh (e.g., Istio), Kiali can be used to visualize:

- Service‑to‑service traffic
- Request rates
- Error rates
- Latency at service boundaries

Important distinction:

- **Zipkin / Jaeger** → method‑level tracing.
- **Kiali** → service‑level topology.

---

### 8. Implementation Roadmap

#### Phase 1 – Basic Tracing

- Enable and validate HTTP → JDBC and HTTP → AMQP trace visibility across services.

#### Phase 2 – Layered Spans

- Add manual spans to:
    - Service methods
    - Repository hotspots
    - Messaging producers and consumers
- Validate nesting correctness across microservices.

#### Phase 3 – Custom Metrics

- Implement core Micrometer metrics.
- Expose `/actuator/prometheus` in each service.
- Verify Prometheus scraping in the target environment.

#### Phase 4 – Validation

- Confirm trace completeness.
- Confirm metrics correctness.
- Confirm no significant performance regression.

---

### 9. Success Criteria

The implementation is considered successful if:

- A single gateway‑initiated request shows a complete layered trace across services.
- Repository and messaging execution time is clearly measurable.
- Metrics show request count and latency distribution per microservice.
- Service topology is visible in the service mesh UI (when deployed with Istio or similar).
- No sharding or infrastructure‑level database changes were required.

---

### 10. Design Philosophy

This implementation follows three principles:

1. Start small and iterate.
2. Prioritize observability before scalability.
3. Avoid premature architectural complexity.

By removing sharding concerns from this phase, we ensure:

- Reduced cognitive load.
- Faster delivery.
- Cleaner validation of observability improvements.

Scalability enhancements (e.g., distributed database strategies) can be addressed in future iterations after
observability foundations are stable.

---

### 11. Future Extensions (Optional)

After observability is stable:

- Introduce query and request classification metrics.
- Add slow‑request alerting.
- Add adaptive sampling for traces.
- Evaluate distributed database solutions if necessary.

---

### 12. Final Statement

This document defines a focused, pragmatic observability enhancement for the current Spring Boot microservices stack.

The primary deliverable is not infrastructure complexity, but clarity:

- Clear execution visibility.
- Clear performance metrics.
- Clear service‑level traffic topology.

This provides a stable foundation for future scalability work without over‑engineering the present solution.
