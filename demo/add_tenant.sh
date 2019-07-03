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
set -Eeuo pipefail

source .env
source ./scripts/aether_functions.sh

echo_message "Adding tenant $1..."
echo_message "Starting kong..."
start_container kong $KONG_INTERNAL
echo_message "Starting keycloak..."
start_container keycloak "${KEYCLOAK_INTERNAL}/auth"
echo_message "Starting other services..."
demo/up.sh
echo_message "Waiting for other services..."
sleep 20

DC_AUTH="docker-compose -f docker-compose-generation.yml"
AUTH_RUN="$DC_AUTH run --rm auth"

function create_kc_tenant {
    REALM=$1
    DESC=${2:-$REALM}

    $AUTH_RUN add_realm \
        $REALM \
        "$DESC" \
        $LOGIN_THEME

    $AUTH_RUN add_public_client \
        $REALM \
        $KEYCLOAK_AETHER_CLIENT

    $AUTH_RUN add_oidc_client \
        $REALM \
        $KEYCLOAK_KONG_CLIENT

    $AUTH_RUN add_user \
        $REALM \
        $KEYCLOAK_INITIAL_USER_USERNAME \
        $KEYCLOAK_INITIAL_USER_PASSWORD

    $AUTH_RUN add_solution aether $REALM $KEYCLOAK_KONG_CLIENT

    $AUTH_RUN add_kafka_tenant $REALM
}

function add_es_tenant {
    REALM=$1
    echo_message "Adding [kibana] service in kong..."
    $AUTH_RUN add_service kibana $REALM $KEYCLOAK_KONG_CLIENT
    $AUTH_RUN add_elasticsearch_tenant $REALM
}

function add_gather_tenant {
    REALM=$1
    echo_message "Adding [gather] solution in kong..."
    $AUTH_RUN add_solution gather $REALM $KEYCLOAK_KONG_CLIENT
}

echo_message "Creating initial tenants/realms in keycloak..."
create_kc_tenant "$1"  "Realm: $1"
add_es_tenant "$1"
add_gather_tenant "$1"
