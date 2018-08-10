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

echo Installing LAMP stack
yum install httpd -y
systemctl enable httpd.service
systemctl start httpd.service
yum install mariadb-server mariadb -y
systemctl start mariadb
systemctl enable mariadb
sudo mysql_secure_installation
yum install php php-mysql -y
systemctl restart httpd.service
yum install php-fpm -y
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload
