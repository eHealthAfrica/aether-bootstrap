#!/usr/bin/env bash
#
# Copyright (C) 2023 by eHealth Africa : http://www.eHealthAfrica.org
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

start_db

# Initialize the kernel & kernel-ui databases in the postgres instance

# THESE COMMANDS WILL ERASE PREVIOUS DATA!!!
echo_warning "ERASING PREVIOUS KERNEL & KERNEL-UI DATA!!!"
rebuild_database aether    kernel ${KERNEL_DB_PASSWORD}
rebuild_database kernel-ui ui     ${UI_DB_PASSWORD}
echo_message ""
