#!/bin/sh -x

JAILHOME=/home
JAILNAME=mail

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf
cp -f config/common/resolv.conf ${JAILHOME}/${JAILNAME}/etc/resolv.conf

export http_proxy="http://squid:3128/"

echo y | pkg -j $JAILNAME install postfix-tls

cp -f config/mail/rc.conf ${JAILHOME}/${JAILNAME}/etc/rc.conf
cp -f config/mail/periodic.conf ${JAILHOME}/${JAILNAME}/etc/periodic.conf
cp -f config/mail/mailer.conf ${JAILHOME}/${JAILNAME}/etc/mail/mailer.conf
cp -f config/mail/main.cf ${JAILHOME}/${JAILNAME}/usr/local/etc/postfix/main.cf
IPADDR=`ifconfig $NETIF | grep inet | grep -v 192.168.254 | awk '{print $2}'`
sed -i .bk "s/ip999/$IPADDR/" ${JAILHOME}/${JAILNAME}/usr/local/etc/postfix/main.cf
#cp -f config/mail/bounce.cf ${JAILHOME}/${JAILNAME}/usr/local/etc/postfix/bounce.cf

if ! [ -f ${JAILHOME}/${JAILNAME}/etc/aliases.db ]; then
  jexec $JAILNAME newaliases
fi

jexec $JAILNAME service sendmail onestop
jexec $JAILNAME postmap /usr/local/etc/postfix/main.cf
#jexec $JAILNAME postmap /usr/local/etc/postfix/bounce.cf

jexec $JAILNAME service postfix restart
