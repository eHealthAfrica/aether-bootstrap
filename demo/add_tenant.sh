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

source ./.env || \
    ( echo "Run this script from /aether-bootstrap not from /aether-bootstrap/demo" && \
      exit 1 )
source ./scripts/aether_functions.sh

echo_message "You services must be running! If you encounter errors, run demo/start.sh"
echo_message "Adding tenant $1..."
echo_message "Creating initial tenants/realms in keycloak..."
create_kc_tenant "$1"  "Realm: $1"
add_es_tenant "$1"
add_gather_tenant "$1"
