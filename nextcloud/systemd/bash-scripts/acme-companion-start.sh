#!/bin/bash

docker pull nginxproxy/acme-companion

# Run acme-companion
docker run --detach \
 --name nginx-proxy-acme \
 --volumes-from nginx-proxy \
 --volume /var/run/docker.sock:/var/run/docker.sock:ro \
 --volume acme:/etc/acme.sh \
 --env "DEFAULT_EMAIL=admin@$domain_name" \
 nginxproxy/acme-companion
