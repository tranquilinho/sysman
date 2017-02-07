#!/bin/bash
echo $0
readonly scripts_cfg=${0%/sysman/san.*}/etc/service.cfg

. ${scripts_cfg} 

readonly log_file=${storage_log}
readonly module="storage"
readonly log_facility="${module}"

. ${scripts_base}/common

df -lh | grep -v tmpfs



