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
import requests

from settings import DEBUG


def request_post(url, data):
    res = requests.post(url, data=data)
    try:
        res.raise_for_status()
        data = res.json()

        if DEBUG:
            print(json.dumps(data, indent=2))
        return data

    except Exception as e:
        print(res.status_code)
        print(res.json())
        raise e


def request_get(url):
    res = requests.get(url)
    try:
        res.raise_for_status()
        data = res.json()

        if DEBUG:
            print(json.dumps(data, indent=2))
        return data

    except Exception as e:
        print(res.status_code)
        print(res.json())
        raise e


def request_delete(url):
    res = requests.delete(url)
    try:
        res.raise_for_status()
        data = res.text

        if DEBUG:
            print(data)
        return data

    except Exception as e:
        print(res.status_code)
        print(res.text)
        raise e
