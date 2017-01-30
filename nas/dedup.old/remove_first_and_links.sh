#!/bin/bash

while read D1 D2
do
	if [ -d "$D1" ]
	then
		ABS_PATH=`pwd`/"$D2"
		echo $D1
		rm -rf "$D1"
		ln -s $ABS_PATH $D1
	fi
done
