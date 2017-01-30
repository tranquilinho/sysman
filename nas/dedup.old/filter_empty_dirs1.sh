#!/bin/bash

INPUT=$1

cat $INPUT | while read D1
do
		FILES=`find "$D1" -type f | wc -l `
		if [ $FILES -gt 0 ]
		then
			echo $D1
		fi
done
