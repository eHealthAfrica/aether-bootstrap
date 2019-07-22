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

if [ -z "${1:-}" ]; then
    echo "Please, indicate tenant!"
    exit 1
fi

source ./.env || \
    ( echo "Run this script from /aether-bootstrap not from /aether-bootstrap/demo" && \
      exit 1 )
source ./scripts/aether_functions.sh

echo_message "You services must be running!"
echo_message "REST PROXY IS NOT MULTI-TENANT!!!"
echo_message "ONLY ONE REALM SHOULD BE GRANTED ACCESS"
echo_message "Adding rest-proxy service tenant $1..."

$AUTH_RUN add_service rest-proxy $1 $KEYCLOAK_KONG_CLIENT
