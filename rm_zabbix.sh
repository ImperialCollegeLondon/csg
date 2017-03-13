#!/bin/bash
yum erase zabbix-agent -y
rm /etc/yum.repos.d/zabbix.repo
yum clean all
