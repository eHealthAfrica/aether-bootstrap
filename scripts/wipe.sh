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

for dc_file in $(find docker-compose*.yml */docker-compose*.yml 2> /dev/null); do
    docker-compose -f $dc_file kill    2>/dev/null
    docker-compose -f $dc_file down -v 2>/dev/null
done

VOLUMES=( aether_database_data aether_minio_data )
for volume in "${VOLUMES[@]}"; do
    {
        docker network rm -f $volume 2>/dev/null
    } || true
done

NETWORKS=( aether_bootstrap_net )
for network in "${NETWORKS[@]}"; do
    {
        docker network rm $network 2>/dev/null
    } || true
done

rm -f .env
rm -Rf ./connect/*.conf

sudo rm -Rf ./.persistent_data
sudo rm -f ckan-consumer/db/consumer.db
