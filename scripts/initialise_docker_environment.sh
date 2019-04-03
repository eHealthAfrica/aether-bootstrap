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

echo ""
echo "================================================================="
echo "Initializing Aether environment, this will take about 60 seconds."
echo "================================================================="
echo ""

create_docker_assets
source .env

docker-compose kill

echo "_________________________________________________________________ Pulling docker images..."
docker-compose -f docker-compose-base.yml pull

echo "_________________________________________________________________ Starting database server..."
docker-compose up -d db
until docker-compose run --no-deps kernel eval pg_isready -q; do
    >&2 echo "Waiting for database..."
    sleep 2
done


echo "_________________________________________________________________ Preparing aether containers..."
# setup container (model migration, admin user, static content...)
CONTAINERS=( kernel ui odk )
for container in "${CONTAINERS[@]}"
do
    docker-compose run --no-deps $container setup
done
docker-compose run --no-deps kernel eval python /code/sql/create_readonly_user.py
echo ""


# Initialize the kong & keycloak databases in the postgres instance

# THESE COMMANDS WILL ERASE PREVIOUS DATA!!!
rebuild_db kong     kong     ${KONG_PG_PASSWORD}
rebuild_db keycloak keycloak ${KEYCLOAK_PG_PASSWORD}
echo ""


echo "_________________________________________________________________ Building custom docker images..."
docker-compose build auth keycloak kong
echo ""

CHECK_URL="docker-compose run --no-deps kernel manage check_url -u"


echo "_________________________________________________________________ Preparing keycloak..."
docker-compose up -d keycloak
until $CHECK_URL "$KEYCLOAK_INTERNAL/keycloak/auth/" >/dev/null; do
    >&2 echo "Waiting for keycloak..."
    sleep 2
done
echo ""

echo "_________________________________________________________________ Creating initial realms in keycloak..."
REALMS=( dev dev2 )
for REALM in "${REALMS[@]}"; do
    create_kc_realm $REALM
done
echo ""


echo "_________________________________________________________________ Preparing kong..."
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

docker-compose up -d kong
until $CHECK_URL $KONG_INTERNAL >/dev/null; do
    >&2 echo "Waiting for kong..."
    sleep 2
done
echo ""

echo "_________________________________________________________________ Registring keycloak in kong..."
docker-compose run auth setup_auth
echo ""


docker-compose kill

echo ""
echo "================================================================="
echo "Done."
echo "================================================================="
echo ""
