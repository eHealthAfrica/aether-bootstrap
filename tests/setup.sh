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

DC_TEST="docker-compose -f tests/docker-compose.yml"
DC_KERNEL="$DC_TEST run --rm --no-deps kernel-test"

function start_db_test {
    $DC_TEST up -d db-test

    until $DC_KERNEL eval pg_isready -q; do
        >&2 echo "Waiting for database..."
        sleep 2
    done
}

function start_kernel_test {
    $DC_TEST up -d kernel-test

    KERNEL_HEALTH_URL="http://kernel-test:9000/health"
    until $DC_KERNEL manage check_url -u $KERNEL_HEALTH_URL >/dev/null; do
        >&2 echo "Waiting for Kernel..."
        sleep 2
    done
}

start_db_test

$DC_KERNEL setup
$DC_KERNEL eval python /code/sql/create_readonly_user.py

$DC_TEST up -d zookeeper-test kafka-test producer-test
sleep 10

echo "Containers started, waiting for Kernel to be available..."
start_kernel_test
