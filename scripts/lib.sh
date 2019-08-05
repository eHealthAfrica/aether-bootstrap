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

LINE=`printf -v row "%${COLUMNS:-$(tput cols)}s"; echo ${row// /=}`

DC_AUTH="docker-compose -f auth/docker-compose.yml"
GWM_RUN="$DC_AUTH run --rm gateway-manager"


function echo_message {
    if [ -z "$1" ]; then
        echo -e "\e[90m$LINE\e[0m"
    else
        local msg=" $1 "
        local color=${2:-\\033[39m}
        echo -e "\e[90m${LINE:${#msg}}\e[0m$color$msg\e[0m"
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
    echo_message "Generating docker network and database volume..."
    {
        docker network create aether_bootstrap_net \
            --attachable \
            --subnet=${NETWORK_SUBNET}
    } || true
    echo_success "aether_bootstrap_net network is ready"

    docker volume create aether_database_data || true
    echo_success "aether_database_data volume is ready"
}


function start_db {
    echo_message "Starting database server..."
    docker-compose -f _base_/docker-compose.yml up -d db

    local DCK="docker-compose -f aether/docker-compose.yml run --rm kernel"
    until $DCK eval pg_isready -q; do
        >&2 echo "Waiting for database..."
        sleep 2
    done
    echo_success "database is ready"
}


# Usage:    start_container <container-module> <container-name> <container-health-url>
function start_container {
    local dc="${1}/docker-compose.yml"
    local container=$2
    local url=$3

    echo_message "Starting [$container] server..."
    docker-compose -f $dc up -d $container

    local DCK="docker-compose -f aether/docker-compose.yml run --rm kernel"
    until $DCK manage check_url -u $url >/dev/null; do
        >&2 echo "Waiting for [$container]..."
        sleep 2
    done
    echo_success "[$container] is ready"
}


function start_auth_container {
    local container=$1
    echo_message "Starting $container server..."
    $DC_AUTH up -d $container

    local is_ready="$GWM_RUN ${container}_ready"

    until $is_ready >/dev/null; do
        >&2 echo "Waiting for $container..."
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

        DROP DATABASE ${DB_NAME};
        DROP USER ${DB_USER};

        CREATE USER ${DB_USER} PASSWORD '${DB_PWD}';
        CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
EOSQL
    echo_success "$1 database is ready"
}
