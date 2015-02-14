#!/bin/sh -x

JAILHOME=/home
JAILNAME=www

cp -f config/common/FreeBSD.conf ${JAILHOME}/${JAILNAME}/etc/pkg/FreeBSD.conf
cp -f config/common/resolv.conf ${JAILHOME}/${JAILNAME}/etc/resolv.conf

export http_proxy="http://squid:3128/"

echo y | pkg -j $JAILNAME install nginx

cp -f config/www/rc.conf ${JAILHOME}/${JAILNAME}/etc/rc.conf

cp -f config/www/nginx.conf ${JAILHOME}/${JAILNAME}/usr/local/etc/nginx/nginx.conf

mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/nginx/ssl
mkdir ${JAILHOME}/${JAILNAME}/usr/local/etc/nginx/private

cp -f CA/sina.id.au/sina.id.au-key.pem ${JAILHOME}/${JAILNAME}/usr/local/etc/nginx/private/sina.id.au-key.pem
cat CA/sina.id.au/sina.id.au-cert.pem CA/sina.id.au/godaddy-bundle.pem > ${JAILHOME}/${JAILNAME}/usr/local/etc/nginx/ssl/sina.id.au-cert.pem
jexec $JAILNAME chmod -R o-rwx /usr/local/etc/nginx/private

jexec $JAILNAME service nginx restart
