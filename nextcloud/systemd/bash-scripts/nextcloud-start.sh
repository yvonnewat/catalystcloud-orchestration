#!/bin/bash

# Pull nextcloud container
docker pull nextcloud

# Run nextcloud container
docker run --detach \
 --name=nextcloud \
 -e TZ=NZ \
 -p 8080:80 \
 --env "VIRTUAL_HOST=$host_name.$domain_name" \
 --env "LETSENCRYPT_HOST=$host_name.$domain_name"  \
 --volume /data/www/html:/var/www/html \
 --restart unless-stopped \
 nextcloud
