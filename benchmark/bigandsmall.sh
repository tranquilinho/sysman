#!/bin/bash
if [ $# -ne 1 ]
then
	echo Syntax: $0 test_name
	exit 1
fi
TEST_NAME="$1"
SMALL_PARAMS="100 8192 1"
SMALL=`/root/sysman/benchmark/iospeed.sh $SMALL_PARAMS`
BIG_PARAMS="10 1048576 1024"
BIG=`/root/sysman/benchmark/iospeed.sh $BIG_PARAMS`
echo "$TEST_NAME. Small(${SMALL_PARAMS}): $SMALL. Big(${BIG_PARAMS}): $BIG"
