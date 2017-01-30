#!/bin/bash

if [ $# -ne 6 ]
then
        echo Syntax: $0 src_dir dst_dir server vg size start_step
        exit 1
fi
SRC=$1
DST=$2
SERVER=$3
VG=$4
SIZE=$5
START=$6
BASE=`dirname $SRC`
LOGNAME=`basename $SRC`.log
LOG=$BASE/$LOGNAME

echo Started `date` >> $LOG
if [ $START -le 1 ]
then
	grep ^vdisk $LOG
	if [ $? -eq 0 ]
	then
		echo Warning: the vdisk is already created
		echo Proceed with the migration from step 2
		exit 1
	fi
	VDISK=`/etc/san/create_remote_iscsi_disk.sh $SERVER $VG $SIZE |tail -1`
	echo vdisk $VDISK >> $LOG
	sleep 5
else
	VDISK=`grep ^vdisk $LOG | cut -d" " -f 2`
fi
if [ $START -le 2 ]
then
	/etc/san/import_iscsi_disk.sh $VDISK >> $LOG
fi
DEV=`/etc/san/dev_from_iscsi_disk.sh $VDISK`
if [ $DEV == "/dev/" ]
then
	echo No device found for $VDISK
	exit 1
fi

if [ $START -le 3 ]
then
	mkfs -t ext4 -F -m 1 $DEV
	echo mkfs $DEV result $? >> $LOG
fi
if [ $START -le 4 ]
then
	mkdir -p $DST
	mount $DEV $DST
	echo FS mounted $? >> $LOG
	DISK_BY_PATH=`ls /dev/disk/by-path | grep $VDISK`
	if [ "a" != "a$DISK_BY_PATH" ]
	then
		echo "/dev/disk/by-path/$DISK_BY_PATH $DST ext4 defaults,_netdev 0 0" >> /etc/fstab
	fi
fi

if [ $START -le 5 ]
then
	mount | grep $DST 
	if [ $? -eq 0 ]
	then
		rsync -av $SRC/ $DST >> $LOG
	fi
fi
echo Finished `date` >> $LOG
