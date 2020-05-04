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

source options.txt || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )

_base_/start.sh
auth/start.sh
aether/start.sh

if [ "$ENABLE_CONNECT" = true ]; then
    connect/start.sh
fi
if [ "$ENABLE_GATHER" = true ]; then
    gather/start.sh
fi
if [ "$ENABLE_ELASTICSEARCH" = true ]; then
    elasticsearch/start.sh
fi
if [ "$ENABLE_CKAN" = true ]; then
    ckan/start.sh
    ckan-consumer/start.sh
fi
