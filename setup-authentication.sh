echo "INFO: setup-authentication.sh: Switch over to LDAP and Kerberos 5"
ADSERVERS=icads34.ic.ac.uk:88,icads12.ic.ac.uk:88,icads13.ic.ac.uk:88,icads14.ic.ac.uk:88,icads36.ic.ac.uk:88,icads35.ic.ac.uk:88,icads15.ic.ac.uk:88
authconfig --useshadow --passalgo=sha512 --disablemd5 --disablefingerprint --enableldap --ldapserver unixldap.cc.ic.ac.uk --ldapbasedn ou=everyone,dc=ic,dc=ac,dc=uk --enablekrb5 --krb5realm IC.AC.UK --krb5kdc $ADSERVERS --krb5adminserver $ADSERVERS  --enablecache --enablemkhomedir --updateall

