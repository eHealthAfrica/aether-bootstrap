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

source ./scripts/aether_functions.sh

DC_AUTH="docker-compose -f docker-compose-generation.yml"


echo ""
echo "========================================================================="
echo "    Initializing Aether environment, this will take about 60 seconds."
echo "========================================================================="
echo ""

# stop and remove all containers or the network cannot be recreated
$DC_AUTH kill
$DC_AUTH down
docker-compose kill
docker-compose down

create_docker_assets
source .env

echo "${LINE} Pulling docker images..."
docker-compose pull db minio
docker-compose -f docker-compose-connect.yml pull producer zookeeper kafka
echo ""

start_db


echo "${LINE} Preparing aether containers..."
# setup container (model migration, admin user, static content...)
CONTAINERS=( kernel ui odk )
for container in "${CONTAINERS[@]}"
do
    docker-compose pull $container
    docker-compose run --no-deps $container setup
done
docker-compose run --no-deps kernel eval python /code/sql/create_readonly_user.py
echo ""


# Initialize the kong & keycloak databases in the postgres instance

# THESE COMMANDS WILL ERASE PREVIOUS DATA!!!
rebuild_database kong     kong     ${KONG_PG_PASSWORD}
rebuild_database keycloak keycloak ${KEYCLOAK_PG_PASSWORD}
echo ""


echo "${LINE} Building custom docker images..."
docker-compose build --no-cache --force-rm --pull keycloak kong
$DC_AUTH       build --no-cache --force-rm --pull auth
echo ""


echo "${LINE} Preparing kong..."
#
# https://docs.konghq.com/install/docker/
#
# Note for Kong < 0.15: with Kong versions below 0.15 (up to 0.14),
# use the up sub-command instead of bootstrap.
# Also note that with Kong < 0.15, migrations should never be run concurrently;
# only one Kong node should be performing migrations at a time.
# This limitation is lifted for Kong 0.15, 1.0, and above.
docker-compose run kong kong migrations bootstrap 2>/dev/null || true
docker-compose run kong kong migrations up
echo ""
start_kong


echo "${LINE} Registering keycloak and minio in kong..."
$DC_AUTH run auth setup_auth
echo ""


echo "${LINE} Preparing keycloak..."
start_keycloak
connect_to_keycloak

function create_kc_tenant {
    REALM=$1
    DESC=${2:-$REALM}

    create_kc_realm          $REALM $DESC
    create_kc_aether_client  $REALM
    create_kc_kong_client    $REALM

    create_kc_user  $REALM \
                    $KEYCLOAK_INITIAL_USER_USERNAME \
                    $KEYCLOAK_INITIAL_USER_PASSWORD

    echo "${LINE} Adding [aether] solution in kong..."
    $DC_AUTH run auth add_solution aether $REALM
}

echo "${LINE} Creating initial tenants in keycloak..."
create_kc_tenant "dev"  "Local development"
create_kc_tenant "prod" "Production environment"
create_kc_tenant "test" "Testing playground"
echo ""

$DC_AUTH down
docker-compose kill
docker-compose down

echo ""
echo "========================================================================="
echo "                                 Done!"
echo "========================================================================="
echo ""
