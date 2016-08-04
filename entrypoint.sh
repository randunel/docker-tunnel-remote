#!/bin/bash

forward_all_signals_to() {
    SIGNALS=(SIGHUP SIGINT SIGTERM SIGQUIT SIGSTOP SIGUSR1 SIGUSR2);
    for SIGNAL in ${SIGNALS[@]}; do
        eval "trap \"printf \\\"\\n$0 forwarding signal $SIGNAL to pid $1.\\n\\\"; kill -$SIGNAL $1;\" \"$SIGNAL\";"
    done;
}

confirm_env_exists() {
    local NAME=$1;
    if [ -z "${!NAME}" ]; then
        printf "Missing env $NAME, cannot start.\n";
        exit 1;
    fi
}

continue_init() {
    printf "Continue init\n";

    trap - SIGUSR2;
    trap - SIGINT;

    printf "Executing openvpn.\n";
    exec 3< <(openvpn "${@:1}");
    OPENVPN_PID=$!;
    forward_all_signals_to $OPENVPN_PID;

    printf "Reading pid $OPENVPN_PID.\n";

    while read line; do
        case $line in
            *"Initialization Sequence Completed"*)
                printf "Openvpn started.\n";
                break;
                ;;
            *)
                printf " $line\n";
        esac
    done <&3;

    # exec 3<&-;

    unbound &

    printf "Setting up iptables\n";
    iptables -t nat -A POSTROUTING -o $DOCKER_IF -j MASQUERADE;
    iptables -t nat -A POSTROUTING -o $OPENVPN_IF -j MASQUERADE;

    printf "Setting up ip route\n";
    ip r a $DOCKER_NETWORK dev $DOCKER_IF;

    tail -f /dev/null &
    TAIL_PID=$!;
    trap "kill -9 $TAIL_PID; printf \"got SIGINT\"; exit 0;" SIGINT;
    wait;
}

for env in DOCKER_NETWORK; do
    confirm_env_exists $env;
done;

if [ -z "$DOCKER_IF" ]; then
    DOCKER_IF="eth1";
fi

if [ -z "$OPENVPN_IF" ]; then
    OPENVPN_IF="tun0";
fi

printf "Waiting for SIGUSR2.\n";

tail -f /dev/null &
TAIL_PID=$!;
trap "kill -9 $TAIL_PID; printf \"got SIGUSR2\"; continue_init \"\$@\";" SIGUSR2;
trap "kill -9 $TAIL_PID; printf \"got SIGINT\"; exit 1;" SIGINT;
wait;
