#!/bin/sh -x 

#SSL
#LDAP DB
#KRB DB
#KRB M-KEY
#MAILBOX SINA
#.gitignore

tar -zcvf backup.tgz \
.gitignore \
CA \
/usr/home/ldap/var/db/openldap-data/data.mdb \
/usr/home/krb/var/heimdal/heimdal.db \
/usr/home/krb/var/heimdal/m-key \
/usr/home/mail/var/mail/sina
