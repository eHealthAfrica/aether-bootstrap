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


def __get(url):
    res = requests.get(url)
    try:
        res.raise_for_status()
        return res.json()
    except Exception as e:
        print(res.status_code)
        print(res.json())
        raise e


def __delete(url):
    res = requests.delete(url)
    try:
        res.raise_for_status()
        return res.text
    except Exception as e:
        print(res.status_code)
        raise e


def add_service_to_realm(realm, config):

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

    oidc_endpoints = config.get('oidc_endpoints', [])
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        strip_path = json.dumps(ep['strip_path'])

        route_name = f'{name}_oidc_{endpoint_name}'
        ROUTE_URL = f'{KONG_URL}services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{name}{endpoint_url}'],
            'strip_path': strip_path,
        }
        route_info = __post(url=ROUTE_URL, data=route_data)
        print(json.dumps(route_info, indent=2))
        protected_route_id = route_info['id']

        confirmation = __post(
            url=f'{KONG_URL}routes/{protected_route_id}/plugins',
            data=oidc_data
        )
        print(json.dumps(confirmation, indent=2))

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        strip_path = json.dumps(ep['strip_path'])
        print(f'{endpoint_name} | {endpoint_url} | {strip_path}')
        route_name = f'{name}_public_{endpoint_name}'
        PUBLIC_ROUTE_URL = f'{KONG_URL}services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{name}{endpoint_url}'],
            'strip_path': strip_path,
        }
        confirmation = __post(url=PUBLIC_ROUTE_URL, data=route_data)
        print(json.dumps(confirmation, indent=2))


def remove_service_from_realm(realm, config):
    name = config['name']  # app name
    oidc_endpoints = config.get('oidc_endpoints', [])
    print(f'Removing service {config["name"]} from realm {realm}')
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_oidc_{endpoint_name}'
        routes_url = f'{KONG_URL}services/{service_name}/routes'
        res = __get(routes_url)
        for service in res['data']:
            remove = any([path.strip('/').startswith(realm)
                         for path in service['paths']])
            if remove:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}routes/{service["id"]}'
                res = __delete(remove_url)
                print(res)

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_public_{endpoint_name}'
        routes_url = f'{KONG_URL}services/{service_name}/routes'
        res = __get(routes_url)
        for service in res['data']:
            remove = any([path.strip('/').startswith(realm)
                         for path in service['paths']])
            if remove:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}routes/{service["id"]}'
                res = __delete(remove_url)
                print(res)


def remove_service(config):
    name = config['name']  # app name
    print(f'Removing service {config["name"]} from ALL')
    oidc_endpoints = config.get('oidc_endpoints', [])
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_oidc_{endpoint_name}'
        routes_url = f'{KONG_URL}services/{service_name}/routes'
        try:
            res = __get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}routes/{service["id"]}'
                try:
                    res = __delete(remove_url)
                    print(res)
                except requests.exceptions.HTTPError:
                    print(f'Could not add endpoint {endpoint_name}')
        except requests.exceptions.HTTPError:
            print(f'Route not found at {routes_url}')

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_public_{endpoint_name}'
        routes_url = f'{KONG_URL}services/{service_name}/routes'
        try:
            res = __get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}routes/{service["id"]}'
                try:
                    res = __delete(remove_url)
                    print(res)
                except requests.exceptions.HTTPError:
                    print(f'Could not add endpoint {endpoint_name}')
        except requests.exceptions.HTTPError:
            print(f'Route not found at {routes_url}')

    global_endpoints = config.get('global_public_endpoints', [])
    for ep in global_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_global_{endpoint_name}'
        routes_url = f'{KONG_URL}services/{service_name}/routes'
        try:
            res = __get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}routes/{service["id"]}'
                try:
                    res = __delete(remove_url)
                    print(res)
                except requests.exceptions.HTTPError:
                    print(f'Could not add endpoint {endpoint_name}')
        except requests.exceptions.HTTPError:
            print(f'Route not found at {routes_url}')


def register_app(realm, config):
    # Register Client with Kong
    # Single API Service
    name = config['name']  # app name
    url = config['service_url']  # service_url

    oidc_endpoints = config.get('oidc_endpoints', [])
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        data = {
            'name': f'{name}_oidc_{endpoint_name}',
            'url': f'{url}{endpoint_url}'
        }
        try:
            __post(url=f'{KONG_URL}services/', data=data)
            print(f'Added oidc kong service component: '
                  f'{name}_public_{endpoint_name} for service: {name}')
        except requests.exceptions.HTTPError:
            print(f'Could not add endpoint {endpoint_name}')

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']

        data = {
            'name': f'{name}_public_{endpoint_name}',
            'url': f'{url}{endpoint_url}'
        }
        try:
            __post(url=f'{KONG_URL}services/', data=data)
            print(f'Added public kong service component: '
                  f'{name}_public_{endpoint_name} for service: {name}')
        except requests.exceptions.HTTPError:
            print(f'Could not add endpoint {endpoint_name}')

    global_endpoints = config.get('global_public_endpoints', [])
    for ep in global_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        strip_path = json.dumps(ep['strip_path'])
        service_name = f'{name}_global_{endpoint_name}'
        data = {
            'name': service_name,
            'url': f'{url}{endpoint_url}'
        }
        try:
            __post(url=f'{KONG_URL}services/', data=data)
            print(f'Added global kong service component: '
                  f'{service_name} for service: {name}')
        except requests.exceptions.HTTPError as err:
            print(f'Global service exists: {err}')

        PUBLIC_ROUTE_URL = f'{KONG_URL}services/{service_name}/routes'
        route_data = {
            'paths': [f'{endpoint_url}'],
            'strip_path': strip_path,
        }
        try:
            confirmation = __post(url=PUBLIC_ROUTE_URL, data=route_data)
            print(json.dumps(confirmation, indent=2))
        except requests.exceptions.HTTPError:
            print(f'Could not add endpoint {endpoint_name}')


def load_service_definitions():
    definitions = {}
    _files = os.listdir(SERVICES_PATH)
    for f in _files:
        with open(f'{SERVICES_PATH}/{f}') as _f:
            config = json.load(_f)
            service_name = config['name']
            definitions[service_name] = config
    return definitions


CMDS = ['ADD', 'REMOVE']

if __name__ == '__main__':
    REALM_NAME = sys.argv[1]
    SERVICE_NAME = sys.argv[2]
    CMD = sys.argv[3]
    if CMD not in CMDS:
        raise KeyError(f'No command: {CMD}')
    SERVICE_DEFINITIONS = load_service_definitions()
    if SERVICE_NAME not in SERVICE_DEFINITIONS:
        raise KeyError(f'No service definition for name: {SERVICE_NAME}')
    service_config = SERVICE_DEFINITIONS[SERVICE_NAME]
    if CMD == 'ADD':
        try:
            register_app(REALM_NAME, service_config)
        except Exception as err:
            print(f'Could not register service: {err}')
        print(f'Adding realm {REALM_NAME} to service: {SERVICE_NAME}')
        add_service_to_realm(REALM_NAME, service_config)
        print(f'Service {SERVICE_NAME} now being served '
              f'by kong for realm {REALM_NAME}.')
    elif CMD == 'REMOVE':
        if REALM_NAME == "ALL":
            remove_service(service_config)
        else:
            remove_service_from_realm(REALM_NAME, service_config)
