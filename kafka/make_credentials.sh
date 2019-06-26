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

set -Eeo pipefail
gen_kafka_creds > kafka/kafka_server_jaas.conf
echo "[kafka/kafka_server_jaas.conf] security file generated!"
gen_zookeeper_creds > kafka/zk_server_jaas.conf
echo "[kafka/zk_server_jaas.conf] security file generated!"
