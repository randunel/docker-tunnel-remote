FROM ubuntu:16.04

RUN apt-get update && \
        apt-get install -y iptables iproute2 unbound

# RUN apk add --no-cache unbound bash && \
#         rm -rf /var/cache/apk/*

ADD unbound.conf /etc/unbound/unbound.conf
ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/root/entrypoint.sh"]
