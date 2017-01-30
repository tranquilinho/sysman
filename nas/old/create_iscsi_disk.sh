#!/bin/bash
IETCONF=/etc/iet/ietd.conf
SIZE=$2
VG=$1
HOST=`hostname`
DISK_ID=`/etc/san/create_new_iscsi_disk_id.sh`
LVNAME=d$DISK_ID

if [ $# -ne 2 ]
then
	echo Syntax: $0 vg_name size
	echo Example: $0 vg1 30G
	exit 1
fi
lvcreate -L $SIZE --name $LVNAME $VG
if [ $? -ne 0 ]
then
	exit $?
fi

TARGET=iqn.san.$HOST:$LVNAME

echo "Target $TARGET" >> $IETCONF
echo "       Lun 0 Path=/dev/$VG/$LVNAME,Type=fileio" >> $IETCONF

/etc/init.d/iscsitarget restart
/etc/init.d/iscsitarget start

echo $TARGET
