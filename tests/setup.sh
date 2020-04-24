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

function _wait_for {
    local container=$1
    local is_ready=$2

    echo "Starting $container server..."
    $DC_TEST up -d "${container}-test"

    local retries=1
    until $is_ready > /dev/null; do
        >&2 echo "Waiting for $container... $retries"

        ((retries++))
        if [[ $retries -gt 10 ]]; then
            echo "It was not possible to start $container"
            exit 1
        fi

        sleep 2
    done
    echo "$container is ready!"
}

function start_db_test {
    _wait_for "db" "$DC_KERNEL eval pg_isready -q"
}

function start_kernel_test {
    _wait_for "kernel" "$DC_KERNEL eval wget -q --spider http://kernel-test:9000/health"
}

./scripts/generate_env_vars.sh
source .env

$DC_TEST pull

start_db_test
$DC_TEST up -d redis-test

$DC_KERNEL setup

$DC_KERNEL manage create_user \
    -u=$TEST_KERNEL_CLIENT_USERNAME \
    -p=$TEST_KERNEL_CLIENT_PASSWORD \
    -r=$TEST_KERNEL_CLIENT_REALM

$DC_TEST up -d zookeeper-test kafka-test producer-test
sleep 10

echo "Containers started, waiting for Kernel to be available..."
start_kernel_test
