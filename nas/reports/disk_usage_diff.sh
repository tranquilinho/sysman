#!/bin/bash

tail -300 /var/log/disk_usage_history.log | awk -f /etc/san/reports/disk_usage_diff.awk 
