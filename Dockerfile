FROM alpine:3.4

RUN apk add --no-cache \
        bash \
        iptables \
        iproute2 \
        openvpn \
        unbound \
        && rm -rf /var/cache/apk/*

ADD unbound.conf /etc/unbound/unbound.conf
ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
