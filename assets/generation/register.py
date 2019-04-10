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

from aether.client import Client
import json
import os
import sys

def env(key):
    return os.environ.get(key, None)

PROJECT_NAME = env('PROJECT_NAME')
SUBMISSION_ENDPOINT = env('SUBMISSION_ENDPOINT')
kernel_url = env('KERNEL_URL')
user = env('KERNEL_USER')
pw = env('KERNEL_PASSWORD')

try:
    client = Client(kernel_url, user, pw)
except Exception as err:
    print("Kernel is not ready. Please check it's status or wait a moment and try again : %s" % err)
    sys.exit(1)


def file_to_json(path):
    with open(path) as f:
        return json.load(f)

def pprint(obj):
    print(obj)

def register_project():
    project_obj = { "name": PROJECT_NAME }
    return client.projects.create(data=project_obj)

def schema():
    schema_names = []
    schemas = []
    defs = file_to_json("/code/assets/schemas/all.json")
    for obj in defs:
        name = obj.get('name')
        schema_names.append(name)
        schema_obj = {
            "name": name,
            "type": "record",
            "revision": "1",
            "definition": obj
        }
        schemas.append(schema_obj)
    out = []
    for obj in schemas:
        try:
            out.append(client.schemas.create(data=obj))
        except Exception as err:
            print(err)
            print(obj)
    return out


def project_schema(project, ids):
    out = {}
    for name in ids.keys():
        project_schema_obj = {
            "revision": "1",
            "name": name,
            "schema": ids[name],
            "project": project,
            "masked_fields": "[]",
            "transport_rule": "[]",
            "mandatory_fields": "[]"
        }
        out[name] = client.projectschemas.create(data=project_schema_obj)
    return out

def mappingset(project):
    return client.mappingsets.create(data={
            "project": project,
            "name": "default_set"}
        )

def mapping(project, mapping_set_id, ids):
    mapping_def = file_to_json("/code/assets/schemas/mapping.json")
    mapping_obj = {
        "name": SUBMISSION_ENDPOINT,
        "definition": {"mapping": mapping_def},
        "revision": "1"
    }
    mapping_obj['definition']['entities'] = ids
    mapping_obj['mappingset'] = mapping_set_id
    mapping_obj['project'] = project
    return client.mappings.create(data=mapping_obj)

def register():
    project = register_project()
    project_id = project.id
    if not project_id:
        print('project could not be registerd, does it already exist?')
        sys.exit(0)
    schema_info = schema()
    pprint(schema_info)
    schema_ids = {obj.name : obj.id for obj in schema_info}
    pprint(schema_ids)
    project_schemas = project_schema(project_id, schema_ids)
    pprint(project_schemas)
    ps_ids = {ps.name : ps.id for ps in project_schemas.values()}
    ms = mappingset(project_id)
    sub_id = mapping(project_id, ms.id, ps_ids)
    pprint(sub_id)
    entity_references = sub_id.definition.get('entities')


if __name__ == "__main__":
    reqs = ['KERNEL_URL' , 'KERNEL_USER', 'KERNEL_PASSWORD', 'SUBMISSION_ENDPOINT', 'PROJECT_NAME']
    if False in [env(r) for r in reqs]:
        log.error('Required Environment Variable is missing.')
        log.error('Required: %s' % (reqs,))
        sys.exit(1)
    register()


