#!/bin/bash

TOTAL=0
while read D 
do
	SIZE=($(du -s $D))
	SIZE=${SIZE[0]}
	echo $SIZE $D
	let "TOTAL = $TOTAL + $SIZE"
done
echo $TOTAL Total
