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

if [ -z "${1:-}" ]; then
    echo -e "\033[91mPlease, indicate tenant/realm!\033[0m"
    exit 1
fi

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env

start_add_tenant_dependencies

REALM="$1"
THEME=${2:-$DEFAULT_LOGIN_THEME}
DESC=${3:-Tenant:  $REALM}

$GWM_RUN add_realm \
    $REALM \
    description="$DESC" \
    account_theme=$THEME \
    admin_theme=$THEME \
    login_theme=$THEME

$GWM_RUN add_public_client \
    $REALM \
    $KEYCLOAK_PUBLIC_CLIENT

$GWM_RUN add_oidc_client \
    $REALM \
    $KEYCLOAK_OIDC_CLIENT

$GWM_RUN add_admin \
    $REALM \
    $INITIAL_SU_USERNAME \
    $INITIAL_SU_PASSWORD

$GWM_RUN add_user \
    $REALM \
    $INITIAL_ADMIN_USERNAME \
    $INITIAL_ADMIN_PASSWORD

$GWM_RUN add_user_group \
    $REALM \
    $INITIAL_ADMIN_USERNAME \
    "admin"

$GWM_RUN add_user \
    $REALM \
    $INITIAL_USER_USERNAME \
    $INITIAL_USER_PASSWORD

$GWM_RUN add_user_group \
    $REALM \
    $INITIAL_USER_USERNAME \
    "user"

$GWM_RUN add_service \
    "gateway" \
    $REALM \
    $KEYCLOAK_OIDC_CLIENT
