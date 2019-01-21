#!/bin/bash
set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure script is running on Ubuntu
if [ ! -f /etc/os-release ]; then
        echo "This script is for Ubuntu"
        exit
fi

# Find Ubuntu codename
release=`lsb_release -c -s`
echo you are running Ubuntu $release

# Download Puppet Platform
wget -P /tmp https://apt.puppetlabs.com/puppet6-release-$release.deb

# Install Puppet platform and puppet agent
dpkg -i /tmp/puppet6-release-$release.deb && rm /tmp/puppet6-release-$release.deb
apt install puppet-agent -y

# Point Puppet agent to our Puppet master
echo server=vm-puppet.doc.ic.ac.uk >> /etc/puppetlabs/puppet/puppet.conf

# Start Puppet and enable on startup
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true