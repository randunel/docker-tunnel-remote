FROM alpine:3.4

RUN apk add --no-cache unbound

ADD unbound.conf /etc/unbound/unbound.conf
ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
