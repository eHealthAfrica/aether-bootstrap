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

DC_AUTH="docker-compose -f auth/docker-compose.yml"
GWM_RUN="$DC_AUTH run --rm gateway-manager"

function start_auth_container {
    container=$1
    echo_message "Starting $container server..."
    $DC_AUTH up -d $container

    is_ready="$GWM_RUN ${container}_ready"

    until $is_ready >/dev/null; do
        >&2 echo "Waiting for $container..."
        sleep 2
    done
    echo_success "$container is ready!"
}
