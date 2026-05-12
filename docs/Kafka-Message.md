# Kafka Message Payload (Transport)

When you produce an event to Kafka using Avro + Schema Registry, the message on the wire is usually binary, not JSON.
Here is how it typically looks:

```text
+---------------------+--------------------------+------------------+
| Magic Byte (1 byte) | Schema ID (4 bytes)     | Serialized Data  |
+---------------------+--------------------------+------------------+
```

## Details

### Magic Byte (1 Byte)

Constant, usually 0, indicates that the message uses Confluent wire format.

### Schema ID (4 bytes, big-endian)

- This is the ID of the Avro schema stored in the Schema Registry.
- Consumers use this ID to fetch the correct schema for deserialization.

### Serialized Data

- The actual event payload, serialized according to Avro rules (fields in binary).
- Only the fields defined in the schema are present.

Important:

- The event ID, timestamp, and other metadata are usually part of the Avro payload itself, not Kafka headers (though
  headers can also be used).
- Kafka headers can carry additional info (like `correlationId`, `causationId`, `traceIDs`, message type, tc), but the
  schema definition lives in the registry, not in headers. 

## Kafka Headers 
- Headers are optional key-value pairs (strings or bytes) per message. 
- Common industrial usage:

## Customer Flow 
- Consumer reads Kafka message (bytes) + optional headers. 
- Reads **Schema ID** from the first 4 bytes. 
- Fetches the Avro schema from **Schema Registry** (or uses cached version).
- Deserializes the remaining bytes into a **typed object**.

## Example 
Suppose we have an `OrderCreatedEvent`

```json
{
  "type": "record",
  "name": "OrderCreated",
  "namespace": "com.example.order",
  "fields": [
    {
      "name": "eventId",
      "type": "string"
    },
    {
      "name": "orderId",
      "type": "string"
    },
    {
      "name": "occurredAt",
      "type": "string"
    },
    {
      "name": "customerId",
      "type": "string"
    }
  ]
}
```

### On Kafka wire 
```text
[Magic Byte=0] [Schema ID=1234] [Avro Binary Serialized Data]
```


### Optional headers (Kafka message headers)
```text
"correlationId" = "abc-uuid"
"causationId" = "cmd-uuid"
```

## Key Takeaways 
- Schema = only in Schema Registry 
- Kafka message = bytes + schema ID + optional headers 
- Headers are for metadata / tracing; payload is the actual event serialized 
- This separation allows independent evolution of schemas without breaking consumers. 

