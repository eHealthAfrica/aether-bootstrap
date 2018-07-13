#!/usr/bin/env bash
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


# Define help message
show_help() {
    echo """
    Commands
    ----------------------------------------------------------------------------
    bash          : run bash
    eval          : eval shell command
    pip_freeze    : freeze pip dependencies and write to requirements.txt

    register      : register types in /assets
    generate      : create mock types from registered assets

    """
}

case "$1" in
    bash )
        bash
    ;;

    eval )
        eval "${@:2}"
    ;;

    pip_freeze )

        rm -rf /tmp/env
        pip3 install -f ./pip/requires -r ./pip/primary-requirements.txt --upgrade

        cat pip/requirements_header.txt | tee pip/requirements.txt
        pip3 freeze --local | grep -v appdir | tee -a pip/requirements.txt
    ;;

    register )
        python register.py "${@:2}"
    ;;

    generate )
        python populate.py "${@:2}"
    ;;

    help)
        show_help
    ;;

    *)
        show_help
    ;;
esac
