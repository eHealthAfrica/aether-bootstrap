#!/usr/bin/env bash
#
# Copyright (C) 2019 by eHealth Africa : http://www.eHealthAfrica.org
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

function gen_env_file {
    cat << EOF
#
# USE THIS ONLY LOCALLY
#
# This file was generated by "./scripts/generate_env_vars.sh" script.
#
# Variables in this file will be substituted into docker-compose-ZZZ.yml and
# are intended to be used exclusively for local deployment.
# Never deploy these to publicly accessible servers.
#
# Verify correct substitution with:
#
#   docker-compose config
#   docker-compose -f docker-compose-connect.yml config
#   docker-compose -f docker-compose-generation.yml config
#   docker-compose -f docker-compose-test.yml config
#
# If variables are newly added or enabled,
# please restart the images to pull in changes:
#
#   docker-compose restart {container-name}
#

# ------------------------------------------------------------------
# Releases
# ==================================================================
AETHER_VERSION=1.5.0
GATHER_VERSION=3.2.0
GATEWAY_VERSION=latest
KONG_VERSION=1.1
KEYCLOAK_VERSION=latest
CONFLUENTINC_VERSION=5.2.1
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Authorization & Authentication
# ==================================================================
KEYCLOAK_GLOBAL_ADMIN=admin
KEYCLOAK_GLOBAL_PASSWORD=password
KEYCLOAK_PG_PASSWORD=$(gen_random_string)
KONG_PG_PASSWORD=$(gen_random_string)

KEYCLOAK_INITIAL_USER_USERNAME=user
KEYCLOAK_INITIAL_USER_PASSWORD=password

KEYCLOAK_AETHER_CLIENT=aether
KEYCLOAK_KONG_CLIENT=kong
REALM_COOKIE=aether-realm

MULTITENANCY=true
DEFAULT_REALM=aether
PUBLIC_REALM=-
LOGIN_THEME=aether
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Routing
# ==================================================================
BASE_DOMAIN=${LOCAL_HOST}
BASE_PROTOCOL=http

# to be used in the aether containers
KEYCLOAK_SERVER_URL=http://${LOCAL_HOST}/auth/realms

KEYCLOAK_INTERNAL=http://keycloak:8080
KONG_INTERNAL=http://kong:8001

NETWORK_SUBNET=192.168.9.0/24
NETWORK_GATEWAY=192.168.9.1
KONG_IP=192.168.9.10
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Minio storage
# ==================================================================
MINIO_STORAGE_ACCESS_KEY=$(gen_random_string)
MINIO_STORAGE_SECRET_KEY=$(gen_random_string)

MINIO_INTERNAL=http://minio:9000
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether Kernel
# ==================================================================
KERNEL_ADMIN_USERNAME=admin
KERNEL_ADMIN_PASSWORD=adminadmin
KERNEL_ADMIN_TOKEN=$(gen_random_string)
KERNEL_DJANGO_SECRET_KEY=$(gen_random_string)
KERNEL_DB_PASSWORD=$(gen_random_string)

KERNEL_READONLY_DB_USERNAME=readonlyuser
KERNEL_READONLY_DB_PASSWORD=$(gen_random_string)

# TEST Aether Kernel
# ------------------------------------------------------------------
TEST_KERNEL_ADMIN_USERNAME=admin-test
TEST_KERNEL_ADMIN_PASSWORD=testingtesting
TEST_KERNEL_ADMIN_TOKEN=$(gen_random_string)
TEST_KERNEL_DJANGO_SECRET_KEY=$(gen_random_string)
TEST_KERNEL_DB_PASSWORD=$(gen_random_string)

TEST_KERNEL_READONLY_DB_USERNAME=readonlytest
TEST_KERNEL_READONLY_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether Producer
# ==================================================================
PRODUCER_ADMIN_USER=admin
PRODUCER_ADMIN_PW=adminadmin
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Kafka & Zookeeper
# ==================================================================
# internal users
KAFKA_ROOT_USER=root
KAFKA_ROOT_PW=$(gen_random_string)
ZK_ROOT_USER=zk-admin
ZK_ROOT_PW=$(gen_random_string)
# kafka all-tenant Superuser
KAFKA_SU_USER=master
KAFKA_SU_PW=adminadmin
# secret to generate tenant specific passwords
KAFKA_SECRET=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# ElasticSearch
# ==================================================================
# this is a pain to set dynamically, so we're using the default for dev
# https://aws.amazon.com/blogs/opensource/change-passwords-open-distro-for-elasticsearch/
ELASTIC_PASSWORD=admin
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether ODK Module
# ==================================================================
ODK_ADMIN_USERNAME=admin
ODK_ADMIN_PASSWORD=adminadmin
ODK_ADMIN_TOKEN=$(gen_random_string)
ODK_DJANGO_SECRET_KEY=$(gen_random_string)
ODK_DB_PASSWORD=$(gen_random_string)

# TEST Aether ODK Module
# ------------------------------------------------------------------
TEST_ODK_ADMIN_USERNAME=admin-test
TEST_ODK_ADMIN_PASSWORD=testingtesting
TEST_ODK_ADMIN_TOKEN=$(gen_random_string)
TEST_ODK_DJANGO_SECRET_KEY=$(gen_random_string)
TEST_ODK_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------


# ------------------------------------------------------------------
# Aether UI
# ==================================================================
UI_ADMIN_USERNAME=admin
UI_ADMIN_PASSWORD=adminadmin
UI_DJANGO_SECRET_KEY=$(gen_random_string)
UI_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# Gather
# ==================================================================
GATHER_ADMIN_USERNAME=admin
GATHER_ADMIN_PASSWORD=adminadmin
GATHER_DJANGO_SECRET_KEY=$(gen_random_string)
GATHER_DB_PASSWORD=$(gen_random_string)
# ------------------------------------------------------------------
EOF
}

check_openssl
RET=$?
if [ $RET -eq 1 ]; then
    echo "Please install 'openssl'  https://www.openssl.org/"
    exit 1
fi

set -Eeo pipefail

LOCAL_HOST=${LOCAL_HOST:-aether.local}

generate_new=yes
if [ -e ".env" ]; then
    echo "[.env] file already exists!"
    source .env

    # check localhost vs base domain
    if [ "$LOCAL_HOST" = "$BASE_DOMAIN" ]; then
        generate_new=no
        echo "  - Remove it if you want to generate new local credentials."
    else
        echo "  - Current domain [$LOCAL_HOST] differs from saved one [$BASE_DOMAIN], generating new credentials"
        mv ".env" ".env.${BASE_DOMAIN}"
    fi
fi

if [[ $generate_new = "yes" ]]; then
    gen_env_file > .env
    echo "[.env] file generated!"
fi


cat << EOF

Add to your

    /etc/hosts file (Linux / MacOS)

or

    C:\Windows\System32\Drivers\etc\hosts file (Windows)

the following line:

--------------------------------------------------------------------------------

127.0.0.1  ${LOCAL_HOST}

--------------------------------------------------------------------------------

EOF
