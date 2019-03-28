#!/usr/bin/env python

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

import json
import os
import requests

from keycloak import KeycloakAdmin

from settings import (
    KEYCLOAK_URL,  # EXTERNAL
    KC_URL,  # INTERNAL
    KC_ADMIN_USER,
    KC_ADMIN_PASSWORD,
    KC_MASTER_REALM,
    REALMS_PATH,
)


def __post(url, data):
    res = requests.post(url, data=data)
    try:
        res.raise_for_status()
        return res.json()
    except Exception as e:
        print(res.status_code)
        print(res.json())
        raise e

# Get administrative Token with KC Master Credentials


def make_realm(name, config):
    print(f'Creating realm: {name}')

    keycloak_admin = KeycloakAdmin(server_url=KC_URL,
                                   username=KC_ADMIN_USER,
                                   password=KC_ADMIN_PASSWORD,
                                   realm_name=KC_MASTER_REALM,
                                   verify=False)

    token = keycloak_admin.token['access_token']

    # Register realm with provided config
    realm_url = f'{KC_URL}admin/realms'
    headers = {
        'content-type': 'application/json',
        'authorization': f'Bearer {token}',
    }
    res = requests.post(realm_url, headers=headers, data=json.dumps(config))
    try:
        res.raise_for_status()
        print(res.text)
    except Exception:
        raise ValueError('Could not create realm.')

    print(f'Realm: {name} created on keycloak: {KEYCLOAK_URL}')


def find_available_realms():
    realms = {}
    _files = os.listdir(REALMS_PATH)
    for f in _files:
        name = f.split('.json')[0]
        with open(f'{REALMS_PATH}/{f}') as _f:
            config = json.load(_f)
            realms[name] = config
    return realms


if __name__ == '__main__':
    realms = find_available_realms()
    for name, config in realms.items():
        make_realm(name, config)
