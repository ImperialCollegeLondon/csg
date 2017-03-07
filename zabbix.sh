rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
wget http://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-79EA5ED4| rpm --import
yum install zabbix-agent -y
firewall-cmd --add-port=10050/tcp --zone=public --permanent
firewall-cmd --add-port=10051/tcp --zone=public --permanent 
firewall-cmd --reload
sed -i 's/enforcing/permissive/g' /etc/sysconfig/selinux /etc/sysconfig/selinux
sed -i 's/Server=127.0.0.1/Server=ee-icinga3.ee.ic.ac.uk/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=ee-icinga3.ee.ic.ac.uk/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
echo HostMetadataItem=system.uname >> /etc/zabbix/zabbix_agentd.conf
setenforce 0
systemctl enable zabbix-agent
systemctl start zabbix-agent
