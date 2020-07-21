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

case "$1" in

    setup )
        for dc_file in $(find docker-compose.yml */docker-compose.yml 2> /dev/null); do
            docker-compose -f $dc_file logs -t --tail="all"
        done
    ;;

    integration )
        dc_file="tests/docker-compose.yml"
        CONTAINERS=( db kafka zookeeper kernel producer )
        for container in "${CONTAINERS[@]}"; do
            docker-compose -f $dc_file logs -t --tail="all" "${container}-test"
        done
    ;;

esac
