#!/bin/bash
IETCONF=/etc/iet/ietd.conf
VG=$1
HOST=`hostname`
LVNAME=$2

if [ $# -ne 2 ]
then
	echo Syntax: $0 vg_name lv_name
	echo Example: $0 vg1 d21
	exit 1
fi

TARGET=iqn.san.$HOST:$LVNAME

echo $TARGET $LVNAME
sed -i "/$TARGET/d" $IETCONF
sed -i "/$LVNAME/d" $IETCONF

/etc/init.d/iscsitarget restart
/etc/init.d/iscsitarget start

LV=/dev/$VG/$LVNAME
echo $LV
lvremove $LV

