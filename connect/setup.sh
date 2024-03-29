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

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env
source options.txt

connect/make_credentials.sh

DCC="docker compose --env-file .env -f connect/docker-compose.yml"

if [ "$AETHER_CONNECT_MODE" = "LOCAL" ]; then
    echo_message "Starting Kafka & Zookeper containers..."
    $DCC up -d zookeeper kafka
    $DCC run --rm --no-deps kafka dub wait kafka 9092 60

    echo_message "Creating Kafka Superuser..."
    $GWM_RUN add_kafka_su   $KAFKA_SU_USER $KAFKA_SU_PASSWORD
    $GWM_RUN grant_kafka_su $KAFKA_CONSUMER_USER
    echo_message ""

elif [ "$AETHER_CONNECT_MODE" = "CONFLUENT" ]; then
    echo_message "Using Confluent Cloud, no additional cluster setup required..."
    echo_message ""
fi
