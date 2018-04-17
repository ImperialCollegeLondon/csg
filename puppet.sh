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

# Disable IPV6 due to DNS problems
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install puppet-agent -y
echo server=ee-puppet.ee.ic.ac.uk >> /etc/puppetlabs/puppet/puppet.conf
systemctl enable puppet
/opt/puppetlabs/puppet/bin/puppet agent -t
systemctl start puppet

