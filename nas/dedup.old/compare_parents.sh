#!/bin/bash

PARENTS_FILE=$1
PROGRESS=progress`date +%s`

cat $PARENTS_FILE | while read D1 D2
do
	echo $D1 >> $PROGRESS
        diff -r "$D1" "$D2" > /dev/null 
        if [ $? -eq 0 ]
        then
                echo -e ${D1}\\t$D2
        fi
done
