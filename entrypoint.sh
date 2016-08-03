#!/bin/bash

trap "printf '\nBye.\n'; exit 0;" SIGHUP SIGINT SIGTERM

confirm_env_exists() {
    local NAME=$1;
    if [ -z "${!NAME}" ]; then
        printf "Missing env $NAME, cannot start.\n";
        exit 1;
    fi
}
for env in DOCKER_NETWORK DEV_IP OWN_IP; do
    confirm_env_exists $env;
done;

GRE_NETWORK="10.160.2.0/24";
GRE_IP="10.160.2.1/24";

printf "Setting up GRE tunnel\n";
ip tunnel add gre0 mode gre remote $DEV_IP local $OWN_IP ttl 255;
ip link set gre0 up;
ip addr add $GRE_IP dev gre0;

printf "Starting unbound daemon\n";
unbound &
UNBOUND_PID=$!;

printf "Setting up iptables\n";
iptables -t nat -A POSTROUTING -j MASQUERADE;

printf "Setting up ip route\n";
ip r a $GRE_NETWORK dev gre0;

printf "Waiting for daemon pid $UNBOUND_PID.\n";
wait $UNBOUND_PID;
