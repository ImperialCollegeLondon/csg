#!/bin/bash
echo for RHEL6 Only! 
echo Installing LDAP and Kerberos clients
yum -y install epel-release && rpm -Uvh http://li.nux.ro/download/nux/dextop/el6/x86_64/nux-dextop-release-0-2.el6.nux.noarch.rpm
yum upgrade -y
yum install man samba-client samba-common cifs-utils nfs-utils nfs-utils-lib epel-release wget ntp openldap-clients nss-pam-ldapd krb5-workstation pam_krb5 net-tools authconfig krb5-libs oddjob-mkhomedir pam_ldap sssd oddjob -y
#service nfs start
#service rpcbind start
#mv /tmp/rhel-ic.repo /etc/yum.repos.d
#yum update -y
yum install pam_mount -y
curl http://ict-repo.cc.ic.ac.uk/scripts/setup-authentication.sh | sh
curl http://ict-repo.cc.ic.ac.uk/scripts/setup-ssh.sh | sh
echo Please test that you can su to an IC user.
