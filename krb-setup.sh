#!/bin/sh -x

JAILHOME=/home
JAILNAME=krb

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf

cp -f config/common/resolv.conf ${JAILHOME}/${JAILNAME}/etc/resolv.conf

export http_proxy="http://squid:3128/"

echo "kadmind_enable=\"YES\"" > ${JAILHOME}/${JAILNAME}/etc/rc.conf
echo "kdc_enable=\"YES\"" >> ${JAILHOME}/${JAILNAME}/etc/rc.conf

cp -f config/krb/krb5.conf ${JAILHOME}/${JAILNAME}/etc/krb5.conf

if ! [ -f ${JAILHOME}/${JAILNAME}/var/heimdal/m-key ]; then
  jexec ${JAILNAME} kstash --random-key
fi

jexec $JAILNAME service kdc restart
jexec $JAILNAME service kadmind restart

#kstash --random-key
#kadmin -l
#kadmin> init INT.SINA.ID.AU
#kadmin> add --random-key ldap/ldap.int.sina.id.au
#kadmin> ext_keytab --keytab=/root/ldap_krb5.key ldap/ldap.int.sina.id.au
#kadmin> add user/sina
