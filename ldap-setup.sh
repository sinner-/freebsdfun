#!/bin/sh -x

JAILHOME=/home
JAILNAME=ldap

if ! [ -f CA/cacert.pem ]; then
  echo "missing CA/cacert.pem. exiting."
  exit 1
fi

if ! [ -f CA/ldap/ldapcert.pem ]; then
  echo "missing CA/ldap/ldapcert.pem. exiting.
  exit 1
fi

if ! [ -f CA/ldap/ldapkey.pem ]; then
  echo "missing CA/ldap/ldapkey.pem. exiting.
  exit 1
fi

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf

cp -f config/common/resolv.conf ${JAILHOME}/${JAILNAME}/etc/resolv.conf

export http_proxy="http://squid:3128/"

echo y | pkg -j $JAILNAME install openldap-sasl-client cyrus-sasl-gssapi libltdl

if ! [ -d /usr/ports/net/openldap24-server/work ]; then
  echo "no openldap-server port compiled. exiting."
  exit 1
fi
mkdir ${JAILHOME}/${JAILNAME}/usr/ports
mount_nullfs /usr/ports ${JAILHOME}/${JAILNAME}/usr/ports
jexec ${JAILNAME} csh -c "cd /usr/ports/net/openldap24-server && make install"

echo "slapd_enable=\"YES\"" > ${JAILHOME}/${JAILNAME}/etc/rc.conf
echo "slapd_flags='-h \"ldapi:///var/run/openldap/ldapi/ ldaps://0.0.0.0/\"'" >> ${JAILHOME}/${JAILNAME}/etc/rc.conf
echo "slapd_sockets=\"/var/run/openldap/ldapi\"" >> ${JAILHOME}/${JAILNAME}/etc/rc.conf

if ! [ -d ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl ]; then
  mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl
fi

if ! [ -d ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private ]; then
  mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private
  jexec chown -R ldap:ldap ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private
  jexec chmod og-rwx ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private
fi

cp -f CA/cacert.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl/cacert.pem
cp -f CA/ldap/ldapcert.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl/ldapcert.pem
cp -f CA/ldap/ldapkey.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private/ldapkey.pem
jexec $JAILNAME chmod og-rwx ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private/ldapkey.pem
jexec $JAILNAME chown ldap:ldap ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private/ldapkey.pem

cp -f config/ldap/slapd.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/slapd.conf
cp -f config/ldap/ldap.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ldap.conf

jexec $JAILNAME service slapd restart

#cp krb5.key
#setup ssl certs
#add user to directory
