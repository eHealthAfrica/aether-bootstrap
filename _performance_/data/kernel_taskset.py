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

import random
import uuid

from locust import TaskSet, task

from settings import (
    NUMBER_OF_USERS,
    KERNEL_URL,

    TEST_USER,
    TEST_PASSWORD,
    TEST_REALM,
)


class KernelTaskSet(TaskSet):

    def on_start(self):
        user_id = random.randint(0, NUMBER_OF_USERS)
        user_name = f'{TEST_USER}-{user_id + 1}'
        print('Running with', user_name)

        self.client.get(
            url=f'{KERNEL_URL}/',
            name='/login',
            auth=(user_name, TEST_PASSWORD),
        )

        # create initial project
        self.create_avro_schemas()

    @task(1)
    def health_page(self):
        self.client.get(
            url=f'{KERNEL_URL}/health',
            name='/health',
        )

    @task(5)
    def view_projects(self):
        self.client.get(
            url=f'{KERNEL_URL}/projects',
            name='/projects',
        )

    @task(2)
    def create_avro_schemas(self):
        # get CSRFToken
        response = self.client.get(
            url=f'{KERNEL_URL}/projects?format=api&page_size=1',
            name='/projects',
        )

        csrftoken = response.cookies.get('csrftoken')

        project_id = str(uuid.uuid4())
        avro_schema = {
            'name': f'simple-{project_id}',
            'type': 'record',
            'fields': [
                {
                    'name': 'id',
                    'type': 'string',
                },
                {
                    'name': 'name',
                    'type': 'string',
                }
            ],
        }

        self.client.request(
            method='PATCH',
            url=f'{KERNEL_URL}/projects/{project_id}/avro-schemas',
            name='/projects/avro-schemas',
            json={
                'name': project_id,
                'avro_schemas': [
                    {
                        'id': project_id,
                        'definition': avro_schema,
                    },
                ],
            },
            headers={'X-CSRFToken': csrftoken},
        )

    @task(15)
    def create_submission(self):
        # get mappingset
        response = self.client.get(
            url=f'{KERNEL_URL}/mappingsets.json',
            name='/mappingsets',
        )
        data = response.json()
        if data['count'] == 0:
            return

        mappingset_id = data['results'][0]['id']
        submission_id = str(uuid.uuid4())
        submission_payload = {
            'id': submission_id,
            'name': f'Name {submission_id}',
        }

        # get CSRFToken
        response = self.client.get(
            url=f'{KERNEL_URL}/mappingsets?format=api&page_size=1',
            name='/mappingsets',
        )
        csrftoken = response.cookies.get('csrftoken')

        self.client.request(
            method='POST',
            url=f'{KERNEL_URL}/submissions.json',
            name='/submissions',
            json={
                'id': submission_id,
                'mappingset': mappingset_id,
                'payload': submission_payload,
            },
            headers={'X-CSRFToken': csrftoken},
        )
