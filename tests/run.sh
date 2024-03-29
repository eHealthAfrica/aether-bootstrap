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

source .env

DC_TEST="docker compose --env-file .env -f tests/docker-compose.yml"
DC_KERNEL="$DC_TEST run --rm kernel-test"
MAX_RETRIES=20

function _wait_for {
    local container=$1
    local is_ready=$2

    echo "Starting $container server..."
    $DC_TEST up -d "${container}-test"

    local retries=1
    until $is_ready > /dev/null; do
        >&2 echo "Waiting for $container... $retries"

        ((retries++))
        if [[ $retries -gt $MAX_RETRIES ]]; then
            echo "It was not possible to start $container"
            $DC_TEST logs "${container}-test"
            $is_ready
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

function start_producer_test {
    _wait_for "producer" "$DC_KERNEL eval wget -q --spider http://producer-test:9005/healthcheck"
}

function kernel_setup {
    $DC_KERNEL setup

    $DC_KERNEL manage create_user \
        -u=$TEST_KERNEL_CLIENT_USERNAME \
        -p=$TEST_KERNEL_CLIENT_PASSWORD \
        -r=$TEST_KERNEL_CLIENT_REALM
}

$DC_TEST up -d db-test redis-test kafka-test zookeeper-test
start_db_test

# check producer access to kernel via RESTful API (api) / database (db)
_types=( api )

for _type in "${_types[@]}"; do
    echo "====================================================================="
    echo "== Integration tests with Producer Kernel access type:  ${_type}"
    echo "====================================================================="

    export TEST_PRODUCER_KERNEL_ACCESS_TYPE=${_type}
    kernel_setup
    $DC_TEST up -d exm-test
    start_kernel_test
    start_producer_test

    $DC_TEST run --rm integration-test test

    $DC_TEST kill exm-test kernel-test producer-test
done

./tests/wipe.sh
