cloud-native-eda-lab — Docker Postgres (customer + order only)
==============================================================

Scripts (run in name order on FIRST start of an empty data volume):

  10-customer-schema.sql  — from customer-service/src/main/resources/init-schema.sql
  20-customer-seed.sql    — from customer-service/src/main/resources/init-data.sql
  30-order-schema.sql     — from order-service/order-container/src/main/resources/init-schema.sql

When this Postgres is used locally:

  export SPRING_PROFILES_ACTIVE=docker

  - customer-service loads application-docker.yml (disables classpath schema + data init).
  - order-service loads application-docker.yml (ready for when you add schema init to application.yaml).

If you change init-schema.sql or init-data.sql in the repo, update the matching file under postgres/init/.
