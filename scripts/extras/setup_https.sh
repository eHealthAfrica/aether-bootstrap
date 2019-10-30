#!/usr/bin/env bash
#
# Copyright (C) 2019 by eHealth Africa : http://www.eHealthAfrica.org
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

source scripts/lib.sh || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source .env

CERT_FOLDER="./.persistent_data/certs"
CERT_NAME="${CERT_FOLDER}/${BASE_DOMAIN}"

function gen_local_cert {
    mkdir -p ${CERT_FOLDER}
    rm -Rf ${CERT_NAME}*

    echo_message "Generating self-signed certificate for ${BASE_DOMAIN}..."
    openssl genrsa -out ${CERT_NAME}.key 4096

    openssl req -new \
        -key ${CERT_NAME}.key \
        -out ${CERT_NAME}.csr \
        -subj "/O=eHealth Africa/OU=Aether Team/CN=${BASE_DOMAIN}"

    openssl x509 -req \
        -days 365 \
        -in ${CERT_NAME}.csr \
        -signkey ${CERT_NAME}.key \
        -out ${CERT_NAME}.crt

    # --------------------------------------------------------------------------
    # workaround for self signed certificates
    # include our certificate in the official certificate authority (CA) bundle
    echo_message "Creating workaround for self-signed certificates and python containers..."
    python3 -m pip install -q --upgrade --target=${CERT_FOLDER} certifi
    PY_CERT="${CERT_FOLDER}/certifi/cacert.pem"
    mv ${PY_CERT} ${PY_CERT}.original
    cat ${CERT_NAME}.crt ${PY_CERT}.original > ${PY_CERT}
    # --------------------------------------------------------------------------

    start_db
    start_auth_container kong

    echo_message "Installing self-signed certificate in kong..."
    curl -i -X PUT "http://localhost:8001/certificates/00000000-0000-0000-0000-000000000000" \
        -H 'Content-Type: application/json' \
        -d "{\"cert\":\"$(cat ${CERT_NAME}.crt)\",\"key\":\"$(cat ${CERT_NAME}.key)\",\"snis\":[\"${BASE_DOMAIN}\"]}"
}

function instructions {
    cat << EOF

--------------------------------------------------------------------------------

The self-signed certificate for ${BASE_DOMAIN} was included in the certificates
list stored in [${PY_CERT}] and installed in kong.
Please follow the next points to finish the local setup.

--------------------------------------------------------------------------------

1. Change in your [.env] file the following:

BASE_PROTOCOL=https
CERT_FOLDER=${CERT_FOLDER}
KEYCLOAK_SERVER_URL=https://${BASE_DOMAIN}/auth/realms

--------------------------------------------------------------------------------

2. Add in your auth/docker-compose.yml file in the kong service the following:

  kong:
    environment:
      KONG_PROXY_LISTEN: 0.0.0.0:80, ssl 0.0.0.0:443
    ports:
      - 443:443

--------------------------------------------------------------------------------

3. Add to your {module}/docker-compose.yml file the following volume entry
in each service that uses https to communicate internally with
the rest of services (kernel, odk, ui, gather):

    volumes:
      # -------------------------------------------------------------
      # DO NOT USE THIS WORKAROUND IN ANY PRODUCTION ENVIRONMENT!!!
      - ${CERT_FOLDER}/certifi:/usr/local/lib/python3.7/site-packages/certifi
      # -------------------------------------------------------------

--------------------------------------------------------------------------------

OPTIONAL

4. Install the [${BASE_DOMAIN}.crt] file in your Android device certificates list
Follow this link instructions: https://support.google.com/nexus/answer/2844832
Maybe you'll need to reboot the device afterwards.
Most probably this doesn't work at all.

--------------------------------------------------------------------------------
EOF
}

gen_local_cert
instructions
