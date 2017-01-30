#!/bin/bash

if [ $# -ne 1 ]
then
	echo Syntax: $0 TARGET
	exit 1
fi


TARGET=$1
host $TARGET.san $SAN_DNS | grep address | cut -d" " -f 4
