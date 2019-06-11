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


function echo_message {
    if [ -z "$1" ]; then
        echo "$LINE"
    else
        msg=" $1 "
        echo "${LINE:${#msg}}$msg"
    fi
}


function create_docker_assets {
    echo_message "Generating docker network and database volume..."
    {
        docker network create aether_bootstrap_net \
            --attachable \
            --subnet=${NETWORK_SUBNET} \
            --gateway=${NETWORK_GATEWAY}
    } || true
    echo_message "aether_bootstrap_net network is ready"

    docker volume create aether_database_data || true
    echo_message "aether_database_data volume is ready"
}


function start_db {
    echo_message "Starting database server..."
    docker-compose up -d db
    until docker-compose run --rm --no-deps kernel eval pg_isready -q; do
        >&2 echo "Waiting for database..."
        sleep 2
    done
    echo_message "database is ready"
}


# Usage:    start_container <container-name> <container-health-url>
function start_container {
    container=$1
    url=$2

    echo_message "Starting $container server..."
    docker-compose up -d $container

    CHECK_URL="docker-compose run --rm --no-deps kernel manage check_url -u"
    until $CHECK_URL $url >/dev/null; do
        >&2 echo "Waiting for $container..."
        sleep 2
    done
    echo_message "$container is ready"
}


# Usage:    rebuild_database <database> <user> <password>
function rebuild_database {
    DB_NAME=$1
    DB_USER=$2
    DB_PWD=$3

    DB_ID=$(docker-compose ps -q db)
    PSQL="docker container exec -i $DB_ID psql"

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
    echo_message "$1 database is ready"
}
