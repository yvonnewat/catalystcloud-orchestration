#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker-ce
  - docker-ce-cli
  - containerd.io
  
write_files:
  - path: /etc/system/systemd/format-volume@.service
    content: |
      [Unit]
      Description="A service that creates a file system on the volume, if it does not have an existing file system"
      After=local-fs-pre.target
      Before=local-fs.target

      [Service]
      ExecStart=/usr/local/sbin/format-volume.sh /dev/%i
      RemainAfterExit=yes
      Type=oneshot

      [Install]
      WantedBy=multi-user.target  
  - path: /etc/system/systemd/data-mount
    content: |
      [Unit]
      Description="A service that mounts a volume on the virtual machine"
      After=format-volume@vdb.service
      Before=local-fs.target

      [Mount]
      Where=/data
      What=/dev/vdb
      Type=ext4

      [Install]
      WantedBy=multi-user.target   
  - path: /etc/system/systemd/nginx-start.service   
    content: |
      [Unit]
      Description="A service that starts the NGINX container"
      After=docker.service

      [Service]
      ExecStart=/usr/bin/docker run \
      --name nginx-proxy \
      --publish 80:80 \
      --publish 443:443 \
      --volume certs:/etc/nginx/certs \
      --volume vhost:/etc/nginx/vhost.d \
      --volume html:/usr/share/nginx/html \
      --volume /tmp/proxy.conf:/etc/nginx/conf.d/proxy.conf \
      --volume /var/run/docker.sock:/tmp/docker.sock:ro \
      nginxproxy/nginx-proxy

      [Install]
      WantedBy=multi-user.target  
  - path: /etc/system/systemd/acme-companion-start@.service
    content: |
      [Unit]
      Description="A service that starts the NGINX acme companion container"


      [Service]
      ExecStart=/usr/bin/docker run \
      --name nginx-proxy-acme \
      --volumes-from nginx-proxy \
      --volume /var/run/docker.sock:/var/run/docker.sock:ro \
      --volume acme:/etc/acme.sh \
      --env "DEFAULT_EMAIL=admin@%i" \
      nginxproxy/acme-companion

      [Install]
      WantedBy=multi-user.target  
  - path: /etc/system/systemd/nextcloud-start@.service
    content: |
      [Unit]
      Description="A service that starts the Nextcloud container"
      After=acme-companion.service

      [Service]
      ExecStart=/usr/bin/docker run \
      --name=nextcloud \
      -e TZ=NZ \
      -p 8080:80 \
      --env "VIRTUAL_HOST=%i" \
      --env "LETSENCRYPT_HOST=%i"  \
      --volume /data/www/html:/var/www/html \
      --restart unless-stopped \
      nextcloud

      [Install]
      WantedBy=multi-user.target   
  - path: /setup/configure-nginx.sh
    content: |
       #!/bin/bash

       file_upload_size=$1

       # Create custom nginx proxy configuration
       echo "client_max_body_size $file_upload_size;" > /tmp/proxy.conf
       chmod 666 /tmp/proxy.conf  # Change file permissions   
runcmd:
  - [ cd /setup ]
  - [ curl -fsSL $ddns_script_url > /setup/ddns-script.sh ]
  - [ chmod +x ddns-script.sh ]
  - [ ./ddns-script $host_name $domain_name $ip_address $ddns_password ]
  - [ ./configure-nginx.sh $file_upload_size ]
  - [ cd ~ ]
  - [ cd /etc/systemd/system ]
  - [ chmod 0755 format-volume@.service data.mount nginx-start.service acme-companion-start@.service nextcloud-start@.service ]
  - [ systemctl daemon-reload ]
  - [ systemctl enable format-volume@vdb.service ]
  - [ systemctl enable data.mount ]
  - [ systemctl enable nginx-start.service ]
  - [ systemctl enable acme-companion-start@$domain_name.service ] 
  - [ systemctl enable nextcloud-start@$host_name.$domain_name.service ]
  - [ systemctl start format-volume@vdb.service ]
  - [ systemctl start data.mount ]
  - [ systemctl start --no-block nginx-start.service ] 
  - [ systemctl start --no-block acme-companion-start@$domain_name.service ] 
  - [ systemctl start --no-block nextcloud-start@$host_name.$domain_name.service ]
  - [ touch /deploy-complete ]
apt:
  sources:
    docker:
      source: deb https://download.docker.com/linux/ubuntu $RELEASE stable
      keyid: 9dc858229fc7dd38854ae2d88d81803c0ebfcd88
