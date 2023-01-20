#!/usr/bin/env bash
#
# Copyright (C) 2023 by eHealth Africa : http://www.eHealthAfrica.org
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

CERT_FOLDER="./.certs"
CERT_NAME="${CERT_FOLDER}/${BASE_DOMAIN}"

mkdir -p ${CERT_FOLDER}
rm -rf ${CERT_NAME}*

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

start_db
start_auth_container kong

echo_message "Installing self-signed certificate in kong..."
curl -s -i \
    -X PUT "http://localhost:8001/certificates/00000000-0000-0000-0000-000000000000" \
    -H 'Content-Type: application/json' \
    -d "{\"cert\":\"$(cat ${CERT_NAME}.crt)\",\"key\":\"$(cat ${CERT_NAME}.key)\",\"snis\":[\"${BASE_DOMAIN}\"]}" \
    --output "${CERT_NAME}-kong.log" \
    --write-out '%{http_code}'

echo ""
echo_success "Done!"
