#!/bin/bash

if [ $# -ne 2 ]
then
	echo Syntax: $0 vd_name size
	exit 1
fi

VDNAME=$1
SIZE=$2
SERVER=`echo $VDNAME | sed 's_iqn.san.\(.*\):.*_\1_g'`

DEV=`/etc/san/dev_from_iscsi_disk.sh $VDNAME`
mount | grep $DEV
if [ $? -eq 0 ]
then
	echo The disk should not be mounted...
	exit 1
fi
/etc/san/disconnect_iscsi_disk.sh $VDNAME
SERVER_IP=`/etc/san/san_host_ip.sh $SERVER`
ssh $SERVER_IP "/etc/san/resize_iscsi_disk.sh $VDNAME $SIZE"
/etc/san/connect_iscsi_disk.sh $VDNAME

e2fsck -f $DEV
resize2fs $DEV
