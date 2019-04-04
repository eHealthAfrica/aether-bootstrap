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
import sys

from keycloak import KeycloakAdmin, KeycloakOpenID
from keycloak.exceptions import KeycloakError
from requests.exceptions import HTTPError

from helpers import request_post, request_get, request_delete
from settings import (
    HOST,
    DOMAIN,

    KONG_URL,

    KC_URL,
    KC_ADMIN_USER,
    KC_ADMIN_PASSWORD,
    KC_MASTER_REALM,
    KEYCLOAK_KONG_CLIENT,

    SERVICES_PATH,
    SOLUTIONS_PATH,
)


def _realm_in_service(realm, service):
    return any([path.strip('/').startswith(realm) for path in service['paths']])


def add_service_to_realm(realm, config):

    service_name = config['name']
    client_id = KEYCLOAK_KONG_CLIENT
    client_secret = None


    try:
        # https://bitbucket.org/agriness/python-keycloak

        # find out client secret

        # connect ot master realm
        keycloak_admin = KeycloakAdmin(server_url=KC_URL,
                                       username=KC_ADMIN_USER,
                                       password=KC_ADMIN_PASSWORD,
                                       realm_name=KC_MASTER_REALM,
                                       )
        # change to our realm
        keycloak_admin.realm_name = realm
        # get kong client internal id
        client_pk = keycloak_admin.get_client_id(client_id)
        # get its secrets
        secret = keycloak_admin.get_client_secrets(client_pk)
        client_secret = secret.get('value')
        # get its well known info
        keycloak_openid = KeycloakOpenID(server_url=KC_URL,
                                         realm_name=realm,
                                         client_id=client_id,
                                         client_secret_key=client_secret,
                                         )
        config_well_know = keycloak_openid.well_know()

    except KeycloakError as ke:
        raise RuntimeError(f'Could not get info from keycloak  {str(ke)}')
    except Exception  as e:
        raise RuntimeError(f'Unexpected error, do the realm and the client exist?  {str(e)}')

    # OIDC plugin settings (same for all)
    oidc_data = {
        'name': f'{client_id}-oidc-auth',
        'config.app_login_redirect_url': f'{HOST}/{realm}/{service_name}/',
        'config.authorize_url': config_well_know['authorization_endpoint'],
        'config.client_id': client_id,
        'config.client_secret': client_secret,
        'config.cookie_domain': DOMAIN,
        'config.email_key': 'email',
        'config.scope': 'openid+profile+email+iss',
        'config.service_logout_url': config_well_know['end_session_endpoint'],
        'config.token_url': config_well_know['token_endpoint'],
        'config.user_info_cache_enabled': 'true',
        'config.user_url': config_well_know['userinfo_endpoint'],
    }

    oidc_endpoints = config.get('oidc_endpoints', [])
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        strip_path = json.dumps(ep['strip_path'])

        route_name = f'{service_name}_oidc_{endpoint_name}'
        ROUTE_URL = f'{KONG_URL}/services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{service_name}{endpoint_url}'],
            'strip_path': strip_path,
        }
        route_info = request_post(url=ROUTE_URL, data=route_data)
        protected_route_id = route_info['id']

        request_post(
            url=f'{KONG_URL}/routes/{protected_route_id}/plugins',
            data=oidc_data
        )

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        endpoint_url = ep['url']
        strip_path = json.dumps(ep['strip_path'])
        route_name = f'{service_name}_public_{endpoint_name}'
        PUBLIC_ROUTE_URL = f'{KONG_URL}/services/{route_name}/routes'
        route_data = {
            'paths': [f'/{realm}/{service_name}{endpoint_url}'],
            'strip_path': strip_path,
        }
        request_post(url=PUBLIC_ROUTE_URL, data=route_data)


def remove_service_from_realm(realm, config):
    name = config['name']  # app name
    oidc_endpoints = config.get('oidc_endpoints', [])
    print(f'Removing service {config["name"]} from realm {realm}')
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_oidc_{endpoint_name}'
        routes_url = f'{KONG_URL}/services/{service_name}/routes'
        res = request_get(routes_url)
        for service in res['data']:
            if _realm_in_service(realm, service):
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}/routes/{service["id"]}'
                request_delete(remove_url)

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_public_{endpoint_name}'
        routes_url = f'{KONG_URL}/services/{service_name}/routes'
        res = request_get(routes_url)
        for service in res['data']:
            if _realm_in_service(realm, service):
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}/routes/{service["id"]}'
                request_delete(remove_url)


def remove_service(config):
    name = config['name']  # app name
    print(f'Removing service {config["name"]} from ALL')
    oidc_endpoints = config.get('oidc_endpoints', [])
    for ep in oidc_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_oidc_{endpoint_name}'
        routes_url = f'{KONG_URL}/services/{service_name}/routes'
        try:
            res = request_get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}/routes/{service["id"]}'
                try:
                    request_delete(remove_url)
                except HTTPError:
                    print(f'Could not remove endpoint {endpoint_name}')
        except HTTPError:
            print(f'Route not found at {routes_url}')

    public_endpoints = config.get('public_endpoints', [])
    for ep in public_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_public_{endpoint_name}'
        routes_url = f'{KONG_URL}/services/{service_name}/routes'
        try:
            res = request_get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}/routes/{service["id"]}'
                try:
                    request_delete(remove_url)
                except HTTPError:
                    print(f'Could not remove endpoint {endpoint_name}')
        except HTTPError:
            print(f'Route not found at {routes_url}')

    global_endpoints = config.get('global_public_endpoints', [])
    for ep in global_endpoints:
        endpoint_name = ep['name']
        service_name = f'{name}_global_{endpoint_name}'
        routes_url = f'{KONG_URL}/services/{service_name}/routes'
        try:
            res = request_get(routes_url)
            for service in res['data']:
                print(f'Removing {service["paths"]}')
                remove_url = f'{KONG_URL}/routes/{service["id"]}'
                try:
                    request_delete(remove_url)
                except HTTPError:
                    print(f'Could not remove endpoint {endpoint_name}')
        except HTTPError:
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
            request_post(url=f'{KONG_URL}/services/', data=data)
            print(f'Added oidc kong service component: '
                  f'{name}_public_{endpoint_name} for service: {name}')
        except HTTPError:
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
            request_post(url=f'{KONG_URL}/services/', data=data)
            print(f'Added public kong service component: '
                  f'{name}_public_{endpoint_name} for service: {name}')
        except HTTPError:
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
            request_post(url=f'{KONG_URL}/services/', data=data)
            print(f'Added global kong service component: '
                  f'{service_name} for service: {name}')
        except HTTPError as err:
            print(f'Global service exists: {err}')

        PUBLIC_ROUTE_URL = f'{KONG_URL}/services/{service_name}/routes'
        route_data = {
            'paths': [f'{endpoint_url}'],
            'strip_path': strip_path,
        }
        try:
            request_post(url=PUBLIC_ROUTE_URL, data=route_data)
        except HTTPError:
            print(f'Could not add endpoint {endpoint_name}')


def load_definitions(def_path):
    definitions = {}
    _files = os.listdir(def_path)

    for f in _files:
        with open(f'{def_path}/{f}') as _f:
            config = json.load(_f)
            name = config['name']
            definitions[name] = config
    return definitions


def handle_service(realm, service, command):
    if service not in SERVICE_DEFINITIONS:
        raise KeyError(f'No service definition for name: {service}')

    service_config = SERVICE_DEFINITIONS[service]
    if command == 'ADD':
        try:
            register_app(realm, service_config)
        except Exception as err:
            print(f'Could not register service: {err}')

        print(f'Adding realm {realm} to service: {service}')
        add_service_to_realm(realm, service_config)
        print(f'Service {service} now being served by kong for realm {realm}.')

    elif command == 'REMOVE':
        if realm in ['ALL', '*']:
            remove_service(service_config)
        else:
            remove_service_from_realm(realm, service_config)


def handle_solution(realm, solution, command):
    if solution not in SOLUTION_DEFINITIONS:
        raise KeyError(f'No Solution definition for name: {solution}')

    services = SOLUTION_DEFINITIONS[solution]['services']
    for service in services:
        handle_service(realm, service, command)


CMDS = ['ADD', 'REMOVE']
TYPES = ['SERVICE', 'SOLUTION']

if __name__ == '__main__':
    CMD = sys.argv[1]
    if CMD not in CMDS:
        raise KeyError(f'No command: {CMD}')

    TYPE = sys.argv[2]
    if TYPE not in TYPES:
        raise KeyError(f'No type: {TYPE}')

    SERVICE_NAME = sys.argv[3]
    REALM_NAME = sys.argv[4]

    SERVICE_DEFINITIONS = load_definitions(SERVICES_PATH)
    SOLUTION_DEFINITIONS = load_definitions(SOLUTIONS_PATH)

    if TYPE == 'SERVICE':
        handle_service(REALM_NAME, SERVICE_NAME, CMD)

    if TYPE == 'SOLUTION':
        handle_solution(REALM_NAME, SERVICE_NAME, CMD)
