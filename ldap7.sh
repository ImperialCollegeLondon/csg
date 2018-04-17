#!/bin/bash
#!/bin/bash
set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo For RHEL7 only!
echo Installing LDAP and Kerberos clients
yum install wget vim deltarpm git epel-release -y
yum upgrade -y
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum install man samba-client samba-common cifs-utils nfs-utils nfs-utils-lib epel-release wget ntp openldap-clients nss-pam-ldapd krb5-workstation pam_krb5 net-tools authconfig krb5-libs oddjob-mkhomedir pam_ldap sssd oddjob -y
service nfs start
service rpcbind start
yum install fail2ban -y
systemctl enable fail2ban
cat <<EOT >> /etc/fail2ban/jail.local
[DEFAULT]
# Ban hosts for one hour:
bantime = 3600

# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport

[sshd]
enabled = true
EOT
#cd /tmp
#wget -c https://dl.dropboxusercontent.com/u/42136/ldap_req.tar.gz
#tar zxvf ldap_req.tar.gz
#tar zxvf profile.d.tar.gz -C /etc/profile.d --strip-components=1
#tar zxvf security.tar.gz -C /etc/security --strip-components=1
#tar zxvf pam.d.tar.gz -C /etc/pam.d --strip-components=1
#mv /tmp/rhel-ic.repo /etc/yum.repos.d
yum update -y
yum install pam_mount -y
curl http://ict-repo.cc.ic.ac.uk/scripts/setup-authentication.sh | sh
curl http://ict-repo.cc.ic.ac.uk/scripts/setup-ssh.sh | sh
#tar zxvf ldap_req.tar.gz
#tar zxvf profile.d.tar.gz -C /etc/profile.d/ --strip-components=1
#tar zxvf security.tar.gz -C /etc/security/ --strip-components=1
#tar zxvf pam.d.tar.gz -C /etc/pam.d/ --strip-components=1
echo Please test that you can su to an IC user.
