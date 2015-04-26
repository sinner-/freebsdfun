#!/bin/sh
if ! [ -f openvpn/ta.key ]; then
  openvpn --genkey --secret openvpn/ta.key
else
  echo "ta.key already exists."
fi
