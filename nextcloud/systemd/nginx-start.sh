#!/bin/bash

docker pull nginxproxy/nginx-proxy

# Run nginx-proxy
docker run --detach \
 --name nginx-proxy \
 --publish 80:80 \
 --publish 443:443 \
 --volume certs:/etc/nginx/certs \
 --volume vhost:/etc/nginx/vhost.d \
 --volume html:/usr/share/nginx/html \
 --volume /tmp/proxy.conf:/etc/nginx/conf.d/proxy.conf \
 --volume /var/run/docker.sock:/tmp/docker.sock:ro \
 nginxproxy/nginx-proxy
