-- Synced from: customer-service/src/main/resources/init-data.sql
INSERT INTO customer.customers(id, username, first_name, last_name)
VALUES ('3f6f8d4e-9c2a-4b1a-8c7e-1a2b3c4d5e6f', 'user_1', 'First', 'User'),
       ('7a1c2b3d-5e6f-4a8b-9c0d-2e3f4a5b6c7d', 'user_2', 'Second', 'User'),
       ('9b2e4c6a-1d3f-4e7b-8a9c-0d1e2f3a4b5c', 'user_3', 'Third', 'User'),
       ('1c3d5e7f-8a9b-4c2d-0e1f-2a3b4c5d6e7f', 'user_4', 'Fourth', 'User');

REFRESH MATERIALIZED VIEW customer.order_customer_m_view;
