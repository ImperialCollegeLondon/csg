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

# Pre-install
yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
yum install -y docker-ce

# Start Docker Service
systemctl start docker
systemctl enable docker
# Test Docker
docker run hello-world