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

function create_docker_assets {
    docker network create aether_internal      2>/dev/null || true
    docker volume  create aether_database_data 2>/dev/null || true

    ./scripts/generate_env_vars.sh
}


# Usage:    rebuild_db <database> <user> <password>
function rebuild_db {
    DB_NAME=$1
    DB_USER=$2
    DB_PWD=$3

    DB_ID=$(docker-compose ps -q db)
    PSQL="docker container exec -i $DB_ID psql"

    echo "_________________________________________________________________ Recreating $1 database..."

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


# Usage:    create_kc_realm <realm-name>
function create_kc_realm {
    REALM=$1

    # default credentials
    USERNAME=user
    PASSWORD=password

    KC_ID=$(docker-compose ps -q keycloak)
    KCADM="docker container exec -i ${KC_ID} ./keycloak/bin/kcadm.sh"

    # https://www.keycloak.org/docs/latest/server_admin/index.html#using-the-admin-cli

    KC_URL="http://localhost:8080/keycloak/auth/"

    echo "_________________________________________________________________ Connecting to keycloak server..."
    $KCADM \
        config credentials \
        --server ${KC_URL} \
        --realm master \
        --user ${KEYCLOAK_GLOBAL_ADMIN} \
        --password ${KEYCLOAK_GLOBAL_PASSWORD}

    echo "_________________________________________________________________ Creating realm  ${REALM}..."
    $KCADM \
        create realms \
        -s realm=${REALM} \
        -s enabled=true

    echo "_________________________________________________________________ Creating default clients..."
    CLIENTS=( kernel odk ui )
    for CLIENT in "${CLIENTS[@]}"; do
        _create_kc_client $REALM $CLIENT
    done

    echo "_________________________________________________________________ Creating client  ${REALM}-oidc..."
    CLIENT_URL="http://aether.local/${REALM}/"
    $KCADM \
        create clients \
        -r ${REALM} \
        -s clientId="${REALM}-oidc" \
        -s publicClient=true \
        -s directAccessGrantsEnabled=true \
        -s rootUrl=${CLIENT_URL} \
        -s baseUrl=${CLIENT_URL} \
        -s 'redirectUris=["/*/accounts/login/"]' \
        -s enabled=true

    _create_kc_role $REALM admin "Administrator privileges"
    _create_kc_user $REALM admin password admin

    _create_kc_role $REALM user "User privileges"
    _create_kc_user $REALM user password user

    echo "_________________________________________________________________ Adding solution in kong..."
    docker-compose run auth add_solution aether $REALM

    echo "_________________________________________________________________ ${REALM} ready!"
}


function _create_kc_client {
    REALM=$1
    CLIENT=$2

    CLIENT_URL="http://aether.local/${REALM}/${CLIENT}"
    echo "_________________________________________________________________ Creating client  ${CLIENT}..."
    $KCADM \
        create clients \
        -r ${REALM} \
        -s clientId=${CLIENT} \
        -s publicClient=true \
        -s directAccessGrantsEnabled=true \
        -s rootUrl=${CLIENT_URL} \
        -s baseUrl=${CLIENT_URL} \
        -s 'redirectUris=["/accounts/login/"]' \
        -s enabled=true
}


function _create_kc_role {
    REALM=$1
    NAME=$2
    DES=$3

    echo "_________________________________________________________________ Creating role  $NAME..."
    kcadm.sh \
        create roles \
        -r ${REALM} \
        -s name=$NAME \
        -s description="$DES"
}


function _create_kc_user {
    REALM=$1
    USERNAME=$2
    PASSWORD=$3
    ROLE=$4

    KC_ID=$(docker-compose ps -q keycloak)
    KCADM="docker container exec -i ${KC_ID} ./keycloak/bin/kcadm.sh"

    echo "_________________________________________________________________ Creating user  $USERNAME..."
    $KCADM \
        create users \
        -r ${REALM} \
        -s username=${USERNAME} \
        -s enabled=true

    $KCADM \
        set-password \
        -r ${REALM} \
        --username ${USERNAME} \
        --new-password=${PASSWORD}

    $KCADM \
        add-roles \
        -r ${REALM} \
        --uusername ${USERNAME} \
        --rolename=${ROLE}
}
