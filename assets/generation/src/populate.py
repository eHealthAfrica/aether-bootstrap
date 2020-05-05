#!/usr/bin/env python

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
import sys

from mocker import MockingManager, MockFn

from utils import (
    RESOURCES_DIR,
    LOGGER,

    KERNEL_URL,
    KERNEL_USER,
    KERNEL_PASSWORD,
    CLIENT_LOGLEVEL,
    REALM,
    KEYCLOAK_URL,

    check_reqs,
    file_to_json,
)

class SimpleResource(object):

    def _get(self, arg):
        try:
            res = getattr(self, arg)
        except Exception:
            res = None

        if not res:
            self._gen()
            return self._get(arg)

        setattr(self, arg, None)
        return res

    def __getattribute__(self, name):
        if not name.startswith('get_'):
            return object.__getattribute__(self, name)

        else:
            def fn():
                return self._get(name.split('get_')[1])
            return fn


class Location(SimpleResource):

    std_dev = .5  # std_dev of dist in lat/lng degrees

    def _gen(self):
        locations = [i for i in POP_CENTERS.values()]
        self.center = random.choice(locations)
        self.lat = random.gauss(self.center[0], Location.std_dev)
        self.lng = random.gauss(self.center[1], Location.std_dev)
        self.alt = 1.0 * self.center[2]
        self.acc = 10.0
        self.btype = random.choice(['house', 'duplex', 'apartment'])


class Person(SimpleResource):

    def _gen(self):
        self.sex = random.choice(['male', 'female'])
        name_gender = 'boys' if self.sex == 'male' else 'girls'
        self.name = random.choice(NAMES.get(name_gender))
        self.age = random.randint(0, 99)


LOCATION = Location()
PERSON = Person()


def main(seed_size=1000):
    SEED_ENTITIES = seed_size
    manager = None
    building = 'eha.aether.clusterdemo.Building'
    person = 'eha.aether.clusterdemo.Person'

    manager = MockingManager(KERNEL_URL, KERNEL_USER, KERNEL_PASSWORD,
                             CLIENT_LOGLEVEL, REALM, KEYCLOAK_URL)
    for i in manager.types.keys():
        LOGGER.error(i)

    for k, v in manager.names.items():
        LOGGER.error([k, v])

    try:
        manager.types[building].override_property(
            'latitude', MockFn(LOCATION.get_lat))
    except KeyError:
        LOGGER.error(
            '%s is not a valid registered type. Have you run scripts/register_assets.sh?' %
            building)
        sys.exit(1)

    manager.types[building].override_property('longitude', MockFn(LOCATION.get_lng))
    manager.types[building].override_property('altitude', MockFn(LOCATION.get_alt))
    manager.types[building].override_property('accuracy', MockFn(LOCATION.get_acc))
    manager.types[building].override_property('building_type', MockFn(LOCATION.get_btype))

    manager.types[person].override_property('occupant_age', MockFn(PERSON.get_age))
    manager.types[person].override_property('occupant_gender', MockFn(PERSON.get_sex))
    manager.types[person].override_property('occupant_name', MockFn(PERSON.get_name))

    for _ in range(SEED_ENTITIES):
        manager.register(person)
        for mocker in manager.types.values():
            if mocker.killed:
                manager.kill()
                return
            break

    manager.kill()


if __name__ == '__main__':
    check_reqs(reqs=['KERNEL_URL', 'KERNEL_USER', 'KERNEL_PASSWORD'])

    NAMES = file_to_json(f'{RESOURCES_DIR}/sample-names.json')
    POP_CENTERS = file_to_json(f'{RESOURCES_DIR}/sample-locations.json')

    args = sys.argv
    seed = 1000
    try:
        if len(args) > 1 and isinstance(int(args[1]), int):
            seed = int(args[1])
    except ValueError:
        pass

    main(seed_size=seed)
