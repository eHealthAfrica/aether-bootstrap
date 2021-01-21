#!/usr/bin/env bash
#
# Copyright (C) 2020 by eHealth Africa : http://www.eHealthAfrica.org
#
# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# This script can be used to generate an ".env" for local development with
# docker compose.
#
# Example:
# ./scripts/generate_env_vars.sh

function check_openssl {
    which openssl > /dev/null
}

function gen_random_string {
    openssl rand -hex 16 | tr -d "\n"
}

function kafka_settings {
    local kafka_consumer_pw=$(gen_random_string)

    if [ "$AETHER_CONNECT_MODE" = "CONFLUENT" ]; then
        cat << EOF1
# Confluent Cloud setup
# ------------------------------------------------------------------
KAFKA_URL=${CC_URL}
KAFKA_SECURITY=SASL_SSL
# default number of replicas to maintain
KAFKA_REPLICAS=3

# kafka all-tenant Superuser
KAFKA_SU_USER=${CC_SU_USER}
KAFKA_SU_PASSWORD=${CC_SU_PASSWORD}

# kafka consumer user
KAFKA_CONSUMER_USER=${CC_SU_USER}
KAFKA_CONSUMER_PASSWORD=${CC_SU_PASSWORD}

# # Local setup
# # ------------------------------------------------------------------
# KAFKA_URL=kafka:29092
# KAFKA_SECURITY=SASL_PLAINTEXT
# # default number of replicas to maintain
# KAFKA_REPLICAS=1

# # kafka all-tenant Superuser
# KAFKA_SU_USER=master
# KAFKA_SU_PASSWORD=${admin_password}

# # kafka consumer user
# KAFKA_CONSUMER_USER=root
# KAFKA_CONSUMER_PASSWORD=${kafka_consumer_pw}
EOF1
    else
        cat << EOF2
# # Confluent Cloud setup
# # ------------------------------------------------------------------
# KAFKA_URL=${CC_URL}
# KAFKA_SECURITY=SASL_SSL
# # default number of replicas to maintain
# KAFKA_REPLICAS=3

# # kafka all-tenant Superuser
# KAFKA_SU_USER=${CC_SU_USER}
# KAFKA_SU_PASSWORD=${CC_SU_PASSWORD}

# # kafka all-tenant Superuser
# KAFKA_CONSUMER_USER=${CC_SU_USER}
# KAFKA_CONSUMER_PASSWORD=${CC_SU_PASSWORD}

# Local setup
# ------------------------------------------------------------------
KAFKA_URL=kafka:29092
KAFKA_SECURITY=SASL_PLAINTEXT
# default number of replicas to maintain
KAFKA_REPLICAS=1

# kafka all-tenant Superuser
KAFKA_SU_USER=master
KAFKA_SU_PASSWORD=${admin_password}

# kafka consumer user
KAFKA_CONSUMER_USER=root
KAFKA_CONSUMER_PASSWORD=${kafka_consumer_pw}
EOF2
fi
}

function gen_env_file {
    user_password="${SERVICES_DEFAULT_USER_PASSWORD:-password}"
    admin_password="${SERVICES_DEFAULT_ADMIN_PASSWORD:-adminadmin}"

    IFS=';' read -a tenants <<< "$INITIAL_TENANTS"
    for tenant in "${tenants[@]}"; do
        DEFAULT_REALM=$tenant
        break
    done

    cat << EOF
#
# USE THIS ONLY LOCALLY
#
# This file was generated by "./scripts/generate_env_vars.sh" script.
#
# Variables in this file will be substituted into {module}/docker-compose.yml and
# are intended to be used exclusively for local deployment.
# Never deploy these to publicly accessible servers.
#
# Verify correct substitution with:
#
#   docker-compose -f {module}/docker-compose.yml config
#
# If variables are newly added or enabled,
# please restart the images to pull in changes:
#
#   docker-compose -f {module}/docker-compose.yml restart {container-name}
#

# ------------------------------------------------------------------
# Releases
# ==================================================================
AETHER_VERSION=1.7.11
GATHER_VERSION=3.4.5

GATEWAY_VERSION=0.0.4
KONG_VERSION=2.0
KEYCLOAK_VERSION=12.0.1

CONFLUENTINC_VERSION=5.5.3
KAFKA_VIEWER_VERSION=latest
KAFKACAT_VERSION=1.5.0

AMAZON_ES_VERSION=1.12.0
ES_CONSUMER_VERSION=2.2.6

CKAN_VERSION=2.8.4
CKAN_SOLR_VERSION=8.4.0
CKAN_CONSUMER_VERSION=1.0.2

POSTGRES_VERSION=13-alpine
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Authorization & Authentication
# ==================================================================
KEYCLOAK_GLOBAL_ADMIN=${KEYCLOAK_GLOBAL_ADMIN:-admin}
KEYCLOAK_GLOBAL_PASSWORD=${admin_password}
KEYCLOAK_PG_PASSWORD=$(gen_random_string)
KONG_PG_PASSWORD=$(gen_random_string)
KONGA_PG_PASSWORD=$(gen_random_string)

KEYCLOAK_PUBLIC_CLIENT=${KEYCLOAK_PUBLIC_CLIENT:-aether}
KEYCLOAK_OIDC_CLIENT=${KEYCLOAK_OIDC_CLIENT:-kong}

DEFAULT_LOGIN_THEME=${KEYCLOAK_LOGIN_THEME:-ehealth}
AETHER_LOGIN_THEME=${AETHER_LOGIN_THEME:-aether}
GATHER_LOGIN_THEME=${GATHER_LOGIN_THEME:-aether}

INITIAL_SU_USERNAME=${INITIAL_SU_USERNAME:-sys-admin}
INITIAL_SU_PASSWORD=${admin_password}

INITIAL_ADMIN_USERNAME=${INITIAL_ADMIN_USERNAME:-admin}
INITIAL_ADMIN_PASSWORD=${user_password}

INITIAL_USER_USERNAME=${INITIAL_USER_USERNAME:-user}
INITIAL_USER_PASSWORD=${user_password}

MULTITENANCY=true
DEFAULT_REALM=${DEFAULT_REALM:-aether}
PUBLIC_REALM=-
REALM_COOKIE=aether-realm
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Routing
# ==================================================================
BASE_DOMAIN=${LOCAL_HOST}
BASE_PROTOCOL=${BASE_PROTOCOL:-http}

# to be used in the aether containers
KEYCLOAK_SERVER_URL=${BASE_PROTOCOL:-http}://${LOCAL_HOST}/auth/realms

KEYCLOAK_HOST=http://keycloak:8080
KEYCLOAK_INTERNAL=http://keycloak:8080/auth
KONG_INTERNAL=http://kong:8001

NETWORK_SUBNET=192.168.9.0/24
KONG_IP=192.168.9.10
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Databases
# ==================================================================
REDIS_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Minio storage
# ==================================================================
# https://github.com/minio/minio/blob/master/docs/config/README.md#rotating-encryption-with-new-credentials
MINIO_STORAGE_ACCESS_KEY=minio-access-key
MINIO_STORAGE_SECRET_KEY=minio-secret-key

MINIO_ENDPOINT=minio:9100
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether Kernel
# ==================================================================
KERNEL_ADMIN_USERNAME=admin
KERNEL_ADMIN_PASSWORD=${admin_password}
KERNEL_ADMIN_TOKEN=$(gen_random_string)
KERNEL_DJANGO_SECRET_KEY=$(gen_random_string)
KERNEL_DB_PASSWORD=$(gen_random_string)

# TEST Aether Kernel
# ------------------------------------------------------------------
TEST_KERNEL_ADMIN_USERNAME=admin-test
TEST_KERNEL_ADMIN_PASSWORD=testingtesting
TEST_KERNEL_ADMIN_TOKEN=$(gen_random_string)
TEST_KERNEL_DJANGO_SECRET_KEY=$(gen_random_string)
TEST_KERNEL_DB_PASSWORD=$(gen_random_string)

TEST_KERNEL_CLIENT_USERNAME=user-test
TEST_KERNEL_CLIENT_PASSWORD=$(gen_random_string)
TEST_KERNEL_CLIENT_REALM=test
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether Producer
# ==================================================================
PRODUCER_ADMIN_USER=admin
PRODUCER_ADMIN_PASSWORD=${admin_password}
PRODUCER_DB_PASSWORD=$(gen_random_string)

# TEST Aether Producer
# ------------------------------------------------------------------
TEST_PRODUCER_ADMIN_USER=admin-test
TEST_PRODUCER_ADMIN_PASSWORD=testingtesting
TEST_PRODUCER_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Kafka & Zookeeper
# ==================================================================
# General Settings

$(kafka_settings)

# secret to generate tenant specific passwords
KAFKA_SECRET=$(gen_random_string)

# ZK settings
ZOOKEEPER_ROOT_USER=zk-admin
ZOOKEEPER_ROOT_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Confluent Cloud Admin (optional)
# ==================================================================
CC_API_USER=${CC_API_USER}
CC_API_PASSWORD=${CC_API_PASSWORD}
CC_CLUSTER_NAME=${CC_CLUSTER_NAME}
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# ElasticSearch
# ==================================================================
# this is a pain to set dynamically, so we're using the default for dev
# https://aws.amazon.com/blogs/opensource/change-passwords-open-distro-for-elasticsearch/
ELASTICSEARCH_PASSWORD=admin
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether ODK Module
# ==================================================================
ODK_ADMIN_USERNAME=admin
ODK_ADMIN_PASSWORD=${admin_password}
ODK_ADMIN_TOKEN=$(gen_random_string)
ODK_DJANGO_SECRET_KEY=$(gen_random_string)
ODK_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether UI
# ==================================================================
UI_ADMIN_USERNAME=admin
UI_ADMIN_PASSWORD=${admin_password}
UI_DJANGO_SECRET_KEY=$(gen_random_string)
UI_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Gather
# ==================================================================
GATHER_ADMIN_USERNAME=admin
GATHER_ADMIN_PASSWORD=${admin_password}
GATHER_DJANGO_SECRET_KEY=$(gen_random_string)
GATHER_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# CKAN
# ==================================================================
CKAN_DATASTORE_READONLY_PASSWORD=$(gen_random_string)
CKAN_SYSADMIN_NAME=admin
CKAN_SYSADMIN_PASSWORD=adminadmin
CKAN_SYSADMIN_EMAIL=info@ehealthafrica.org
CKAN_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# PERFORMANCE TESTS
# ==================================================================
TEST_REALM=_test_
TEST_WORKERS=5
TEST_NUMBER_OF_USERS=20
# ------------------------------------------------------------------
EOF
}

check_openssl
RET=$?
if [ $RET -eq 1 ]; then
    echo -e "\033[91mPlease install 'openssl'  https://www.openssl.org/\033[0m"
    exit 1
fi

set -Eeo pipefail

source options.txt || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )

LOCAL_HOST=${LOCAL_HOST:-aether.local}

generate_new=yes
if [ -e ".env" ]; then
    echo -e "\033[93m[.env] file already exists!\033[0m"
    source .env

    # check localhost vs base domain
    if [ "$LOCAL_HOST" = "$BASE_DOMAIN" ]; then
        generate_new=no
        echo "Remove it if you want to generate new local credentials."
    else
        echo -e "Current domain \033[1m[$LOCAL_HOST]\033[0m differs from saved one \033[1m[$BASE_DOMAIN]\033[0m, generating new credentials"
        mv ".env" ".env.${BASE_DOMAIN}"
    fi
fi

if [[ $generate_new = "yes" ]]; then
    gen_env_file > .env
    echo -e "\033[92m[.env] file generated!\033[0m"
fi


cat << EOF

Add to your

    [/etc/hosts] file (Linux / MacOS)

or

    [C:\Windows\System32\Drivers\etc\hosts] file (Windows)

the following line:

--------------------------------------------------------------------------------

127.0.0.1  ${LOCAL_HOST}

--------------------------------------------------------------------------------

EOF
