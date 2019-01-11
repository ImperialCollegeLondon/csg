#!/bin/bash
rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm
yum install puppet-agent -y
echo server=vm-puppet.doc.ic.ac.uk >> /etc/puppetlabs/puppet/puppet.conf
/opt/puppetlabs/puppet/bin/puppet agent -t
#systemctl enable puppet
chkconfig puppet on
#systemctl start puppet
service puppet start
