-- Backup copy. Canonical local DB init: infrastructure/docker-compose/postgres/init/
-- Customer IDs match payment init-data and order-service tests (d215b5f8-...cfb41 / cfb43).
INSERT INTO customer.customers(id, username, first_name, last_name)
VALUES ('d215b5f8-0249-4dc5-89a3-51fd148cfb41', 'user_1', 'First', 'User'),
       ('d215b5f8-0249-4dc5-89a3-51fd148cfb43', 'user_2', 'Second', 'User');
