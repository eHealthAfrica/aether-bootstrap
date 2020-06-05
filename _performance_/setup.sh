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

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env

docker-compose -f _performance_/docker-compose.yml pull

./scripts/start.sh

TEST_REALM=${TEST_REALM:-_test_}

# create tenant for performance tests
./scripts/add_tenant.sh "${TEST_REALM}"

# create test users
NUMBER_OF_USERS=${TEST_NUMBER_OF_USERS:-100}
for ((i=1;i<=$NUMBER_OF_USERS;i++)); do
    USER_NAME="${KEYCLOAK_INITIAL_USER_USERNAME}-${i}"

    $GWM_RUN add_user \
        $TEST_REALM \
        $USER_NAME \
        $KEYCLOAK_INITIAL_USER_PASSWORD
done
