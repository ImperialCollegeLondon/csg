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

# Create Repo
cat <<EOT >> /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT
yum upgrade -y

# Install
yum install filebeat -y

# Configure
sed -i 's/hosts\: \[\"#localhost\:5044\"\]/hosts\: \[\"ee-elk.ee.ic.ac.uk\:5400\"\]/g' /etc/filebeat/filebeat.yml
#systemctl start filebeat

# Enable Service
chkconfig filebeat on

# Start Service
service filebeat start
