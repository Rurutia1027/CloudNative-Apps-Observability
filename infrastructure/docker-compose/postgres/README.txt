cloud-native-eda-lab — Postgres Docker init (all services)
==========================================================

Scripts run in filename order on FIRST start only (empty ./volumes/postgres/data).

  10-customer-schema.sql
  15-customer-seed.sql      (IDs aligned with payment + order tests)
  30-restaurant-schema.sql  (creates shared public.outbox_status)
  40-restaurant-seed.sql
  50-payment-schema.sql     (no duplicate outbox_status)
  60-payment-seed.sql
  70-order-schema.sql

Source of truth for edits: update matching file here, then sync
  *-service/**/src/main/resources/init-schema.sql | init-data.sql as backup.

Start:
  cd infrastructure/docker-compose
  docker compose -f postgres.yml up -d

Apps:
  export SPRING_PROFILES_ACTIVE=docker

Re-apply SQL after changes:
  docker compose -f postgres.yml down -v
  docker compose -f postgres.yml up -d
