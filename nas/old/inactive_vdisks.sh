#!/bin/bash
ACTIVE_DISKS=`mktemp /tmp/active.XXX`
SAN_DISKS=`mktemp /tmp/san.XXX`
/etc/san/active_vdisks.sh | sort > $ACTIVE_DISKS
/etc/san/exported_iscsi_vdisks_san.sh | sort > $SAN_DISKS
comm -13 $ACTIVE_DISKS $SAN_DISKS
