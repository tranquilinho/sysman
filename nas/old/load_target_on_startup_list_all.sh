#!/bin/bash
CFG_DIR=/etc/iscsi/send_targets/

find  $CFG_DIR -name "*iface0" |  sed 's_.*/iqn.san.\(.*\):\(.*\)\.\(.*\),.*,.*,.*,.*_iqn.san.\1:\2.\3_g' | \
while read VD
do
	/etc/san/load_target_on_startup.sh $VD
done
	