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

source .env || \
    ( echo -e "\033[91mRun this script from root folder\033[0m" && \
      exit 1 )
source options.txt

function gen_kafka_creds {
    cat << EOF
KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required;
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="$KAFKA_CONSUMER_USER"
    password="$KAFKA_CONSUMER_PASSWORD"
    user_$KAFKA_CONSUMER_USER="$KAFKA_CONSUMER_PASSWORD";
};
Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="$ZOOKEEPER_ROOT_USER"
    password="$ZOOKEEPER_ROOT_PASSWORD";
};
EOF
}

function gen_zookeeper_creds {
    cat << EOF
Server {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    user_$ZOOKEEPER_ROOT_USER="$ZOOKEEPER_ROOT_PASSWORD";
};
EOF
}

function gen_kafkacat_creds {
    if [ "$AETHER_CONNECT_MODE" = "LOCAL" ]; then
        local sasl_mechanism="SCRAM-SHA-512"
        local security_protocol="sasl_plaintext"
    elif [ "$AETHER_CONNECT_MODE" = "CONFLUENT" ]; then
        local sasl_mechanism="PLAIN"
        local security_protocol="sasl_ssl"
    fi

    cat << EOF
bootstrap.servers=$KAFKA_URL
sasl.username=$KAFKA_SU_USER
sasl.password=$KAFKA_SU_PASSWORD
sasl.mechanism=$sasl_mechanism
security.protocol=$security_protocol
EOF
}

if [ "$AETHER_CONNECT_MODE" = "LOCAL" ]; then
    gen_kafka_creds > connect/kafka_server_jaas.conf
    echo -e "\033[92m[connect/kafka_server_jaas.conf] security file generated!\033[0m"

    gen_zookeeper_creds > connect/zk_server_jaas.conf
    echo -e "\033[92m[connect/zk_server_jaas.conf] security file generated!\033[0m"
fi

gen_kafkacat_creds > connect/kafkacat.conf
echo -e "\033[92m[connect/kafkacat.conf] configuration file generated!\033[0m"
