#!/bin/bash

if [[ "$(blkid -s TYPE -o value /dev/vdb)" == "" ]]; then
  mkfs.ext4 /dev/vdb
fi
