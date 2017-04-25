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

# Update system
yum update -y && yum upgrade -y


################################## NTP Time Sync ##################################
yum install ntp ntpdate ntp-doc -y || true
systemctl enable ntpd || true
systemctl start ntpd || true
ntpdate pool.ntp.org || true

##################################### Install Java ##################################
cd /opt
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jre-8u102-linux-x64.rpm"
rpm -Uvh jre-8u102-linux-x64.rpm
rm -rf jre-8u102-linux-x64.rpm
yum install java-devel -y

##################################### Install/Setup Elasticsearch #####################################
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo '[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/elasticsearch.repo
sudo yum -y install elasticsearch

sed -i 's/#network.host: 192.168.0.1/network.host: localhost/g' /etc/elasticsearch/elasticsearch.yml

systemctl enable elasticsearch
systemctl start elasticsearch

##################################### Install/Setup Kibana #####################################
echo '[kibana-5.x]
name=Kibana repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/kibana.repo
sudo yum -y install kibana

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo systemctl start kibana.service


##################################### Install/Setup Nginx #####################################
yum -y install epel-release
yum -y install nginx httpd-tools
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# Delete server block  in default config
sed -i -e '38,87d' /etc/nginx/nginx.conf

read -p "Create OpenSSL cert or Let's Encrypt Cert [L/O]" -n 1 -r
if [[ $REPLY =~ ^[Oo]$ ]]; then
	mkdir /etc/nginx/ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
  sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

cat > /etc/nginx/conf.d/kibana.conf << EOF
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        return 301 https://$host$request_uri;
}

server {
        listen 443 ssl;
        server_name _;

        root /usr/share/nginx/html;
        index index.html index.htm;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security max-age=15768000;

        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/htpasswd.users;

	location / {
        	proxy_pass http://localhost:5601;
        	proxy_http_version 1.1;
        	proxy_set_header Upgrade \$http_upgrade;
        	proxy_set_header Connection 'upgrade';
        	proxy_set_header Host \$host;
        	proxy_cache_bypass \$http_upgrade;
    	}
}
EOF

sudo systemctl start nginx
sudo systemctl enable  nginx
sudo setsebool -P httpd_can_network_connect 1

else
	sudo yum install certbot
echo 'server {
        location ~ /.well-known {
          allow all;
        }
}
' | sudo tee /etc/nginx/conf.d/le-well-known.conf

	sudo systemctl start nginx
	sudo systemctl enable  nginx

	read -p "Enter domain name: " -e domainName
	sudo certbot certonly -a webroot --webroot-path=/usr/share/nginx/html -d $domainName -d www.$domainName
	sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

cat > /etc/nginx/conf.d/kibana.conf << EOF
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        return 301 https://$host$request_uri;
  }

server {
	     listen 443 ssl;

        server_name ${domainName} www.${domainName};

        ssl_certificate /etc/letsencrypt/live/${domainName}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${domainName}/privkey.pem;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security max-age=15768000;

        # The rest of your server block
        root /usr/share/nginx/html;
        index index.html index.htm;

        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/htpasswd.users;

        location / {
                proxy_pass http://localhost:5601;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host \$host;
                proxy_cache_bypass \$http_upgrade;
        }
}
EOF

	rm -rf /etc/nginx/conf.d/le-well-known.conf
	sudo systemctl restart nginx
  sudo setsebool -P httpd_can_network_connect 1


	sudo certbot renew
echo '30 2 * * 1 /usr/bin/certbot renew >> /var/log/le-renew.log
35 2 * * 1 /usr/bin/systemctl reload nginx
' >> /etc/crontab

systemctl start crond

fi

##################################### Install/Setup Logstash #####################################
echo '[logstash-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/logstash.repo

sudo yum -y install logstash

# Install filebeat
cd /usr/share/logstash
./bin/logstash-plugin install logstash-input-beats

read -p "Logstash encryption or no encryption [E/N]: " -n 1 -r
if [[ $REPLY =~ ^[E]$ ]]; then

  read -p "OpenSSL cert or Let's Encrypt Cert [L/O]: " -n 1 -r
  if [[ $REPLY =~ ^[L]$ ]]; then
touch /etc/logstash/conf.d/02-beats-input.conf
cat > /etc/logstash/conf.d/02-beats-input.conf << EOF
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/letsencrypt/live/$domainName/fullchain.pem"
    ssl_key => "/etc/letsencrypt/live/$domainName/privkey.pem"
  }
}
EOF
  else
echo 'input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/nginx/ssl/nginx.crt"
    ssl_key => "/etc/nginx/ssl/nginx.key"
  }
}
' | sudo tee /etc/logstash/conf.d/02-beats-input.conf
  fi
else

echo 'input {
  beats {
    port => 5044
    ssl => false
  }
}
' | sudo tee /etc/logstash/conf.d/02-beats-input.conf

fi


#### Syslog filter ####
echo 'filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
' | sudo tee /etc/logstash/conf.d/10-syslog-filter.conf



#### Elasticsearch output ####
echo 'output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
' | sudo tee /etc/logstash/conf.d/30-elasticsearch-output.conf

# Load Kibana dashboards
cd ~
curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
sudo yum -y install unzip
unzip beats-dashboards-*.zip
cd beats-dashboards-*
./load.sh


systemctl restart logstash
systemctl enable logstash

##################################### Install/Setup FirewallD #####################################
yum install firewalld -y

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --zone=public --permanent --add-service=ssh
firewall-cmd --zone=public --permanent --add-port=5044/tcp
firewall-cmd --reload
