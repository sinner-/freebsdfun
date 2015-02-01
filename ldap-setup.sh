#!/bin/sh -x

JAILHOME=/home
JAILNAME=ldap

if ! [ -f CA/cacert.pem ]; then
  echo "missing CA/cacert.pem. exiting."
  exit 1
fi

if ! [ -f CA/ldap/ldapcert.pem ]; then
  echo "missing CA/ldap/ldapcert.pem. exiting."
  exit 1
fi

if ! [ -f CA/ldap/ldapkey.pem ]; then
  echo "missing CA/ldap/ldapkey.pem. exiting."
  exit 1
fi

if ! [ -f config/ldap/krb5.keytab ]; then
  echo "missing config/ldap/krb5.keytab. exiting."
  exit 1
fi

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf

cp -f config/common/resolv.conf ${JAILHOME}/${JAILNAME}/etc/resolv.conf

export http_proxy="http://squid:3128/"

if ! [ -f ${JAILHOME}/${JAILNAME}/usr/local/bin/ldapsearch ]; then
  echo y | pkg -j $JAILNAME install openldap-sasl-client cyrus-sasl-gssapi libltdl
fi

if ! [ -d /usr/ports/net/openldap24-server ]; then
  echo "no openldap-server port. exiting."
  exit 1
fi

if ! [ -d ${JAILHOME}/${JAILNAME}/usr/ports ]; then
  mkdir ${JAILHOME}/${JAILNAME}/usr/ports
fi

echo "slapd_enable=\"YES\"" > ${JAILHOME}/${JAILNAME}/etc/rc.conf
echo "slapd_flags='-h \"ldapi:///var/run/openldap/ldapi/ ldaps://0.0.0.0/\"'" >> ${JAILHOME}/${JAILNAME}/etc/rc.conf
echo "slapd_sockets=\"/var/run/openldap/ldapi\"" >> ${JAILHOME}/${JAILNAME}/etc/rc.conf

if ! [ -d ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl ]; then
  mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl
fi

if ! [ -d ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private ]; then
  mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private
  jexec ${JAILNAME} chown -R ldap:ldap /usr/local/etc/openldap/private
  jexec ${JAILNAME} chmod og-rwx /usr/local/etc/openldap/private
fi

cp -f CA/cacert.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl/cacert.pem
cp -f CA/ldap/ldapcert.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ssl/ldapcert.pem
cp -f CA/ldap/ldapkey.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/private/ldapkey.pem
jexec $JAILNAME chmod og-rwx /usr/local/etc/openldap/private/ldapkey.pem
jexec $JAILNAME chown ldap:ldap /usr/local/etc/openldap/private/ldapkey.pem

cp -f config/ldap/slapd.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/slapd.conf
cp -f config/ldap/ldap.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/openldap/ldap.conf

cp -f config/ldap/krb5.keytab ${JAILHOME}/${JAILNAME}/etc/krb5.keytab
cp -f config/krb/krb5.conf ${JAILHOME}/${JAILNAME}/etc/krb5.conf
jexec $JAILNAME chmod og-rwx /etc/krb5.keytab
jexec $JAILNAME chown ldap:ldap /etc/krb5.keytab

jexec $JAILNAME service slapd restart
