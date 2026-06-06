-- Depends on outbox_status (70-order-schema.sql) and payment_status (50-payment-schema.sql).

CREATE TABLE IF NOT EXISTS "payment".order_outbox
(
    id             uuid                     NOT NULL,
    saga_id        uuid                     NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL,
    processed_at   TIMESTAMP WITH TIME ZONE,
    type           character varying        NOT NULL,
    payload        jsonb                    NOT NULL,
    outbox_status  outbox_status            NOT NULL,
    payment_status payment_status           NOT NULL,
    version        integer                  NOT NULL,
    CONSTRAINT order_outbox_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS payment_order_outbox_saga_status
    ON "payment".order_outbox (type, payment_status);

CREATE UNIQUE INDEX IF NOT EXISTS payment_order_outbox_saga_id_payment_status_outbox_status
    ON "payment".order_outbox (type, saga_id, payment_status, outbox_status);
