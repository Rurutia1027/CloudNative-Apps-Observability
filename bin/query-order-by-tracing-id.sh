#!/bin/bash

curl -sS 'http://localhost:18081/orders/1459e832-0060-48d6-9990-8de41936ca7a' \
  -H 'Accept: application/vnd.api.v1+json'



#  # curl -sS 'http://localhost:18081/orders/c79ad5c6-df6e-4674-a827-e80cf36d53ab' \
#    -H 'Accept: application/vnd.api.v1+json'
#  {"orderTrackingId":"c79ad5c6-df6e-4674-a827-e80cf36d53ab","orderStatus":"PENDING","failureMessage":[]}%