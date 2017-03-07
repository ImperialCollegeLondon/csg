#!/bin/bash
rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install puppet-agent -y
echo server=ee-puppet.ee.ic.ac.uk >> /etc/puppetlabs/puppet/puppet.conf
/opt/puppetlabs/puppet/bin/puppet agent -t
systemctl enable puppet
systemctl start puppet

