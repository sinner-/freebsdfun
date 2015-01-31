#!/bin/sh -x

JAILHOME=/home
JAILNAME=dns
FIRST_BIND_INSTALL=no

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf

echo "192.168.254.10 squid" >> ${JAILHOME}/${JAILNAME}/etc/hosts

if ! [ -f ${JAILHOME}/${JAILNAME}/usr/local/etc/namedb/named.conf ]; then
  FIRST_BIND_INSTALL=yes
  echo "nameserver 8.8.4.4" > ${JAILHOME}/${JAILNAME}/etc/resolv.conf
  echo "nameserver 8.8.4.4" > ${JAILHOME}/squid/etc/resolv.conf
  jexec squid service squid stop
  jexec squid pkill squid
  echo "192.168.254.10 squid" >> ${JAILHOME}/squid/etc/hosts
  jexec squid service squid start
  sed -i .bk '/^192.168.254.10 squid/d' ${JAILHOME}/squid/etc/hosts
fi

export http_proxy="http://squid:3128/"

echo y | pkg -j $JAILNAME install bind910

echo "named_enable=\"YES\"" > ${JAILHOME}/${JAILNAME}/etc/rc.conf

cp -f config/dns/named.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/namedb

cp -f config/dns/dns.int.sina.id.au ${JAILHOME}/${JAILNAME}/usr/local/etc/namedb/master

sed -i .bk '/^192.168.254.10 squid/d' ${JAILHOME}/${JAILNAME}/etc/hosts

echo "nameserver 192.168.254.11
search int.sina.id.au" > ${JAILHOME}/${JAILNAME}/etc/resolv.conf

jexec $JAILNAME service named restart

if [ $FIRST_BIND_INSTALL == "yes" ]; then
  echo "nameserver 192.168.254.11
search int.sina.id.au" > ${JAILHOME}/squid/etc/resolv.conf
  jexec squid service squid stop
  jexec squid pkill squid
  jexec squid service squid start
fi
