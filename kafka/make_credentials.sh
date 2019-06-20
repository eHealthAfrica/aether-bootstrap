source .env

function gen_kafka_creds {
    cat << EOF
KafkaServer {
   org.apache.kafka.common.security.scram.ScramLoginModule required;
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="$KAFKA_ROOT_USER"
   password="$KAFKA_ROOT_PW"
   user_$KAFKA_ROOT_USER="$KAFKA_ROOT_PW";
};
Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="$ZK_ROOT_USER"
    password="$ZK_ROOT_PW";
};
EOF
}

function gen_zookeeper_creds {
    cat << EOF
Server {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  user_$ZK_ROOT_USER="$ZK_ROOT_PW";
};
EOF
}

set -Eeo pipefail
gen_kafka_creds > kafka/kafka_server_jaas.conf
echo "[kafka/kafka_server_jaas.conf] security file generated!"
gen_zookeeper_creds > kafka/zk_server_jaas.conf
echo "[kafka/zk_server_jaas.conf] security file generated!"
