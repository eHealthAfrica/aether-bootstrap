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

from aether.client import KernelClient
import json
import os
import requests
import sys

def env(key):
    return os.environ.get(key, None)

PROJECT_NAME = env('PROJECT_NAME')
SUBMISSION_ENDPOINT = env('SUBMISSION_ENDPOINT')

kernel_url = env('KERNEL_URL')

kernel_credentials = {
    "username": env('KERNEL_USER'),
    "password": env('KERNEL_PASSWORD')
    }

def file_to_json(path):
    with open(path) as f:
        return json.load(f)

def pprint(obj):
    print(json.dumps(obj, indent=2))


#Projects
project_obj = {
    "revision": "1",
    "name": PROJECT_NAME,
    "salad_schema": {"a": "schema"},
    "jsonld_context": "[]",
    "rdf_definition": "[]"
}

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

mapping_def = file_to_json("/code/assets/schemas/mapping.json")



mapping_obj = {
    "name": SUBMISSION_ENDPOINT,
    "definition": {"mapping": mapping_def},
    "revision": "1"
}

try:
    client = KernelClient(kernel_url, **kernel_credentials)
except requests.exceptions.RequestException:
    print("Kernel is ready. Please check it's status or wait a moment and try again.")
    sys.exit(1)

def register_project():
    return client.Resource.Project.add(project_obj)

def schema():
    return [client.Resource.Schema.add(obj) for obj in schemas]

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
        out[name] = client.Resource.ProjectSchema.add(project_schema_obj)
    return out

def mapping(project, ids):
    mapping_obj['definition']['entities'] = ids
    mapping_obj['project'] = project
    return client.Resource.Mapping.add(mapping_obj)

def register():
    project = register_project()
    project_id = project.get("id")
    if not project_id:
        print('project could not be registerd, does it already exist?')
        sys.exit(0)
    schema_info = schema()
    pprint(schema_info)
    schema_ids = {obj.get('name') : obj.get('id') for obj in schema_info}
    pprint(schema_ids)
    project_schemas = project_schema(project_id, schema_ids)
    pprint(project_schemas)
    ps_ids = {ps.get('name') : ps.get('id') for ps in project_schemas.values()}
    sub_id = mapping(project_id, ps_ids)
    pprint(sub_id)
    entity_references = sub_id.get('definition', {}).get('entities')


if __name__ == "__main__":
    reqs = ['KERNEL_URL' , 'KERNEL_USER', 'KERNEL_PASSWORD', 'SUBMISSION_ENDPOINT', 'PROJECT_NAME']
    if False in [env(r) for r in reqs]:
        log.error('Required Environment Variable is missing.')
        log.error('Required: %s' % (reqs,))
        sys.exit(1)
    register()


