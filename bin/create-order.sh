#!/bin/bash

curl -sS -X POST 'http://localhost:18081/orders' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/vnd.api.v1+json' \
  -d '{
  "customerId": "d215b5f8-0249-4dc5-89a3-51fd148cfb41",
  "restaurantId": "d215b5f8-0249-4dc5-89a3-51fd148cfb45",
  "price": 200.00,
  "address": {
    "street": "street_1",
    "postalCode": "1000AB",
    "city": "Paris"
  },
  "items": [
    {
      "productId": "d215b5f8-0249-4dc5-89a3-51fd148cfb48",
      "quantity": 1,
      "price": 50.00,
      "subTotal": 50.00
    },
    {
      "productId": "d215b5f8-0249-4dc5-89a3-51fd148cfb48",
      "quantity": 3,
      "price": 50.00,
      "subTotal": 150.00
    }
  ]
}'



#{"orderTrackingId":"c79ad5c6-df6e-4674-a827-e80cf36d53ab","orderStatus":"PENDING","message":"Order Created Successfully"}%