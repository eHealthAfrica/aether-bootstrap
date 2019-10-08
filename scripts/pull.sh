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

source options.txt || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )

docker-compose -f _base_/docker-compose.yml pull
docker-compose -f auth/docker-compose.yml pull
docker-compose -f aether/docker-compose.yml pull


if [ "$ENABLE_CONNECT" = true ]; then
    if [ "$AETHER_CONNECT_MODE" = "LOCAL" ]; then
        docker-compose -f connect/docker-compose.yml pull
    elif [ "$AETHER_CONNECT_MODE" = "CONFLUENT" ]; then
        docker-compose -f connect/docker-compose.yml pull producer
    fi
fi

if [ "$ENABLE_GATHER" = true ]; then
    docker-compose -f gather/docker-compose.yml pull
fi
if [ "$ENABLE_ELASTICSEARCH" = true ]; then
    docker-compose -f elasticsearch/docker-compose.yml pull
fi
