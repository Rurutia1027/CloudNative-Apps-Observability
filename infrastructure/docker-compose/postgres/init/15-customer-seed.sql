-- customer-service/src/main/resources/init-data.sql (aligned with payment + order tests)
INSERT INTO customer.customers(id, username, first_name, last_name)
VALUES ('d215b5f8-0249-4dc5-89a3-51fd148cfb41', 'user_1', 'First', 'User'),
       ('d215b5f8-0249-4dc5-89a3-51fd148cfb43', 'user_2', 'Second', 'User');

REFRESH MATERIALIZED VIEW customer.order_customer_m_view;
