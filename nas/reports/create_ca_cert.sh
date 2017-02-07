#!/bin/bash

if [ $# -ne 1 ]
then
	echo Syntax: $0 host
	exit 1
fi

HOST=$1
openssl genrsa 2048 > ca-key-$HOST.pem
openssl req -new -x509 -nodes -days 1000 -key ca-key-$HOST.pem > ca-cert-$HOST.pem
