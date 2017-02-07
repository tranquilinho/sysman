#!/bin/bash
if [ $# -ne 3 ]
then
	echo Syntax: $0 test block_size block_count
	exit 1
fi
TESTS=$1
BS=$2
COUNT=$3
SEQ=`seq 1 $TESTS`
TIME=$( TIMEFORMAT="%R"; { time   for i in $SEQ ;do dd if=/dev/zero of=ddtest bs=$BS count=$COUNT; done } 2>&1 |tail -1 )
SPEED=`echo "scale=2; ($BS * $COUNT * $TESTS) / ($TIME * 1024 * 1024)" | bc`
echo "$SPEED MB/s"
