#!/bin/bash
#
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
#
set -Eeuo pipefail

show_help () {
    echo """
    Commands
    ----------------------------------------------------------------------------
    bash                                : run bash
    eval                                : eval shell command

    make_realm                          : create realms from the artifacts in /code/realm
    setup_auth                          : register keycloak and in Kong.
    register_service {realm} {service}  : register aether app/realm in Kong.

    """
}

case "$1" in
    bash )
        bash
    ;;

    eval )
        eval "${@:2}"
    ;;

    make_realm )
        # setups realms from those available in /realm folder
        python /code/src/make_realm.py
    ;;

    setup_auth )
        # add keycloak to Kong
        python /code/src/register_keycloak.py keycloak    ${KEYCLOAK_INTERNAL}
    ;;

    register_service )
        # adds a service to an existing realm, using the service definition
        # in /service
        # usage: register_service {realm} {service}
        python /code/src/register_service.py "${@:2}"
    ;;

    help )
        show_help
    ;;

    * )
        show_help
    ;;
esac
