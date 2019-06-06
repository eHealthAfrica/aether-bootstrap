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
    ( echo "Run this script from /aether-bootstrap not from /aether-bootstrap/gather" && \
      exit 1 )
source ./scripts/aether_functions.sh


DC_AUTH="docker-compose -f ./docker-compose-generation.yml"
DCG="docker-compose -f ./gather/docker-compose.yml"

start_kong
start_keycloak

$DCG pull gather
$DCG run --rm --no-deps gather setup

function add_gather_tenant {
    REALM=$1
    echo_message "Adding [gather] solution in kong..."
    $DC_AUTH run --rm auth add_solution gather $REALM
}

add_gather_tenant "dev"
add_gather_tenant "prod"
add_gather_tenant "test"
