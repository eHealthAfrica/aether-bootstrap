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

# ------------------------------------------------------------------------------
# CHANGE THIS VALUE if you want a different host name
export LOCAL_HOST=aether.local
# ------------------------------------------------------------------------------

echo "-------------------------------------------------------"
echo "  Initialising installation for host: ${LOCAL_HOST}"
echo "-------------------------------------------------------"

./scripts/generate_env_vars.sh
source .env
source ./scripts/aether_functions.sh

DC_AUTH="docker-compose -f docker-compose-generation.yml"
AUTH_RUN="$DC_AUTH run --rm auth"


echo_message ""
echo_message "Initializing Aether environment, this will take about 60 seconds."
echo_message ""

# stop and remove all containers or the network cannot be recreated
./scripts/kill_all.sh
docker network rm aether_bootstrap_net || true

create_docker_assets

echo_message "Pulling docker images..."
docker-compose pull db minio keycloak kong
docker-compose -f docker-compose-connect.yml pull producer zookeeper kafka
$DC_AUTH pull auth
echo_message ""

start_db


echo_message "Preparing aether containers..."
# setup container (model migration, admin user, static content...)
CONTAINERS=( kernel ui odk )
for container in "${CONTAINERS[@]}"
do
    docker-compose pull $container
    docker-compose run --rm --no-deps $container setup
done
docker-compose run --rm --no-deps kernel eval python /code/sql/create_readonly_user.py
echo_message ""


# Initialize the kong & keycloak databases in the postgres instance

# THESE COMMANDS WILL ERASE PREVIOUS DATA!!!
rebuild_database kong     kong     ${KONG_PG_PASSWORD}
rebuild_database keycloak keycloak ${KEYCLOAK_PG_PASSWORD}
echo_message ""


echo_message "Preparing kong..."
#
# https://docs.konghq.com/install/docker/
#
# Note for Kong < 0.15: with Kong versions below 0.15 (up to 0.14),
# use the up sub-command instead of bootstrap.
# Also note that with Kong < 0.15, migrations should never be run concurrently;
# only one Kong node should be performing migrations at a time.
# This limitation is lifted for Kong 0.15, 1.0, and above.
docker-compose run --rm kong kong migrations bootstrap 2>/dev/null || true
docker-compose run --rm kong kong migrations up
echo_message ""
start_container kong $KONG_INTERNAL

$AUTH_RUN setup_auth
$AUTH_RUN register_app minio $MINIO_INTERNAL
echo_message ""


echo_message "Preparing keycloak..."
start_container keycloak "${KEYCLOAK_INTERNAL}/auth"

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
}

echo_message "Creating initial tenants/realms in keycloak..."
create_kc_tenant "dev"  "Local development"
create_kc_tenant "prod" "Production environment"
create_kc_tenant "test" "Testing playground"
echo_message ""

./scripts/kill_all.sh

echo_message ""
echo_message "Done!"
echo_message ""
