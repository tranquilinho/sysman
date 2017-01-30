#!/bin/bash

LIMIT=$1

cat $INPUT | while read SIZE D1 D2
do
	if [ $SIZE -gt $LIMIT ]
	then
		echo $D1 $D2
	fi
done
