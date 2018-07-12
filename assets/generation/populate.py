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

import logging
import os
import requests
import sys

from aether.mocker import MockingManager, MockFn, Generic

log = logging.getLogger("AssetGeneration:")

def env(key):
    return os.environ.get(key, False)

def main(seed_size=1000):
    SEED_ENTITIES = seed_size
    entities = []
    manager = None
    survey = "eha.aether.clusterdemo.Survey"
    building = "eha.aether.clusterdemo.Building"
    household = "eha.aether.clusterdemo.HouseHold"
    person = "eha.aether.clusterdemo.Person"
    kernel_credentials ={
        "username": env('KERNEL_USER'),
        "password": env('KERNEL_PASSWORD'),
    }
    try:
        manager = MockingManager(kernel_url=env('KERNEL_URL'), kernel_credentials=kernel_credentials)
    except requests.exceptions.RequestException:
        log.error("Kernel is not ready or not available. Check settings or try again.")
        sys.exit(1)
    for i in manager.types.keys():
        print(i)
    for k,v in manager.names.items():
        print(k,v)
    try:
        manager.types[building].override_property(
            "latitude", MockFn(Generic.geo_lat))
    except KeyError:
        log.error('%s is not a valid registered type. Have you run scripts/register_assets.sh?' %
                 building)
        sys.exit(1)
    manager.types[building].override_property(
        "longitude", MockFn(Generic.geo_lng))
    for x in range(SEED_ENTITIES):
        entity = manager.register(person)
        for name, mocker in manager.types.items():
            if mocker.killed:
                manager.kill()
                return
            break
    manager.kill()

if __name__ == "__main__":
    reqs = ['KERNEL_URL' , 'KERNEL_USER', 'KERNEL_PASSWORD']
    if False in [env(r) for r in reqs]:
        log.error('Required Environment Variable is missing.')
        log.error('Required: %s' % (reqs,))
        sys.exit(1)
    args = sys.argv
    seed = 1000
    try:
        if len(args) > 1 and isinstance(int(args[1]), int):
            seed = int(args[1])
    except ValueError:
        pass
    main(seed_size=seed)
