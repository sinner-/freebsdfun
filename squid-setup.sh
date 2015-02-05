#!/bin/sh -x

JAILHOME=/home
JAILNAME=squid

echo "nameserver 8.8.4.4" > ${JAILHOME}/${JAILNAME}/etc/resolv.conf

pkg -j $JAILNAME remove squid
pkg -j $JAILNAME autoremove 

echo y | pkg -j $JAILNAME install squid

echo "squid_enable=\"YES\"" > ${JAILHOME}/${JAILNAME}/etc/rc.conf

echo "nameserver 192.168.254.11
search int.sina.id.au" > ${JAILHOME}/${JAILNAME}/etc/resolv.conf

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf

echo "192.168.254.10 squid" >> ${JAILHOME}/${JAILNAME}/etc/hosts

jexec $JAILNAME squid -z

jexec $JAILNAME service squid restart

sed -i .bk '/^192.168.254.10 squid/d' ${JAILHOME}/${JAILNAME}/etc/hosts
