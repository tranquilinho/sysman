#!/bin/bash

USAGE_HISTORY=/var/log/disk_usage_history.log

df -lP | grep nas | awk -v today="`date +%F`" '{print $0 "\t" today}' >> $USAGE_HISTORY

