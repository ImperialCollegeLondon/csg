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

# Disable Opensource Drivers
rpm -e xorg-x11-drivers xorg-x11-drv-nouveau
echo -e "blacklist nouveau\nblacklist lbm-nouveau\noptions nouveau modeset=0\nalias nouveau off\nalias lbm-nouveau off" | tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null
echo options nouveau modeset=0 | sudo tee /etc/modprobe.d/nouveau-kms.conf > /dev/null
update-initramfs -u

# Install Requirements
yum -y groupinstall "Development Tools"
yum -y install kernel-devel

# Add Nvidia Repo
rpm -Uvh https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.2.88-1.x86_64.rpm
yum clean all

# Install CUDA
yun install cuda -y