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

source scripts/lib.sh || \
    ( echo -e "\e[91mRun this script from root folder\e[0m" && \
      exit 1 )
source auth/lib.sh
source .env
source options.txt

connect/make_credentials.sh

if [ "$PULL_IMAGES" = true ]; then
    docker-compose -f connect/docker-compose.yml pull
fi

echo_message "Starting Kafka & Zookeper containers..."
docker-compose -f connect/docker-compose.yml up -d zookeeper kafka

./auth/start.sh

echo_message "Creating Kafka Superuser..."
$GWM_RUN add_kafka_su   $KAFKA_SU_USER $KAFKA_SU_PASSWORD
$GWM_RUN grant_kafka_su $KAFKA_ROOT_USER
echo_message ""

echo_message "Stoping Kafka & Zookeper containers..."
docker-compose -f connect/docker-compose.yml kill
docker-compose -f connect/docker-compose.yml down

IFS=';' read -a tenants <<<$INITIAL_TENANTS
for tenant in "${tenants[@]}"; do
    connect/add_tenant "$tenant"
done
echo_message ""
