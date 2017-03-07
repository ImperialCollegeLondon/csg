#!/bin/bash
cat <<EOT >> /etc/yum.repos.d/elasticsearch.repo
[elastic-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT
yum upgrade -y
yum install filebeat -y
sed -i 's/hosts\: \[\"localhost\:9200\"\]/hosts\: \[\"ee-elk.ee.ic.ac.uk\:9200\"\]/g' /etc/filebeat/filebeat.yml
#systemctl start filebeat
chkconfig filebeat on
service filebeat start

