
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

set -eu

gen_random_string () {
    openssl rand -hex 16 | tr -d "\n"
}

create_config() {
    
    COOKIE_SECRET=$(gen_random_string)
    POSTGRES_PASSWORD=$(gen_random_string)
    REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> ./.env
    echo "REDASH_LOG_LEVEL=INFO" >> ./.env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> ./.env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> ./.env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> ./.env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> ./.env
}

echo "___________________________________________________ Creating Redash Secrets"
if [ ! -f ./.env ]; then
    create_config
    cp ./.env ./.env.bak     

    echo "___________________________________________________ Preparing Redash Database"
    docker-compose run server python ./manage.py database create_tables
    docker-compose kill
fi

echo "___________________________________________________ Done"
