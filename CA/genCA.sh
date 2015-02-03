#!/bin/sh
# Create CA private key
openssl genrsa -aes256 -out cakey.pem 4096

# Create CA self-signed certificate
openssl req -sha256 -new -x509 -extensions v3_ca -days 999 -key cakey.pem -out cacert.pem

#Set secure permissions
chmod og-rwx cakey.pem
chmod og-rwx cacert.pem
