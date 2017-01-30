#!/bin/bash
SERVER=$1
SIZE=$3
VG=$2

if [ $# -ne 3 ]
then
	echo Syntax: $0 server_name vg_name size
	echo Example: $0 server1 vg1 30G
	exit 1
fi
SERVER_IP=`/etc/san/san_host_ip.sh $SERVER`
ssh $SERVER_IP "/etc/san/create_iscsi_disk.sh $VG $SIZE"
