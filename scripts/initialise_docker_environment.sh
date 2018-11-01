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

echo "Initializing Aether environment, this will take about 30 seconds."

docker network create aether_internal      2>/dev/null || true
docker volume  create aether_database_data 2>/dev/null || true

./scripts/generate_env_vars.sh

docker-compose -f docker-compose-base.yml pull

docker-compose up -d db
until docker-compose run kernel eval pg_isready -q; do
    >&2 echo "Waiting for database..."
    sleep 2
done

# setup container (model migration, admin user, static content...)
CONTAINERS=( kernel ui odk )
for container in "${CONTAINERS[@]}"
do
    docker-compose run $container setup
done

docker-compose run kernel eval python /code/sql/create_readonly_user.py
docker-compose kill

echo "Done."
