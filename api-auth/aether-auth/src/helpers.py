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
from requests.exceptions import HTTPError

from settings import DEBUG


def request(*args, **kwargs):
    try:
        res = requests.request(*args, **kwargs)
        res.raise_for_status()
        if res.status_code != 204:
            try:
                data = res.json()
                __print(json.dumps(data, indent=2))
            except json.decoder.JSONDecodeError:
                data = res.content.decode('utf-8')
            return data
        return None
    except HTTPError as he:
        __handle_exception(he, res)
    except Exception as e:
        __handle_exception(e)


def __print(msg):
    if DEBUG:
        print(msg)


def __handle_exception(exception, res=None):
    __print('---------------------------------------')
    print(' >> ', str(exception))

    if res:
        print(' >>> ', res)
        if res.status_code != 204:
            __print(json.dumps(res.json(), indent=2))
    __print('---------------------------------------')
    raise exception
