# Schema in Event-Driven Architecture

## What "schema" usually means in EDA

In event-driven systems, a schema is the machine-readable contract for a message on the wire: field names, types,
nesting, and often enums or optional. Conventional practice includes:

- Explicit formats -- Teams standardize on Avro, Protobuf, JSON Schema, or similar so producers and consumers agree on
  structure beyond ad hod JSON.
- Registry and versioning -- A schema registry stores each schema version; serializers register or fetch schemas by id
  so payloads stay small (often just an id + bytes) while remaining decodable.
- Compatibility rules -- Policies such as backward (new readers read old data) or forward (old readers read new data)
  gate schema changes in Ci or at registration time to avoid breaking consumers.
- Subject naming -- A convention for how registry entries map to topics (e.g., <topic>-value, or record-type-centric
  names), aligned with the broker's topic model.
- Evolution discipline -- Additive changes (new fields with defaults), careful enum changes, and documentation (e.g.,
  AsyncAPI) are normal complements to raw schema files.

EDA does not mandate a specific technology; it mandates clear, evolvable contracts when many services share streams.

## How this codebase implements it

### Technology Stack

- Apache Avro
- Code generation -- The `avro-maven-plugin` in `kafka-model` generates Java `SpecificRecord` types into `src/main/java`
  during `generate-source` (Java `String` for strings, `BigDecimal` for decimals via `enableDecimalLogicalType`).
- confluent Schema Registry -- Declared in Docker Compose (`schema-registry` on port `8081`); services set
  `schema.registry.url` and use `KafkaAvroSerializer` / matching deserialize so schemas are registered and resolved at
  runtime.

### Message types (records)

- `PaymentRequestAvroModel` : Order --> Payment
- `PaymentResponseAvroModel` : Payment --> Order
- `RestaurantApprovalRequestAvroModel`: Order --> Restaurant
- `RestaurantApprovalResponseAvroModel`: Restaurant --> Order
- CustomerAvroModel: Customer-related events

All share the namespace `com.food.ordering.system.kafka.order.avro.model`. Nested enums and arrays are defined inline in
the same `.avsc` files where needed.

Modeling conventions in `.avsc`

- Identifiers: `string` with `logicalType: "uuid"`
- Money: `bytes` with `logicalType: "uuid"`
- Timestamps: `long` with `logicalType: "timestamp-millis"`
- Lifecycle fields: Avro `enum` with an explicit symbol set.

### Topics

`init_kafka.yaml` creates topics:

- payment-request
- payment-response
- restaurant-approval-request
- restaurant-approval-response
- consumer

Each topic is used with the corresponding Avro type in application code; the registry subject name follows Confluent
default unless overridden (typically tied to topic and value).

### Architectural Patterns

A single Maven module `kafka-model` is depended on by all services, giving one shard contract artifact--simple for
monorepo or course-style repo; in larger organizations the same ideas often appear as a published schema package or
registry-only workflow. ¬

## Summary

Industry EDA usage treats schema as the versioned, registry-backed contract for events. This project implements that
with Avro + Schema Registry + generated java types and topic message-type alignment enforced by convention and code. 






