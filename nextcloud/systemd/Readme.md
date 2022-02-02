# Systemd Services

These systemd services are used to run the containers and configure the volume such that Nextcloud can survive reboots.

For the volume:

format-service@.service --> configures the volume such that it has an ext4 filesystem (if there is no existing file system on the volume)
data.mount --> mounts the volume into the /data directory

For the containers:

nginx-start.service --> starts the NGINX container
acme-companion.service --> starts the NGINX acme companion container
nextcloud-start.service --> starts the Nextcloud container
