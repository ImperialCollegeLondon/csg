#!/bin/bash
rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
yum install puppet-agent -y
echo server=ee-puppet.ee.ic.ac.uk >> /etc/puppetlabs/puppet/puppet.conf
/opt/puppetlabs/puppet/bin/puppet agent -t
systemctl enable puppet
systemctl start puppet

