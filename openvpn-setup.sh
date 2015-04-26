#!/bin/sh -x

JAILHOME=/home
JAILNAME=openvpn

export http_proxy="http://squid:3128/"

echo y | pkg install openvpn

mkdir /etc/rc.conf.d
cp -f config/master/openvpn.rc.conf /etc/rc.conf.d/openvpn
sysctl net.inet.ip.forwarding=1

mkdir /usr/local/etc/openvpn
cp -f config/master/openvpn.conf /usr/local/etc/openvpn/openvpn.conf

mkdir /usr/local/etc/ssl
mkdir /usr/local/etc/ssl/private

cp -f CA/openvpn/openvpnkey.nocrypt.pem /usr/local/etc/ssl/private/server.key
cp -f CA/openvpn/openvpncert.pem /usr/local/etc/ssl/server.crt
cp -f CA/cacert.pem /usr/local/etc/ssl/ca.crt
cp -f CA/openvpn/dh2048.pem /usr/local/etc/ssl/dh2048.pem
cp -f CA/openvpn/ta.key /usr/local/etc/ssl/private

chmod -R og-rwx /usr/local/etc/ssl/private

service openvpn restart
