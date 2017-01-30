#!/bin/bash

if [ $# -ne 1 ]
then
	echo Syntax: $0 vd_name 
	exit 1
fi

VGNAME=$1
VG=`echo $VGNAME | sed "s_.*\.\(.*-.*\)_\1_g"`
LV=/dev/$VG/data

echo $LV
