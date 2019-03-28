#!/usr/bin/env python

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

import json
import os
import requests
import sys

from keycloak import KeycloakAdmin

from settings import (
    KONG_URL,
    KC_URL,
    KC_ADMIN_USER,
    KC_ADMIN_PASSWORD,
    KC_MASTER_REALM,
    KEYCLOAK_URL,
    SERVICES_PATH
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


def add_realm(realm, config):

    name = config['name']

    keycloak_admin = KeycloakAdmin(server_url=KC_URL,
                                   username=KC_ADMIN_USER,
                                   password=KC_ADMIN_PASSWORD,
                                   realm_name=KC_MASTER_REALM,
                                   verify=False)

    token = keycloak_admin.token['access_token']
    headers = {
        'content-type': 'application/json',
        'authorization': f'Bearer {token}',
    }

    client_id = f'{realm}-oidc'
    client_secret_url = f'{KC_URL}admin/realms/{realm}/clients/{client_id}/client-secret'
    res = requests.get(url=client_secret_url, headers=headers)
    try:
        res.raise_for_status()
        client_secret = res.json()['value']
        print(res.text)
    except Exception:
        raise ValueError('Could not get realm secret.')

    # OIDC plugin settings (same for all)
    auth_path = f'{KEYCLOAK_URL}realms/{realm}/protocol/openid-connect/auth'
    token_path = f'{KEYCLOAK_URL}realms/{realm}/protocol/openid-connect/token'
    user_path = f'{KEYCLOAK_URL}realms/{realm}/protocol/openid-connect/userinfo'
    logout_url = f'{KEYCLOAK_URL}realms/{realm}/protocol/openid-connect/logout'

    oidc_data = {
        'name': 'kong-oidc-auth',
        'config.authorize_url': auth_path,
        'config.scope': 'openid+profile+email+iss',
        'config.token_url': token_path,
        'config.client_id': f'{realm}-oidc',
        'config.client_secret': client_secret,
        'config.user_url': user_path,
        'config.email_key': 'email',
        'config.app_login_redirect_url': f'http://aether.local/{realm}/{name}/',
        'config.service_logout_url': logout_url,
        'config.cookie_domain': 'aether.local',
        'config.user_info_cache_enabled': 'true'
    }

    oidc_endpoints = config.get('oidc_endpoints', {})
    for endpoint_name, endpoint_url in oidc_endpoints.items():

        route_name = f'{name}_oidc_{endpoint_name}'
        ROUTE_URL = f'{KONG_URL}services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{name}{endpoint_url}'],
            'strip_path': 'true',
        }
        route_info = __post(url=ROUTE_URL, data=route_data)
        print(json.dumps(route_info, indent=2))
        protected_route_id = route_info['id']

        confirmation = __post(url=f'{KONG_URL}routes/{protected_route_id}/plugins', data=oidc_data)
        print(json.dumps(confirmation, indent=2))

    public_endpoints = config.get('public_endpoints', {})
    for endpoint_name, endpoint_url in public_endpoints.items():
        route_name = f'{name}_public_{endpoint_name}'
        PUBLIC_ROUTE_URL = f'{KONG_URL}services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{name}{endpoint_url}'],
            'strip_path': 'true',
        }
        confirmation = __post(url=PUBLIC_ROUTE_URL, data=route_data)
        print(json.dumps(confirmation, indent=2))


def register_app(realm, config):
    # Register Client with Kong
    # Single API Service
    name = config['name']  # app name
    url = config['service_url']  # service_url

    oidc_endpoints = config.get('oidc_endpoints', {})
    for endpoint_name, endpoint_url in oidc_endpoints.items():
        data = {
            'name': f'{name}_oidc_{endpoint_name}',
            'url': f'{url}{endpoint_url}'
        }
        __post(url=f'{KONG_URL}services/', data=data)
        print(f'Added oidc kong service component: {name}_public_{endpoint_name} for service: {name}')

    public_endpoints = config.get('public_endpoints', {})
    for endpoint_name, endpoint_url in public_endpoints.items():
        data = {
            'name': f'{name}_public_{endpoint_name}',
            'url': f'{url}{endpoint_url}'
        }
        __post(url=f'{KONG_URL}services/', data=data)
        print(f'Added public kong service component: {name}_public_{endpoint_name} for service: {name}')


def load_service_definitions():
    definitions = {}
    _files = os.listdir(SERVICES_PATH)
    for f in _files:
        with open(f'{SERVICES_PATH}/{f}') as _f:
            config = json.load(_f)
            service_name = config['name']
            definitions[service_name] = config
    return definitions


if __name__ == '__main__':
    REALM_NAME = sys.argv[1]
    SERVICE_NAME = sys.argv[2]
    SERVICE_DEFINITIONS = load_service_definitions()
    if not SERVICE_NAME in SERVICE_DEFINITIONS:
        raise KeyError(f'No service definition for name: {SERVICE_NAME}')
    service_config = SERVICE_DEFINITIONS[SERVICE_NAME]

    try:
        register_app(REALM_NAME, service_config)
    except Exception as err:
        print(f'Could not register service: {err}')
    print(f'Adding realm {REALM_NAME} to service: {SERVICE_NAME}')
    add_realm(REALM_NAME, service_config)
    print(f'Service {SERVICE_NAME} now being served by kong for realm {REALM_NAME}.')
