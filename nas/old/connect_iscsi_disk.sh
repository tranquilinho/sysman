#!/bin/bash
IETCONF=/etc/iet/ietd.conf
VDNAME=$1

if [ $# -ne 1 ]
then
	echo Syntax: $0 vd_name
	exit 1
fi

iscsiadm -m node --targetname "$VDNAME" --login
DEV=`/etc/san/dev_from_iscsi_disk.sh $VDNAME`
# VG=`echo $DEV | /etc/san/vg_from_devices.py`
# FS=`grep -v "#" /etc/fstab | grep $VG | cut -d" " -f 1`
# vgchange -a y $VG
mount $DEV
