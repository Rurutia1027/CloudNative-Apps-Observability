# Thread Pool Usage by Scenario 
In event-driven and messaging systems, **consumer-side concurrency** is often implemented with thread pools (for equivalent worker/actor pools). The following scenarios tend to **depend more on thread pool sizing and design**; others can get by with fewer threads or async I/O.

## Scenario-1 Task Queue / Job Distribution 
Task Queue / Job Distribution, Each task is usually handled by a **worker thread**; throughput is tied to poolsize. Blocking I/O (DB/HTTP) per message keeps threads busy. Large pool = more concurrency but more contxt switch and memroy. 

## Scenario-2 Orchestration-based Saga
Orchestration-based Saga. The orchestrator holds **one logical flow per saga instance** and often issues blocking calls (RPC, HTTP, MQ publish). Without full async, you need a thread per in-flight saga or a bounded pool; pool size directly limits concurrent sagas. 

## Scenario-3 Event sourcing - synchronous projections 
Replaying events and building read models can be **CPU- or I/O-bound**. Many run a bounded thread pool (or partition-based workers) to avoid overwhelming DB/storage; pool size and partition count are key levers. 

## Scenario-4 High-throughput event streaming with per-message work
High message rate x non-trivial work per message (e.g. transform, DB write) -> need **many concurrent workers**. Consumer thread pool (or Kafka consumer threads per partition) is the main concurrency knob. 

## Scenario-5 Exactly Once / Idempotent Processing with DB 
Dedup or state update per message usually involves **blocking DB calls**. Each in-flight message often holds a thread until the DB round-trip completes; pool size caps concurrent processing. 

## Scenario-6 Rich routing with many in-process handlers 
Once event fan-out to **multiple handlers in the same process**; if handlers are blocking, each needs a thread. Total concurrency = sum of handler concurrencies or a shared pool-easy to under- or over-size. 

**Lower thread-pool dependency** (can rely more on event-loop / few threads): 

- **Simple event notification (fire-and-forget)** with trivial or fully async handlers
- **Choreography-based Saga** where each service only react with short, async work.
- **Pure pub/sub** with minimal processing (forward or light logic) and async I/O.

**Practical takeaway**: When you have **blocking I/O per message**, **orchestration with blocking calls**, **synchronous projections**, or **high throughput + non-trivial processing**, explicitly design and tune the **consumer/worker thread pool** (size, queue, rejection policy) and consider **backpressure** so the pool does not become the hidden bottleneck. 

