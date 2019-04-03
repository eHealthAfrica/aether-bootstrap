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
    bash             : run bash
    eval             : eval shell command

    setup_auth       : register Keycloak in Kong.

    add_service      : adds a service to an existing realm in Kong,
                       using the service definition in /service directory.

                       usage: add_service {service} {realm}

    remove_service   : removes a service from an existing realm in Kong,
                       using the service definition in /service directory.

                       usage: remove_service {service} {realm}

    add_solution     : adds a package of services to an existing realm in Kong,
                       using the solution definition in /solution directory.

                       usage: add_solution {solution} {realm}

    remove_solution  : removes a package of services from an existing realm in Kong,
                       using the solution definition in /solution directory.

                       usage: remove_solution {solution} {realm}

    """
}

case "$1" in
    bash )
        bash
    ;;

    eval )
        eval "${@:2}"
    ;;

    setup_auth )
        # add Keycloak to Kong
        python /code/src/register_keycloak.py keycloak ${KEYCLOAK_INTERNAL}
    ;;

    add_service )
        # adds a service to an existing realm,
        # using the service definition in /service
        # usage: add_service {service} {realm}
        python /code/src/manage_service.py ADD SERVICE "${@:2}"
    ;;

    remove_service )
        # removes a service from an existing realm,
        # using the service definition in /service
        # usage: remove_service {service} {realm}
        python /code/src/manage_service.py REMOVE SERVICE "${@:2}"
    ;;

    add_solution )
        # adds a package of services to an existing realm,
        # using the solution definition in /solution
        # usage: add_solution {solution} {realm}
        python /code/src/manage_service.py ADD SOLUTION "${@:2}"
    ;;

    remove_solution )
        # removes a package of services from an existing realm,
        # using the solution definition in /solution
        # usage: remove_solution {solution} {realm}
        python /code/src/manage_service.py REMOVE SOLUTION "${@:2}"
    ;;

    help )
        show_help
    ;;

    * )
        show_help
    ;;
esac
