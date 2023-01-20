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

source scripts/lib.sh

for dc_file in $(find docker-compose.yml */docker-compose.yml 2> /dev/null); do
    docker compose --env-file .env -f $dc_file kill    2>/dev/null
    docker compose --env-file .env -f $dc_file down -v 2>/dev/null
done

for volume in "${AET_VOLUMES[@]}"; do
    {
        docker volume rm -f $volume 2>/dev/null
    } || true
done

docker network rm $AET_NETWORK 2>/dev/null || true

rm -f .env
rm -rf ./connect/*.conf
