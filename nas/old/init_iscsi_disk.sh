#!/bin/bash

if [ $# -ne 1 ]
then
	echo Syntax: $0 vd_name 
	exit 1
fi

VDNAME=$1
DEV=`/etc/san/dev_from_iscsi_disk.sh $VDNAME`
VGNAME=`echo $VDNAME | sed "s_.*\.\(.*-.*\)_\1_g"`


# pvcreate $DEV
# vgcreate $VGNAME $DEV
# lvcreate -l 100%VG --name data $VGNAME 
# mkfs -t ext4 -m 1 /dev/$VGNAME/data
mkfs -t ext4 -m 1 $DEV

