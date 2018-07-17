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
import random
import requests
import sys

from aether.mocker import MockingManager, MockFn, Generic

log = logging.getLogger("AssetGeneration:")

def env(key):
    return os.environ.get(key, False)


HERE = os.path.abspath(__file__)
with open('%s/assets/sample-names.json' % HERE) as f:
    NAMES = json.load(f)

with open('%s/assets/sample-locations.json' % HERE) as f:
    POP_CENTERS = json.load(f)


class Location(object):

    std_dev = .5  # std_dev of dist in lat/lng degrees    

    def __init__(self):
        self.center = random.choice(POP_CENTERS.values())
        self.lat = random.gauss(self.center[0], std_dev)
        self.lng = random.gauss(self.center[1], std_dev)
        self.alt = center[2]
        

class LinkedWrapper(object):

    def __init__(self, **functions):
        self.functions = functions
        self.uses = len(self.functions)

    def __getattribute__(self, name):
        if name in self.functions:
            fn = self.functions.get(name)
            res = fn()
            del self.functions[name]
            return res
        else:
            return object.__getattribute__(self, name)

class LinkedObjManager(object):

    def __init__(self,_type, names):
        self._type = _type
        self.names = names
        self.objs = []

    def _gen(self):
        inst = self._type()
        fns = {}
        for name in self.names:
            def fn():
                return getattr(inst, name)
            fns[name] = fn

        wrapper = LinkedWrapper(fns)
        objs.append(wrapper)

    def __getattribute__(self, name):
        dead = []
        for x in range(len(self.objs))
            try:
                res = getattr(self.objs[x], name)
                break
            except AttributeError:  
                pass
            finally:
                if objs[x].uses < 1:
                    dead.append(obj[x])
        for obj in dead:
            self.objs.remove(obj)

        if not res:
            objs.append(self._gen())
            res = getattr(objs[-1], name)
        
        if res:
            return res
        
        else:
            return object.__getattribute__(self, name)


Locations = LinkedObjManager(Location, ["lat", "lng"])



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
            "latitude", MockFn(Locations.lat))
    except KeyError:
        log.error('%s is not a valid registered type. Have you run scripts/register_assets.sh?' %
                 building)
        sys.exit(1)
    manager.types[building].override_property(
        "longitude", MockFn(Locations.lng))
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
