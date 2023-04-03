#!/usr/bin/env python

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

import sys

from aether.client import Client

from utils import (
    RESOURCES_DIR,
    LOGGER,

    KERNEL_URL,
    KERNEL_USER,
    KERNEL_PASSWORD,
    CLIENT_LOGLEVEL,
    REALM,
    KEYCLOAK_URL,

    PROJECT_NAME,
    MAPPING_NAME,

    check_reqs,
    file_to_json,
)


def register_project():
    project_obj = {'name': PROJECT_NAME}
    return client.projects.create(data=project_obj)


def schema():
    schema_names = []
    schemas = []
    defs = file_to_json(f'{RESOURCES_DIR}/schemas/all.json')
    for obj in defs:
        name = obj.get('name')
        schema_names.append(name)
        schema_obj = {
            'name': name,
            'type': 'record',
            'revision': '1',
            'definition': obj
        }
        schemas.append(schema_obj)

    out = []
    for obj in schemas:
        try:
            out.append(client.schemas.create(data=obj))
        except Exception as err:
            LOGGER.error(err)
            LOGGER.error(obj)

    return out


def schema_decorator(project, ids):
    out = {}
    for name in ids.keys():
        schema_decorator_obj = {
            'revision': '1',
            'name': name,
            'schema': ids[name],
            'project': project,
        }
        out[name] = client.schemadecorators.create(data=schema_decorator_obj)

    return out


def mappingset(project):
    return client.mappingsets.create(
        data={
            'project': project,
            'name': 'default_set'
        }
    )


def mapping(project, mapping_set_id, ids):
    mapping_def = file_to_json(f'{RESOURCES_DIR}/mappings/mapping.json')
    mapping_obj = {
        'name': MAPPING_NAME,
        'definition': {
            'mapping': mapping_def,
            'entities': ids,
        },
        'revision': '1',
        'mappingset': mapping_set_id,
        'project': project,
    }
    return client.mappings.create(data=mapping_obj)


def register():
    project = register_project()
    project_id = project.id
    if not project_id:
        LOGGER.error('project could not be registered, does it already exist?')
        sys.exit(0)

    schema_info = schema()
    if not schema_info:
        raise ValueError('No schemas registered')
    LOGGER.debug(schema_info)

    schema_ids = {obj.name: obj.id for obj in schema_info}
    LOGGER.debug(schema_ids)

    schema_decorators = schema_decorator(project_id, schema_ids)
    LOGGER.debug(schema_decorators)

    ps_ids = {ps.name: ps.id for ps in schema_decorators.values()}
    ms = mappingset(project_id)
    sub_id = mapping(project_id, ms.id, ps_ids)
    LOGGER.debug(sub_id)


if __name__ == '__main__':

    check_reqs(reqs=[
        'KERNEL_URL',
        'KERNEL_USER',
        'KERNEL_PASSWORD',
        'PROJECT_NAME',
        'MAPPING_NAME',
    ])

    try:
        client = Client(KERNEL_URL, KERNEL_USER, KERNEL_PASSWORD,
                        log_level=CLIENT_LOGLEVEL,
                        realm=REALM,
                        keycloak_url=KEYCLOAK_URL)
    except Exception as err:
        LOGGER.error(
            f'Kernel is not ready. Please check '
            f'''it's status or wait a moment and try again : {err}''')
        sys.exit(1)

    register()
