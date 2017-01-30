#!/bin/bash
NAS_DISKS=`mktemp /tmp/nas.XXX`
SAN_DISKS=`mktemp /tmp/san.XXX`
grep "/dev/disk/by-path/ip-" /etc/fstab | grep -v "#" | sed "s_.*iqn\(.*\)-lun.*_iqn\1_g" | sort # > $NAS_DISKS
# /etc/san/exported_iscsi_vdisks_san.sh | sort > $SAN_DISKS
# comm -12 $NAS_DISKS $SAN_DISKS
