#!/bin/env bash
#set -x
#set -e
# Import Bash OO Framework
#source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/lib/oo-bootstrap.sh"

# Make sure only root can run our script
#if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

# Check to make sure script is running on CentOS/Redhat
#if [ ! -f /etc/redhat-release ]; then
#        echo "This script is for CentOS"
#        exit
#fi

echo Installing LDAP and Kerberos clients
yum install wget vim deltarpm git epel-release -y
yum upgrade -y
#rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum install man samba-client samba-common cifs-utils nfs-utils nfs-utils-lib epel-release wget ntp openldap-clients nss-pam-ldapd krb5-workstation pam_krb5 net-tools authconfig krb5-libs oddjob-mkhomedir pam_ldap sssd oddjob -y
service nfs start
service rpcbind start

yum install pam_mount -y
echo "INFO: setup-authentication.sh: Switch over to LDAP and Kerberos 5"
ADSERVERS=icads34.ic.ac.uk:88,icads12.ic.ac.uk:88,icads13.ic.ac.uk:88,icads14.ic.ac.uk:88,icads36.ic.ac.uk:88,icads35.ic.ac.uk:88,icads15.ic.ac.uk:88
authconfig --useshadow --passalgo=sha512 --disablemd5 --disablefingerprint --enableldap --ldapserver unixldap.cc.ic.ac.uk --ldapbasedn ou=everyone,dc=ic,dc=ac,dc=uk --enablekrb5 --krb5realm IC.AC.UK --krb5kdc $ADSERVERS --krb5adminserver $ADSERVERS  --enablecache --enablemkhomedir --updateall

# Configure SSH options and only allow access to the custodian, sysadmin and 
# owner

echo "INFO: setup-ssh.sh: Configuring sshd and ssh to only use Protocol v2"

MAC="$(/sbin/ifconfig ${KSDEVICE} | grep HWaddr | cut -dr -f3 | sed -e 's/ *//g')"
echo "INFO: read-hdb.sh: Getting system information from HDB for MAC address (${MAC})"
wget -N -q -O - http://hdb.ic.ac.uk/Zope/complete_reg/self_info?mac=${MAC} > /root/selfinfo

CUSTODIAN="$(cat /root/selfinfo | grep custodian | cut -d ';' -f 2)"
OWNER="$(cat /root/selfinfo | grep machineowner | cut -d ';' -f 2)"
SYSADMIN="$(cat /root/selfinfo | grep sysadmin | cut -d ';' -f 2)"

if [ "${CUSTODIAN}" = "" ]; then
  CUSTODIAN="${OWNER}"
fi

if [ "${SYSADMIN}" == "" ]; then
  SYSADMIN="${CUSTODIAN}"
fi

echo "INFO: setup-ssh.sh: Setting ssh banner"
echo > /etc/issue
echo "Unauthorised Access Is Prohibited" >> /etc/issue
echo >> /etc/issue
sed -i -e 's/#Banner.*/Banner \/etc\/issue/g' /etc/ssh/sshd_config

echo "INFO: setup-ssh.sh: Configuring sshd to allow owner, custodian and system administrator remote access (${OWNER},${CUSTODIAN},${SYSADMIN})"

/usr/sbin/usermod -a -G sshd root

for FIELD in "${OWNER}" "${CUSTODIAN}" "${SYSADMIN}"; do
        /usr/sbin/usermod -a -G sshd ${FIELD}
done

echo "AllowGroups sshd" >> /etc/ssh/sshd_config


echo Please test that you can su to an IC user.
