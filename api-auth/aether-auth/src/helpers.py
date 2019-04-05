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
    try:
        res = requests.post(url, data=data)
        res.raise_for_status()
        data = res.json()
        _print(json.dumps(data, indent=2))
        return data
    except Exception as e:
        _handle_exception(e, res)


def request_get(url):
    try:
        res = requests.get(url)
        res.raise_for_status()
        data = res.json()
        _print(json.dumps(data, indent=2))
        return data
    except Exception as e:
        _handle_exception(e, res)


def request_delete(url):
    try:
        res = requests.delete(url)
        res.raise_for_status()
        data = res.text
        _print(data)
        return data
    except Exception as e:
        _handle_exception(e, res)


def _print(msg):
    if DEBUG:
        print(msg)


def _handle_exception(e, res):
    _print('---------------------------------------')
    _print(str(e))
    _print(res.status_code)
    if res.status_code != 204:
        _print(json.dumps(res.json(), indent=2))
    else:
        _print(res.text)
    _print('---------------------------------------')
    raise e
