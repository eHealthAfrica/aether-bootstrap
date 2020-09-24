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

source options.txt || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env

if [ -z "${1:-}" ]; then
    echo -e "\033[91mPlease, indicate tenant!\033[0m"
    exit 1
fi

# <realm> <login-theme> <realm-description>
auth/add_tenant.sh "$1" "${2:-$KEYCLOAK_LOGIN_THEME}" "${3:-}"
aether/add_tenant.sh "$1"

if [ "$ENABLE_CONNECT" = true ]; then
    connect/add_tenant.sh "$1"
fi

if [ "$ENABLE_GATHER" = true ]; then
    gather/add_tenant.sh "$1"
fi

if [ "$ENABLE_ELASTICSEARCH" = true ]; then
    elasticsearch/add_tenant.sh "$1"
fi

if [ "$ENABLE_CKAN" = true ]; then
    ckan/add_tenant.sh "$1"
fi
