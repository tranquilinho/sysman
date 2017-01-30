#!/bin/bash
CFG_DIR=/etc/iscsi/send_targets/

if [ $# -ge 1 ]
then
	CFG_FILE="`find  $CFG_DIR -name "$1*"`/iface0"
fi

if [ $# -eq 1 ]
then
	STATUS=`grep node.startup $CFG_FILE | cut -d"=" -f 2`
	echo $1 $STATUS
elif [ $# -eq 2 ]
then
	STATUS=$2
	if [ $STATUS == "automatic" -o $STATUS == "manual" ]
	then
		sed -i "s/node.startup = \(.*\)/node.startup = $STATUS/g" $CFG_FILE
		echo Status of target $1 changed to $STATUS
	else
		echo Unknows status $STATUS
	fi
else
	echo Syntax: $0 TARGET \[manual\|automatic\]
	exit 1
fi
	