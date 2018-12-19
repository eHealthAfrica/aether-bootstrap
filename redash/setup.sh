#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 18.04.
set -eu

create_config() {
    
    COOKIE_SECRET=$(pwgen -1s 32)
    POSTGRES_PASSWORD=$(pwgen -1s 32)
    REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> ./.env
    echo "REDASH_LOG_LEVEL=INFO" >> ./.env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> ./.env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> ./.env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> ./.env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> ./.env
}

create_config

docker-compose run server python ./manage.py database create_tables
docker-compose kill