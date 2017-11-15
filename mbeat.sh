#!/bin/bash
# removed as filebeat installs repository
#cat <<EOT >> /etc/yum.repos.d/elasticsearch.repo
#[elastic-5.x]
#name=Elastic repository for 5.x packages
#baseurl=https://artifacts.elastic.co/packages/5.x/yum
#gpgcheck=1
#gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
#enabled=1
#autorefresh=1
#type=rpm-md
#EOT
#yum upgrade -y
yum install metricbeat -y
sed -i 's/hosts\: \[\"#localhost\:5044\"\]/hosts\: \[\"ee-elk.ee.ic.ac.uk\:5044\"\]/g' /etc/metricbeat/metricbeat.yml
sed -i 's/period\: 10s/period\: 10m/g' /etc/metricbeat/metricbeat.yml
#systemctl start filebeat
chkconfig metricbeat on
service metricbeat start

