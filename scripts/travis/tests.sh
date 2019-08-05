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

function travis_options {
    cat << EOF
# Travis test options
BASE_PROTOCOL=http
LOCAL_HOST=travis.test.server

PULL_IMAGES=true
INITIAL_TENANTS="test;"

## Keycloak Settings
KEYCLOAK_GLOBAL_ADMIN=admin-travis
KEYCLOAK_GLOBAL_PASSWORD=travis-password

KEYCLOAK_AETHER_CLIENT=aether-travis
KEYCLOAK_KONG_CLIENT=kong-travis

# Initial user credentials
KEYCLOAK_INITIAL_USER_USERNAME=user-travis
KEYCLOAK_INITIAL_USER_PASSWORD=travis-password

# Password for user "admin"
SERVICES_DEFAULT_ADMIN_PASSWORD=travis-password

# Enable services
ENABLE_CONNECT=true
ENABLE_GATHER=true
ENABLE_ELASTICSEARCH=true
EOF
}

travis_options > options.txt

case "$1" in

    setup )
        ./scripts/init.sh
        ./scripts/start.sh
        ./scripts/stop.sh
    ;;

    integration )
        ./tests/run.sh
    ;;

esac
