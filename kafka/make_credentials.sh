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

source .env

function gen_kafka_creds {
    cat << EOF
KafkaServer {
   org.apache.kafka.common.security.scram.ScramLoginModule required;
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="$KAFKA_ROOT_USER"
   password="$KAFKA_ROOT_PASSWORD"
   user_$KAFKA_ROOT_USER="$KAFKA_ROOT_PASSWORD";
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

gen_kafka_creds > kafka/kafka_server_jaas.conf
echo -e "\e[92m[kafka/kafka_server_jaas.conf] security file generated!\e[0m"

gen_zookeeper_creds > kafka/zk_server_jaas.conf
echo -e "\e[92m[kafka/zk_server_jaas.conf] security file generated!\e[0m"
