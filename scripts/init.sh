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

# ------------------------------------------------------------------------------
# Set LOCAL_HOST and other installation specific options in options.txt
# See options.default for possible values
# ------------------------------------------------------------------------------

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )

parse_options
source options.txt

echo_message ""
echo_message "Initializing installation for host: \\033[1m$LOCAL_HOST\\033[0m"
echo_message ""
echo_warning "This can take up to 15 minutes depending on bandwidth."
echo_message ""

if [ "$WIPE_ON_INIT" = true ]; then
    ./scripts/wipe.sh
else
    # stop and remove all containers or the network cannot be recreated
    ./scripts/stop.sh 2>/dev/null
fi

./scripts/generate_env_vars.sh
source .env

docker network rm aether_bootstrap_net || true
create_docker_assets

if [ "$PULL_IMAGES" = true ]; then
    ./scripts/pull.sh
fi

if [ "$WIPE_ON_INIT" = true ]; then
    # create all databases even if the services will not be enabled later
    ./auth/init.sh
    ./aether/init.sh
    ./connect/init.sh
    ./gather/init.sh
fi

./scripts/setup.sh
./scripts/start.sh

# always create default realm
./scripts/add_tenant.sh "$DEFAULT_REALM"

IFS=';' read -a tenants <<< "$INITIAL_TENANTS"
for tenant in "${tenants[@]}"; do
    if [ "$tenant" != "$DEFAULT_REALM" ]; then
        ./scripts/add_tenant.sh "$tenant"
    fi
done


./scripts/stop.sh 2>/dev/null

echo_message ""
echo_success "Done!"
echo_message ""
