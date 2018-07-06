from aether.client import KernelClient
import json
import sys

PROJECT_NAME = "ClusterDemo"
SUBMISSION_ENDPOINT = "cluster_mapping"

kernel_url = "http://localhost:8000"

kernel_credentials ={
    "username": "admin-kernel",
    "password": "adminadmin",
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
defs = file_to_json("../schemas/all.json")
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

mapping_def = file_to_json("../schemas/mapping.json")



mapping_obj = {
    "name": SUBMISSION_ENDPOINT,
    "definition": {"mapping": mapping_def},
    "revision": "1"
}

client = KernelClient(kernel_url, **kernel_credentials)

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
        print('project already exists')
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
    if entity_references:
        with open('./references.json', 'w') as f:
            json.dump(entity_references, f)


if __name__ == "__main__":
    register()


