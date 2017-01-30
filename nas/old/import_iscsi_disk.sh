#!/bin/bash
CFG_DIR=/etc/iscsi/send_targets/

if [ $# -ne 1 ]
then
	echo Syntax: $0 TARGET
	exit 1
fi


TARGET=$1
TARGET_HOST=`echo $TARGET | sed "s/iqn.san.\(.*\):.*/\1/g"`
HOST_IP=`/etc/san/san_host_ip.sh $TARGET_HOST`
iscsiadm -m discovery --type sendtargets -p $HOST_IP
iscsiadm -m node --targetname "$TARGET" --login
