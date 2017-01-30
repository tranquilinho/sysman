#!/bin/bash

cat  | while read D1 D2
do
	echo `dirname "$D1"` `dirname "$D2"`
done
