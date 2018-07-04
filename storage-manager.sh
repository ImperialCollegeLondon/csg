#!/bin/bash
set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure script is running on CentOS/Redhat
if [ ! -f /etc/redhat-release ]; then
        echo "This script is for CentOS"
        exit
fi

# Install Storage Manager (SSM)
yum install system-storage-manager -y

# Show disk status
ssm list

# Print Example Config
echo to add /dev/sdb in a new pool and mount as /mnt/storage
echo ssm create -s 100% -n data --fstype xfs -p storage /dev/sdb /mnt/storage