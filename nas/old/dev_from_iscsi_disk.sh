#!/bin/bash

if [ $# -ne 1 ]
then
	echo Syntax: $0 vd_name 
	exit 1
fi

VDNAME=$1
DEV=/dev/`ls -l /dev/disk/by-path | grep $VDNAME | sed 's_.*/sd\(.*\)_sd\1_g'`

echo $DEV
