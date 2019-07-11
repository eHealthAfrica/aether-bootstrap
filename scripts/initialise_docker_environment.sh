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

source ./scripts/aether_functions.sh

echo_message ""
echo_message "Initializing installation for host: ${LOCAL_HOST}"
echo_message ""

./scripts/generate_env_vars.sh
source .env
source ./scripts/aether_functions.sh
kafka/make_credentials.sh

echo_message ""
echo_message "Initializing Aether environment,"
echo_message " this may take 15 minutes depending on bandwidth."
echo_message ""

# stop and remove all containers or the network cannot be recreated
./scripts/kill_all.sh
docker network rm aether_bootstrap_net || true

create_docker_assets

echo_message "Pulling docker images..."
docker-compose pull db minio keycloak kong
docker-compose -f docker-compose-connect.yml pull
$DC_AUTH pull auth
echo_message ""


echo_message "Starting Kafka & Zookeper containers..."
docker-compose -f docker-compose-connect.yml up -d zookeeper kafka


start_db
./scripts/setup_auth.sh


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

echo_message "Preparing kong..."
start_container kong $KONG_INTERNAL

$AUTH_RUN add_app keycloak
echo_message ""

echo_message "Creating Kafka Superuser..."
$AUTH_RUN add_kafka_su $KAFKA_SU_USER $KAFKA_SU_PASSWORD
$AUTH_RUN grant_kafka_su $KAFKA_ROOT_USER
echo_message ""

echo_message "Preparing keycloak..."
start_container keycloak $KEYCLOAK_INTERNAL

echo_message "Creating initial tenants/realms in keycloak..."
create_kc_tenant "dev"  "Local development"
create_kc_tenant "prod" "Production environment"
create_kc_tenant "test" "Testing playground"
echo_message ""

./scripts/kill_all.sh

echo_message ""
echo_message "Done!"
echo_message ""
