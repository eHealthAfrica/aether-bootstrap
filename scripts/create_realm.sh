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
# bring the secrets
source .env

# ----------------------------------------
# NOTE: change the following values

REALM="eHA"
DES="eHealth Africa"
USER="user"
PWD="secretsecret"
# ----------------------------------------


if [ -z "${REALM:-}" ]; then
    echo "Pease, indicate realm name!"
    exit 1
fi

start_db
start_kong
start_keycloak

connect_to_keycloak

create_kc_realm          $REALM $DES
create_kc_aether_client  $REALM
create_kc_kong_client    $REALM

if [ ! -z "${USER}" ]; then
    create_kc_user $REALM $USER $PWD
fi
