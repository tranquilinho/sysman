#!/bin/bash

INPUT=$1

cat $INPUT | while read D1 D2
do
	if [ "$D1" != "$D2" ]
	then
		FILES=`find $D1 -type f | wc -l `
		if [ $FILES -gt 0 ]
		then
			echo $D1 $D2
		fi
	fi
done
