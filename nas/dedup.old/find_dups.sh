#!/bin/bash

D1="$1"
TREE_ROOT=$2
PROGRESS=progress`date +%s`

NAME=`basename "$D1"`
#find $TREE_ROOT -type d -name "$NAME" | while read POSSIBLE_DUP
grep "$NAME$" $TREE_ROOT | while read POSSIBLE_DUP
do
	diff -r "$D1" "$POSSIBLE_DUP" > /dev/null 
	if [ $? -eq 0 ]
	then
		echo -e ${D1}\\t$POSSIBLE_DUP
	fi
done
