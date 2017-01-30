#!/bin/bash

LEAVES_FILE=$1
TREE_ROOT=$2
PROGRESS=progress`date +%s`

cat $LEAVES_FILE | while read D
do
	echo $D >> $PROGRESS
	./find_dups.sh "$D" $TREE_ROOT
done
