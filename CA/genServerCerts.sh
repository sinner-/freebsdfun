#!/bin/sh

node=$1
if ! [ $node ]; then
  echo node not set.
  exit 1
fi

if ! [ -d $node ]; then
  mkdir $node
  openssl genrsa -aes256 -out $node/${node}key.pem 4096
  openssl req -sha256 -new -days 999 -key $node/${node}key.pem -out $node/${node}csr.pem
  openssl x509 -req -in $node/${node}csr.pem -CA cacert.pem -CAkey cakey.pem -CAcreateserial -out $node/${node}cert.pem -days 999
  chmod -R og-rwx $node
else
  echo "$node already exists."
fi
