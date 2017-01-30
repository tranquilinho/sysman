#!/bin/bash

if [ $# -ne 2 ]
then
	echo Syntax: $0 vd_name size
	echo Example: $0 iqn.san.server:d11 10G
	exit 1
fi

VDNAME=$1
SIZE=$2

LVPATH=`awk -v P=$VDNAME '$0 ~ P{getline;i=index($0,"=");dev=substr($0,i+1,index($0,",")-i-1); print dev}' < /etc/iet/ietd.conf`
lvresize -L $SIZE $LVPATH

/etc/init.d/iscsitarget restart
/etc/init.d/iscsitarget start
