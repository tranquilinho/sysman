#!/bin/bash

BIGGEST_ID=`/etc/san/extract_iscsi_disk_ids.sh | sort -n | tail -1`
if [ "a" == "a$BIGGEST_ID" ]
then
	BIGGEST_ID=0
fi
NEW_ID=`echo $BIGGEST_ID + 1 | bc`
# printf "%03d\n" $NEW_ID
echo $NEW_ID
