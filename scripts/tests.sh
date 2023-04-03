#!/usr/bin/env bash
#
# Copyright (C) 2023 by eHealth Africa : http://www.eHealthAfrica.org
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
#
# This script is intended to be used exclusively in Github actions.
# It just checks that the different scripts work, and WIPES everything on exit.
#
# ------------------------------------------------------------------------------

function test_options {
    cat << EOF
# Test options
BASE_PROTOCOL=http
LOCAL_HOST=aether.test.server

PULL_IMAGES=true
WIPE_ON_INIT=true
INITIAL_TENANTS="testing;"

## Keycloak Settings
KEYCLOAK_GLOBAL_ADMIN=kc-admin-testing

KEYCLOAK_PUBLIC_CLIENT=public-testing
KEYCLOAK_OIDC_CLIENT=oidc-testing

KEYCLOAK_LOGIN_THEME=keycloak

# Initial users credentials
INITIAL_SU_USERNAME=sys-admin-testing
INITIAL_ADMIN_USERNAME=admin-testing
INITIAL_USER_USERNAME=user-testing

SERVICES_DEFAULT_USER_PASSWORD=testing-password
SERVICES_DEFAULT_ADMIN_PASSWORD=testing-password

# Enable services
ENABLE_CONNECT=true
ENABLE_GATHER=true
ENABLE_ELASTICSEARCH=true
ENABLE_CKAN=true

AETHER_CONNECT_MODE=LOCAL
EOF
}

function _on_exit {
    ./scripts/wipe.sh > /dev/null
}

function _on_err {
    case "$TEST_MODE" in
        s | setup )
            for dc_file in $(find docker-compose.yml */docker-compose.yml 2> /dev/null); do
                docker compose --env-file .env -f $dc_file logs -t --tail="all"
            done
        ;;

        i | integration )
            dc_file="tests/docker-compose.yml"
            CONTAINERS=( db kernel producer )
            for container in "${CONTAINERS[@]}"; do
                docker compose --env-file .env -f $dc_file logs -t --tail="all" "${container}-test"
            done
        ;;
    esac

    exit 1
}

test_options > options.txt
TEST_MODE=$1

trap '_on_exit' EXIT
trap '_on_err' ERR


case "$TEST_MODE" in
    s | setup )
        ./scripts/init.sh
    ;;

    i | integration )
        ./tests/init.sh
        ./tests/run.sh
    ;;
esac
