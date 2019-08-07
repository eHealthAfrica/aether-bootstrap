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
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env

create_docker_assets

docker network create ckan_bootstrap_net || true

pushd ckan

{ # try
    docker-compose build --pull --force-rm
} || { # catch
    echo 'not ready...'
}

docker-compose up -d

retries=1
until docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add admin | tee creds.txt && echo "done"
do
    echo "waiting for ckan container to be ready... $retries"
    sleep 5

        ((retries++))
        if [[ $retries -gt 30 ]]; then
            echo "It was not possible to start CKAN"
            exit 1
        fi
done

popd
