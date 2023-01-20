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

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source auth/extras/keycloak_admin_functions.sh
source .env

# ----------------------------------------
# NOTE: change the following values

REALM="eHA"
DES="eHealth Africa"
USER="user"
PWD="secretsecret"
# ----------------------------------------


if [ -z "${REALM:-}" ]; then
    echo -e "\033[91mPlease, indicate realm name!\033[0m"
    exit 1
fi

start_db
./auth/start.sh

echo_message "Connecting to keycloak server..."
connect_to_keycloak

echo_message "Creating realm [$REALM] [$DESC]..."
create_kc_realm $REALM $DES

echo_message "Creating public client [$KEYCLOAK_PUBLIC_CLIENT] in realm [$REALM]..."
create_kc_public_client $REALM $KEYCLOAK_PUBLIC_CLIENT

echo_message "Creating non-public client [$KEYCLOAK_OIDC_CLIENT] in realm [$REALM]..."
create_kc_non_public_client $REALM $KEYCLOAK_OIDC_CLIENT

if [ ! -z "${USER}" ]; then
    echo_message "Creating user [$USER] in realm [$REALM]..."
    create_kc_user $REALM $USER $PWD
fi
