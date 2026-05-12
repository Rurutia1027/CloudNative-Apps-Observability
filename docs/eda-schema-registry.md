# Schema Registry: Metadata, On-Wire Format, Storage, and Update Timing

## Overview

With Confluent Schema Registry (as in this project's Docker stack) and Avro serializers, the registry holds schema
definitions and identifiers. Kafka holds serialized message bytes. Producers and consumers use a small binary header so
consumers know which schema to use when decoding.

## Main metadata on the registry

### Subject

A logical name for schema "linage", often tied to how values are registered (e.g., default naming like <topic-name>
-value for record values).

### Schema

The canonical schema text (for Avro, the JSON representation of the record definition). May include references to other
subjects.

### Schema ID

A global integer assigned when a schema is registered. Identical schema text typically maps to the same ID across
subjects.

### Version

A monotonic version per subject (v1, v2, ...). Registering new schema text under that subject creates a new version (if
compatibility checks pass).

### Compatibility mode

Per-subject or global rules (e.g., `BACKWARD`, `FULL`) controlling whether a new schema is allowed to be registered.

### Schema type

e.g., `AVRO`, `JSON`, `PROTOBUF` (in our project we use Avro)

The registry does not store every business message's payload. It stores how to interpret payloads that reference a given
schema ID.

## What actually travels in the Kafka message

It is not "raw Avro bytes only" and not the full schema JSON embedded in each message. The common Confluent wire format
for Avro-encoded values is:

- Magic byte -- usually, 0, marking the Confluent encoding.
- 4-byte schema ID -- big-endian integer; matches an entry in Schema Registry.
- Avro binary payload -- encoded according to the schema for that ID.

So the value is compact: 1 + 4 bytes of framing plus Avro-encoded fields. Consumers read the ID, resolve the schema (
from cache or registry), then deserialize the remainder.

If the key is an plain string, it may not use this framing; only Avro (or other registry-managed) keys do.

## Where serialized data lives

- Serialized business records: Kafka topic partitions (the log), durable and read by offset.
- Schema text, IDs, subject versions, config: Schema Registry's backing store -- in Confluent's typical deployment this
  is implemented on top of kafka via an internal topic (commonly `_schemas`), written and ready by the registry
  service -- not mixed into your application topics as the primary store.

Summary: application data bytes are in your topics; schema metadata is in **Schema Registry** (backed by its own Kafka
usage in the usual setup).

## When registry content is updated

Typical cases:

- Producer path -- First use of a schema for a subject, often with auto-registration enabled (or explicit registration
  in code): if the schema is new for that subject and passes compatibility, a new version is created and a schema ID is
  returned for subsequent encodings.
- Operational / CI -- HTTP API calls (e.g., register a schema before rolling out new consumers/producers).
- Administration -- Changing compatibility level, deleting subjects, imports/exports, etc.

Consumers generally do not write new schema versions to the registry when they deserialize; they fetch by ID (and cache
locally in memory, optionally with disk cache). Repeated messages with the same ID reuse the cached schema.

## One-line recap

Schema Registry holds subjects, versions, schema definitions, global IDs, and compatibility rules. Kafka holds message
bytes prefixed by magic + schema ID + Avro payload. Registry content updates when schemas are registered or admin rules
change, not on every consume.


---

# When Schemas Are Generated vs When They(schema metadata) Are Uploaded to Schema Registry

## Build Time (Maven): Java Only

The `avro-maven-plugin` runs in `generate-resources` / `compile` and turns `.avsc` files into Java `SpecifiedRecord`

## Runtime: Registration Happens When The Producer Serialize

Uploading a schema to Confluent Schema Registry happens while the application is running, when a producer serialize a
value with `KafkaAvroSerializer` (the value-serializer-class in our `application.yaml`):

- The serializer must resolve which schema applies and obtain a schema id
- If that schema is not yet registered for the target subject and auto-registration is allowed (Confluent property,
  `auto.register.schemas`, often `true` by default depending on serializer version), the client issues an HTTP call to
  the registry API, registers the schema, gets an id, then the payload (magic byte + id + Avro bytes) and sends it to
  Kafka.
- If the schema is already registered, the producer typically reuses the id (with local caching) and does not keep
  re-uploading the same definition.

Your `KafkaProducerConfig` sets `schema.registry.url` and the serializer classes but **does not** explicitly set
`auto.register.schemas`, so behavior follows the **Confluent serializer defaults** (in many setups used for courses, the
**first** produce to a topic/subject triggers registration).

Other common patterns (not wired as a build step in this repo):

- Pre-register schemas via REST/Confluent CLI / CI before deploy, then set `auto.register.schemas=false` so nly approved
  schemas exists.
- Ops scripts that register schemas independently of app startup.

## One-line Summary

**Build** = generate Java from `.avsc` only.
**Registry** = uploaded at runtime, usually when the producer first serialize an Avro message (if auto-register is on),
or earlier if you register schemas explicitly.


---

# Schema Registry Storage

Schema Registry is not a general-purpose database and not LevelDB by default. It is a stateful HTTP service (the
Confluent `schema-registry` process). In the default deployment, it persists metadata in Kafka using an internal
compacted topic (commonly named `_schemas`). Compaction keeps the latest value per key, which fits a "current catalog of
schemas" model. The service loads and indexes that log in memory and serves REST lookups (by subject/version/id).
Managed cloud offerings may hide the backend, but the idea is the same: **central schema metadata + id for serializers
**.

## Small "code fraction": metadata , wire format, Kafka, Consume

Below is illustrative pseudocode to show the flow end-to-end.

### Registry metadata (conceptual shape after registration)

```json
{
  "subject": "payment-request-value",
  "schemaId": 42,
  "version": 1,
  "schemaType": "AVRO",
  "schema": "{\"type\":\"record\",\"name\":\"DemoPayment\",\"fields\":[{\"name\":\"orderId\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"int\"}]}"
}
```

### Producer: build Avro bytes, prepend Confluent header, send to Kafka

```text
// Logical steps (producer) 
schemaJson = loadFromGeneratedModelOrFile(); // Avro schema text / SpecificRecord 
payloads = avroEncode(record, schemaJson); // compact binary AFTER the header 

magic = 0x00 ; // Confluent wire format 
schemaId = reigstry.registerOrLookup(schemaJson); // HTTP to Schema Registry on first use 


valueOnWire = contact(
    bytes(magic), // 1 byte 
    bigEndianUInt32(schemaId), // 4 bytes 
    payloadBytes // N bytes - Avro binary encoding of fields 
); 

kafkaProducer.send(topic="payment-request", key="saga-123", value=valueOnWire); 
```

On disk in Kafka: that same `valueOnWire` byte array is appended to the `payment-request partition log` (an append-only
log, not a classic "queue" API, though people say "queue" informally)

## Consumer: strip header, resolve schema, decode

```text
// Logical steps (consumer)
raw = kafkaConsumer.poll() ; // byte[] value from topic 

assert raw[0] == 0x00; 
id = readBigEndianUInt32(raw, 1); 
schema = register.getById(id); // HTTP once, then cache 
record = avroDecode(raw, 5, length(raw) - 5, schema); // payload starts at offset 5 

process(record.orderId, record.amount); 
```

## One-line picture of the value bytes

```text
Kafka record.value (byte[]) =
  [ 0x00 ][ schema id: 4 bytes BE ][ Avro-encoded field bytes ... ]
         \_______________________/
              framing (5 bytes)
```

## Summary

Registry holds subject/version/id + Avro schema text (default persistence on a Kafka compacted internal topic).
The business topic stores magic + id + Avro payload. The consumer uses id --> schema then decodes the remainder of the
value. 









