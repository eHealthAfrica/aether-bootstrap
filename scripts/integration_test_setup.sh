#!/usr/bin/env bash
#
# Copyright (C) 2018 by eHealth Africa : http://www.eHealthAfrica.org
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

wait_for_kernel() {
    KERNEL_HEALTH_URL="http://localhost:9000/health"
    until curl -s $KERNEL_HEALTH_URL > /dev/null; do
        >&2 echo "Waiting for Kernel..."
        sleep 2
    done
}

# Setup test network and volume if it doesn't exist.
docker network create aether_test 2>/dev/null || true
docker volume create --name=aether_test_database_data 2>/dev/null || true
DC_TEST="docker-compose -f docker-compose-test.yml"

$DC_TEST up -d db-test
sleep 3
docker-compose -f docker-compose-test.yml \
        run --no-deps kernel-test setup
docker-compose -f docker-compose-test.yml \
        run --no-deps kernel-test eval python /code/sql/create_readonly_user.py
docker-compose -f docker-compose-test.yml kill kernel-test
$DC_TEST up -d kernel-test
$DC_TEST up -d zookeeper-test kafka-test producer-test
echo "Containers started, waiting for Kernel to be available..."
wait_for_kernel