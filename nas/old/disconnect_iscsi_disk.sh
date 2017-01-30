#!/bin/bash
IETCONF=/etc/iet/ietd.conf
VDNAME=$1

if [ $# -ne 1 ]
then
	echo Syntax: $0 vd_name
	exit 1
fi

DEV=`./dev_from_iscsi_disk.sh $VDNAME`
# VG=`echo $DEV | ./vg_from_devices.py`
# FS=`echo $VG | ./fs_from_vg.py $VG`

umount $DEV
# vgchange -a n $VG
iscsiadm -m node --targetname "$VDNAME" --logout
