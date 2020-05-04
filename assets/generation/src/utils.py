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

import json
import logging
import os
import sys


def get_env(key, default_value=None):
    return os.environ.get(key, default_value)


def check_reqs(reqs=[]):
    if None in [get_env(r) for r in reqs]:
        LOGGER.error('Required Environment Variable is missing.')
        LOGGER.error('Required: %s' % (reqs,))
        sys.exit(1)


def file_to_json(path):
    with open(path) as f:
        return json.load(f)


_HERE = os.path.dirname(os.path.realpath(__file__))
RESOURCES_DIR = os.path.join(_HERE, '../resources/')

# Environment variables

KERNEL_URL = get_env('KERNEL_URL')
KERNEL_USER = get_env('KERNEL_USER')
KERNEL_PASSWORD = get_env('KERNEL_PASSWORD')

REALM = get_env('REALM')
KEYCLOAK_URL = get_env('KEYCLOAK_URL')

CLIENT_LOGLEVEL = get_env('CLIENT_LOGLEVEL', 'ERROR')
ROOT_LOGLEVEL = get_env('ROOT_LOGLEVEL', 'ERROR')

PROJECT_NAME = get_env('PROJECT_NAME')
MAPPING_NAME = get_env('MAPPING_NAME')

# Logger

LOGGER = logging.getLogger("AssetGeneration:")
LOGGER.setLevel(ROOT_LOGLEVEL)
