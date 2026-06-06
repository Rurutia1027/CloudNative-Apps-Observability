-- Ensures order schema objects exist before test data inserts.
-- Each statement ends with a double-semicolon (see OrderPaymentSagaTest @SqlConfig).

CREATE SCHEMA IF NOT EXISTS "order";;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('PENDING', 'PAID', 'APPROVED', 'CANCELLED', 'CANCELLING');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;;

DO $$ BEGIN
    CREATE TYPE saga_status AS ENUM ('STARTED', 'FAILED', 'SUCCEEDED', 'PROCESSING', 'COMPENSATING', 'COMPENSATED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;;

DO $$ BEGIN
    CREATE TYPE outbox_status AS ENUM ('STARTED', 'COMPLETED', 'FAILED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;;

CREATE TABLE IF NOT EXISTS "order".orders
(
    id               uuid           NOT NULL,
    customer_id      uuid           NOT NULL,
    restaurant_id    uuid           NOT NULL,
    tracking_id      uuid           NOT NULL,
    price            numeric(10, 2) NOT NULL,
    order_status     order_status   NOT NULL,
    failure_messages character varying,
    CONSTRAINT orders_pkey PRIMARY KEY (id)
);;

CREATE TABLE IF NOT EXISTS "order".order_items
(
    id         bigint         NOT NULL,
    order_id   uuid           NOT NULL,
    product_id uuid           NOT NULL,
    price      numeric(10, 2) NOT NULL,
    quantity   integer        NOT NULL,
    sub_total  numeric(10, 2) NOT NULL,
    CONSTRAINT order_items_pkey PRIMARY KEY (id, order_id)
);;

CREATE TABLE IF NOT EXISTS "order".order_address
(
    id          uuid              NOT NULL,
    order_id    uuid UNIQUE       NOT NULL,
    street      character varying NOT NULL,
    postal_code character varying NOT NULL,
    city        character varying NOT NULL,
    CONSTRAINT order_address_pkey PRIMARY KEY (id, order_id)
);;

CREATE TABLE IF NOT EXISTS "order".payment_outbox
(
    id            uuid                     NOT NULL,
    saga_id       uuid                     NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL,
    processed_at  TIMESTAMP WITH TIME ZONE,
    type          character varying        NOT NULL,
    payload       jsonb                    NOT NULL,
    outbox_status outbox_status            NOT NULL,
    saga_status   saga_status              NOT NULL,
    order_status  order_status             NOT NULL,
    version       integer                  NOT NULL,
    CONSTRAINT payment_outbox_pkey PRIMARY KEY (id)
);;

CREATE INDEX IF NOT EXISTS payment_outbox_saga_status
    ON "order".payment_outbox (type, outbox_status, saga_status);;

CREATE UNIQUE INDEX IF NOT EXISTS payment_outbox_saga_id
    ON "order".payment_outbox (type, saga_id, saga_status);;
