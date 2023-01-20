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
# https://www.keycloak.org/docs/latest/server_admin/index.html#using-the-admin-cli
# ------------------------------------------------------------------------------

function connect_to_keycloak {
    KC_ID=$(docker compose --env-file .env -f auth/docker-compose.yml ps -q keycloak)
    export KCADM="docker container exec -i ${KC_ID} ./keycloak/bin/kcadm.sh"

    $KCADM \
        config credentials \
        --server ${KEYCLOAK_INTERNAL} \
        --realm master \
        --user "${KEYCLOAK_GLOBAL_ADMIN}" \
        --password "${KEYCLOAK_GLOBAL_PASSWORD}"

    $KCADM update realms/master -s sslRequired=NONE
}


# Usage:    create_kc_realm <realm-name> [<realm-description>]
function create_kc_realm {
    REALM=$1
    DESC="${2:-$REALM}"

    $KCADM \
        create realms \
        -s realm="${REALM}" \
        -s displayName="${DESC}" \
        -s loginTheme="${LOGIN_THEME}" \
        -s enabled=true \
        -s sslRequired=NONE
}


# Usage:    create_kc_public_client <realm-name> <client-id>
function create_kc_public_client {
    REALM=$1
    CLIENT=$2

    REALM_URL="${BASE_PROTOCOL}://${BASE_DOMAIN}/${REALM}/"
    PUBLIC_URL="${BASE_PROTOCOL}://${BASE_DOMAIN}/${PUBLIC_REALM}/*"

    $KCADM \
        create clients \
        -r "${REALM}" \
        -s clientId="${CLIENT}" \
        -s publicClient=true \
        -s directAccessGrantsEnabled=true \
        -s baseUrl="${REALM_URL}" \
        -s 'redirectUris=["*","'${PUBLIC_URL}'"]' \
        -s enabled=true
}

# Usage:    create_kc_non_public_client <realm-name> <client-id>
function create_kc_non_public_client {
    REALM=$1
    CLIENT=$2

    REALM_URL="${BASE_PROTOCOL}://${BASE_DOMAIN}/${REALM}/"

    $KCADM \
        create clients \
        -r "${REALM}" \
        -s clientId="${CLIENT}" \
        -s publicClient=false \
        -s clientAuthenticatorType=client-secret \
        -s directAccessGrantsEnabled=true \
        -s baseUrl="${REALM_URL}" \
        -s 'redirectUris=["*"]' \
        -s enabled=true
}


# Usage:    create_kc_user <realm-name> <username> [<password>]
function create_kc_user {
    REALM=$1
    USERNAME=$2
    PASSWORD=${3:-}

    $KCADM \
        create users \
        -r "${REALM}" \
        -s username="${USERNAME}" \
        -s enabled=true

    if [ ! -z "${PASSWORD}" ]; then
        $KCADM \
            set-password \
            -r "${REALM}" \
            --username "${USERNAME}" \
            --new-password="${PASSWORD}"
    fi
}
