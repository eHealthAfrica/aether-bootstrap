#!/usr/bin/env bash
#
# Copyright (C) 2020 by eHealth Africa : http://www.eHealthAfrica.org
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

function demo_options {
    cat << EOF
# DEMO options
BASE_PROTOCOL=http
LOCAL_HOST=demo.server

PULL_IMAGES=true
WIPE_ON_INIT=false
INITIAL_TENANTS="dev;"

## Keycloak Settings
KEYCLOAK_GLOBAL_ADMIN=admin
KEYCLOAK_PUBLIC_CLIENT=aether
KEYCLOAK_OIDC_CLIENT=kong
KEYCLOAK_LOGIN_THEME=aether

# Initial user credentials
INITIAL_SU_USERNAME=sys-admin
INITIAL_ADMIN_USERNAME=admin
INITIAL_USER_USERNAME=user

# Password for user "user"
SERVICES_DEFAULT_USER_PASSWORD=password
# Password for user "admin"
SERVICES_DEFAULT_ADMIN_PASSWORD=adminadmin

# Enable services
ENABLE_CONNECT=false
ENABLE_GATHER=true
ENABLE_ELASTICSEARCH=true
EOF
}

demo_options > options.txt
