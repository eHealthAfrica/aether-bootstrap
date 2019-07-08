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

# just check that the scripts work
source ./scripts/aether_functions.sh

echo_message "Set up tests"
./scripts/initialise_docker_environment.sh


source .env
DC="docker-compose -f ./docker-compose-test.yml"


# TODO: generate assets
echo_message "Assets tests [TBD]"
# ./scripts/kill_all.sh
# start_db
# start_container kong     $KONG_INTERNAL
# start_container keycloak "${KEYCLOAK_INTERNAL}/auth"
# start_container kernel   http://kernel:8000/health

# ./scripts/register_assets.sh
# ./scripts/generate_assets.sh 10


# TODO: integration tests
echo_message "Integration tests [TBD]"
# ./scripts/kill_all.sh
# ./scripts/integration_test_setup.sh
# $DC run --rm integration-test test

echo_message ""
echo_message "Done!"
echo_message ""
