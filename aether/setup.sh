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

_base_/start.sh
start_redis

# setup container (model migration, admin user, static content...)
DCA="docker-compose -f aether/docker-compose.yml"
AETHER_CONTAINERS=( exm kernel kernel-ui )
for container in "${AETHER_CONTAINERS[@]}"; do
    $DCA run --rm $container setup
done

$DCA run --rm kernel eval \
    python3 /code/sql/create_readonly_user.py \
    "$KERNEL_READONLY_DB_USERNAME" \
    "$KERNEL_READONLY_DB_PASSWORD"
