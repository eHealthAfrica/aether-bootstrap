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
    ( echo "Run this script from /aether-bootstrap not from /aether-bootstrap/elasticsearch" && \
      exit 1 )
source ./scripts/aether_functions.sh
source options.txt

DCES="docker-compose -f ./elasticsearch/docker-compose.yml"

$DCES pull elasticsearch kibana

start_container kong     $KONG_INTERNAL
start_container keycloak $KEYCLOAK_INTERNAL

ES_URL="http://admin:${ELASTICSEARCH_PASSWORD}@elasticsearch:9200"
start_container elasticsearch $ES_URL "./elasticsearch/docker-compose.yml"

$AUTH_RUN setup_elasticsearch

# Initial tenants from options.txt
IFS=';' read -a tenants <<<$INITIAL_TENANTS
for tenant in "${tenants[@]}"
do
    # From aether_functions.sh
    add_es_tenant "$tenant"
done
