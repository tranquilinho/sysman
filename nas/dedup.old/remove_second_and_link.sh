#!/bin/bash

while read D1 D2
do
	diff -r "$D1" "$D2" > /dev/null
	if [ $? -eq 0 ]
	then
		echo Deduping $D2
		rm -rf "$D2"
		ln -s `echo "$D1" "$D2" | ./relative_link.rb`  "$D2"
	fi
done
