#!/usr/bin/env bash
#
# Copyright (C) 2020 by eHealth Africa : http://www.eHealthAfrica.org
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

LINE=`printf -v row "%${COLUMNS:-$(tput cols)}s"; echo ${row// /=}`
MAX_RETRIES=20

DC_AUTH="docker-compose -f auth/docker-compose.yml"
GWM_RUN="$DC_AUTH run --rm gateway-manager"
KERNEL_EVAL="docker-compose -f aether/docker-compose.yml run --rm kernel eval"


function echo_message {
    if [ -z "$1" ]; then
        echo -e "\033[90m$LINE\033[0m"
    else
        local msg=" $1 "
        local color=${2:-\\033[39m}
        echo -e "\033[90m${LINE:${#msg}}\033[0m$color$msg\033[0m"
    fi
}

function echo_error {
    echo_message "$1" \\033[91m
}

function echo_success {
    echo_message "$1" \\033[92m
}

function echo_warning {
    echo_message "$1" \\033[93m
}


function parse_options {
    test -e ./options.txt || \
    (
        echo "No options.txt found, using 'options.default'" && \
        cp ./options.default ./options.txt
    )
}


function create_docker_assets {
    echo_message "Generating docker network and volumes..."

    {
        docker network create aether_bootstrap_net \
            --attachable \
            --subnet=${NETWORK_SUBNET}
    } || true
    echo_success "aether_bootstrap_net network is ready"

    VOLUMES=( aether_database_data aether_minio_data aether_ckan_data )
    for volume in "${VOLUMES[@]}"; do
        docker volume create $volume || true
        echo_success "$volume volume is ready"
    done
}


function start_db {
    docker-compose -f _base_/docker-compose.yml up -d db

    local DB_ID=$(docker-compose -f _base_/docker-compose.yml ps -q db)
    local is_ready="docker container exec -i $DB_ID pg_isready -q"
    local on_error="docker-compose -f _base_/docker-compose.yml logs db"

    _wait_for "database" "$is_ready" "$on_error"
}


function start_auth_container {
    local container=$1
    $DC_AUTH up -d $container

    local is_ready="$GWM_RUN ${container}_ready"
    local on_error="$DC_AUTH logs $container"

    _wait_for "$container" "$is_ready" "$on_error"
}


# Usage:    _wait_for <container-name> <is-ready-check> <on-error-action>
function _wait_for {
    local container=$1
    local is_ready=$2
    local on_error=$3

    echo_message "Starting $container server..."

    local retries=1
    until $is_ready > /dev/null; do
        >&2 echo "Waiting for $container... $retries"

        ((retries++))
        if [[ $retries -gt $MAX_RETRIES ]]; then
            echo_error "It was not possible to start $container"
            $on_error
            exit 1
        fi

        sleep 2
    done
    echo_success "$container is ready!"
}


# Usage:    rebuild_database <database> <user> <password>
function rebuild_database {
    local DB_NAME=$1
    local DB_USER=$2
    local DB_PWD=$3

    local DB_ID=$(docker-compose -f _base_/docker-compose.yml ps -q db)
    local PSQL="docker container exec -i $DB_ID psql"

    echo_message "Recreating $1 database..."

    # drops database (terminating any previous connection) and creates it again
    $PSQL <<- EOSQL
        UPDATE pg_database SET datallowconn = 'false' WHERE datname = '${DB_NAME}';
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';

        DROP DATABASE IF EXISTS "${DB_NAME}";
        DROP USER IF EXISTS "${DB_USER}";

        CREATE USER "${DB_USER}" PASSWORD '${DB_PWD}';
        CREATE DATABASE "${DB_NAME}" OWNER "${DB_USER}";
EOSQL
    echo_success "$1 database is ready"
}
