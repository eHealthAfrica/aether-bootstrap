#!/usr/bin/env bash
#
# Copyright (C) 2018 by eHealth Africa : http://www.eHealthAfrica.org
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
set -Eeuo pipefail

source .env

CHECK_URL="docker-compose run --no-deps kernel manage check_url -u"
KC_URL="${KEYCLOAK_INTERNAL}/keycloak/auth"
LINE="__________________________________________________________________"
AETHER_APPS=( kernel odk ui )


function create_docker_assets {
    echo "${LINE} Generating docker network and database volume..."

    {
        docker network create aether_internal \
            --attachable \
            --subnet=${NETWORK_SUBNET} \
            --gateway=${NETWORK_GATEWAY}
    } || { # catch
        echo "aether_internal network is ready."
    }

    {
        docker volume create aether_database_data
    } || { # catch
        echo "aether_database_data volume is ready."
    }

    ./scripts/generate_env_vars.sh

    echo ""
}


function start_db {
    echo "${LINE} Starting database server..."
    docker-compose up -d db
    until docker-compose run --no-deps kernel eval pg_isready -q; do
        >&2 echo "Waiting for database..."
        sleep 2
    done
    echo ""
}


function start_kong {
    echo "${LINE} Starting kong server..."
    docker-compose up -d kong
    until $CHECK_URL $KONG_INTERNAL >/dev/null; do
        >&2 echo "Waiting for kong..."
        sleep 2
    done
    echo ""
}


function start_keycloak {
    echo "${LINE} Starting keycloak server..."
    docker-compose up -d keycloak
    until $CHECK_URL "$KC_URL" >/dev/null; do
        >&2 echo "Waiting for keycloak..."
        sleep 2
    done
    echo ""
}


# Usage:    rebuild_database <database> <user> <password>
function rebuild_database {
    DB_NAME=$1
    DB_USER=$2
    DB_PWD=$3

    DB_ID=$(docker-compose ps -q db)
    PSQL="docker container exec -i $DB_ID psql"

    echo "${LINE} Recreating $1 database..."

    # drops database (terminating any previous connection) and creates it again
    $PSQL <<- EOSQL
        UPDATE pg_database SET datallowconn = 'false' WHERE datname = '${DB_NAME}';
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';

        DROP DATABASE ${DB_NAME};
        DROP USER ${DB_USER};

        CREATE USER ${DB_USER} PASSWORD '${DB_PWD}';
        CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
EOSQL
}


# ------------------------------------------------------------------------------
# https://www.keycloak.org/docs/latest/server_admin/index.html#using-the-admin-cli
# ------------------------------------------------------------------------------

function connect_to_keycloak {
    KC_ID=$(docker-compose ps -q keycloak)
    export KCADM="docker container exec -i ${KC_ID} ./keycloak/bin/kcadm.sh"

    echo "${LINE} Connecting to keycloak server..."
    $KCADM \
        config credentials \
        --server ${KC_URL} \
        --realm master \
        --user "${KEYCLOAK_GLOBAL_ADMIN}" \
        --password "${KEYCLOAK_GLOBAL_PASSWORD}"
}


# Usage:    create_kc_realm <realm-name>
function create_kc_realm {
    REALM=$1

    echo "${LINE} Creating realm [${REALM}]..."
    $KCADM \
        create realms \
        -s realm="${REALM}" \
        -s displayName="${REALM} realm for the Aether Platform" \
        -s enabled=true
}


# Usage:    create_kc_aether_clients <realm-name>
function create_kc_aether_clients {
    REALM=$1

    echo "${LINE} Creating aether clients in realm [$REALM]..."
    for CLIENT in "${AETHER_APPS[@]}"; do
        CLIENT_URL="${BASE_HOST}/${REALM}/${CLIENT}/"
        REDIRECT_URI="${BASE_HOST}/${PUBLIC_REALM}/${CLIENT}/accounts/login/"

        echo "${LINE} Creating client [${CLIENT}] in realm [$REALM]..."
        $KCADM \
            create clients \
            -r "${REALM}" \
            -s clientId="${CLIENT}" \
            -s publicClient=true \
            -s directAccessGrantsEnabled=true \
            -s rootUrl="${CLIENT_URL}" \
            -s baseUrl="${CLIENT_URL}" \
            -s 'redirectUris=["'${REDIRECT_URI}'"]' \
            -s enabled=true
    done
}

# Usage:    create_kc_kong_client <realm-name>
function create_kc_kong_client {
    REALM=$1

    echo "${LINE} Creating client [${KEYCLOAK_KONG_CLIENT}] in realm [$REALM]..."
    CLIENT_URL="${BASE_HOST}/${REALM}/"

    $KCADM \
        create clients \
        -r "${REALM}" \
        -s clientId="${KEYCLOAK_KONG_CLIENT}" \
        -s publicClient=false \
        -s clientAuthenticatorType=client-secret \
        -s directAccessGrantsEnabled=true \
        -s rootUrl="${CLIENT_URL}" \
        -s baseUrl="${CLIENT_URL}" \
        -s 'redirectUris=["*"]' \
        -s enabled=true
}


# Usage:    create_kc_user <realm-name> <username> [<password>]
function create_kc_user {
    REALM=$1
    USERNAME=$2
    PASSWORD=${3:-}

    echo "${LINE} Creating user [$USERNAME] in realm [$REALM]..."
    $KCADM \
        create users \
        -r "${REALM}" \
        -s username="${USERNAME}" \
        -s enabled=true

    if [ ! -z "${PASSWORD}" ]; then
        $KCADM \
            set-password \
            -r "${REALM}" \
            --username "${USERNAME}" \
            --new-password="${PASSWORD}"
    fi
}
