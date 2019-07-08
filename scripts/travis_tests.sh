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

./scripts/generate_env_vars.sh
./kafka/make_credentials.sh

source .env
source ./scripts/aether_functions.sh


case "$1" in

    setup )
        echo_message "Set up [Aether]..."
        ./scripts/initialise_docker_environment.sh || (
            echo_message "Set up [Aether] FAILED!!!" && exit 1
        )

        echo_message "Set up [Gather]..."
        ./gather/setup_gather.sh || (
            echo_message "Set up [Gather] FAILED!!!"
        )

        # ToBeFixed: ES
        echo_message "Set up [ElasticSearch]..."
        ./elasticsearch/setup.sh || (
            echo_message "Set up [ElasticSearch] FAILED!!!"
        )
    ;;

    ckan )
        echo_message "Start [Aether]..."
        start_db
        start_container kong     $KONG_INTERNAL
        start_container keycloak "${KEYCLOAK_INTERNAL}/auth"
        start_container kernel   http://kernel:8000/health

        echo_message "Start [CKAN]..."
        ./scripts/run_ckan.sh
        ./scripts/run_connect.sh


        ./scripts/register_assets.sh || (
            echo_message "Register assets FAILED!!!"
        )
        ./scripts/generate_assets.sh 1 || (
            echo_message "Generate assets FAILED!!!"
        )
    ;;

    integration )
        echo_message "Integration tests..."
        ./scripts/integration_test_setup.sh

        DC="docker-compose -f ./docker-compose-test.yml"
        $DC run --rm integration-test test || (
            echo_message "Integration tests FAILED!!!"
        )
    ;;

esac

echo_message ""
echo_message "Done!"
echo_message ""
