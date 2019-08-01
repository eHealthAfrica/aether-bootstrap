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

# ------------------------------------------------------------------------------
# Set LOCAL_HOST and other installation specific options in options.txt
# See options.default for possible values
# ------------------------------------------------------------------------------

source scripts/lib.sh
parse_options
source options.txt

echo_message ""
echo_message "Initializing installation for host: \\e[1m$LOCAL_HOST\\e[0m"
echo_message ""

./scripts/generate_env_vars.sh
source .env

echo_message ""
echo_warning "Initializing Aether environment,"
echo_warning " this may take 15 minutes depending on bandwidth."
echo_message ""

# stop and remove all containers or the network cannot be recreated
./scripts/stop.sh 2>/dev/null
docker network rm aether_bootstrap_net || true
create_docker_assets

./auth/init.sh
./scripts/setup.sh

./scripts/start.sh
IFS=';' read -a tenants <<<$INITIAL_TENANTS
for tenant in "${tenants[@]}"; do
    ./scripts/add_tenant.sh "$tenant"
done
./scripts/stop.sh 2>/dev/null

echo_message ""
echo_success "Done!"
echo_message ""
