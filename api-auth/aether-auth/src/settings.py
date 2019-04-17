# Copyright (C) 2018 by eHealth Africa : http://www.eHealthAfrica.org
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

import os


DEBUG = bool(os.environ.get('DEBUG'))

HOST = os.environ.get('BASE_HOST')  # External URL for host
DOMAIN = os.environ.get('BASE_DOMAIN')

# Keycloak Information
KEYCLOAK_INTERNAL = os.environ.get('KEYCLOAK_INTERNAL')

KC_URL = f'{KEYCLOAK_INTERNAL}/keycloak/auth/'  # internal
KC_ADMIN_USER = os.environ.get('KEYCLOAK_GLOBAL_ADMIN')
KC_ADMIN_PASSWORD = os.environ.get('KEYCLOAK_GLOBAL_PASSWORD')
KC_MASTER_REALM = 'master'
KEYCLOAK_KONG_CLIENT = os.environ.get('KEYCLOAK_KONG_CLIENT')


# Kong Information
KONG_URL = os.environ.get('KONG_INTERNAL')
KONG_OIDC_PLUGIN = 'kong-oidc-auth'

REALMS_PATH = '/code/realm'
SERVICES_PATH = '/code/service'
SOLUTIONS_PATH = '/code/solution'
