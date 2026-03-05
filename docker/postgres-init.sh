#!/bin/bash
set -e
for db in customer fraud notification; do
  psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM pg_database WHERE datname = '$db'" | grep -q 1 \
    || psql -v ON_ERROR_STOP=1 --username "postgres" -c "CREATE DATABASE $db OWNER amigoscode"
done
