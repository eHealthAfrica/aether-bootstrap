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
source scripts/lib.sh
source auth/scripts/keycloak_admin_functions.sh

# ----------------------------------------
# NOTE: change the following values

REALM="eHA"
DES="eHealth Africa"
USER="user"
PWD="secretsecret"
# ----------------------------------------


if [ -z "${REALM:-}" ]; then
    echo -e "\e[91mPlease, indicate realm name!\e[0m"
    exit 1
fi

./auth/start.sh

echo_message "Connecting to keycloak server..."
connect_to_keycloak

echo_message "Creating realm [$REALM] [$DESC]..."
create_kc_realm $REALM $DES

echo_message "Creating public client [$KEYCLOAK_AETHER_CLIENT] in realm [$REALM]..."
create_kc_public_client $REALM $KEYCLOAK_AETHER_CLIENT

echo_message "Creating non-public client [$KEYCLOAK_KONG_CLIENT] in realm [$REALM]..."
create_kc_non_public_client $REALM $KEYCLOAK_KONG_CLIENT

if [ ! -z "${USER}" ]; then
    echo_message "Creating user [$USER] in realm [$REALM]..."
    create_kc_user $REALM $USER $PWD
fi
