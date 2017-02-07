#!/bin/bash

readonly nas_path=${0%/san/*}/san

status=0
CRIT=50
WARN=25
if [ $# -ge 4 ]
then
        case $3 in
                -w)
                        WARN=$4
                ;;
                -c)
                        CRIT=$4
                ;;
        esac
        case $5 in
                -w)
                        WARN=$6
                ;;
                -c)
                        CRIT=$6
                ;;
        esac
fi

${nas_path}/vmservicebackup/check-backup-all.sh -nagios | awk '{if($4>15){print $0;OLD=1}}END{if(OLD==1)exit 1}'
status=$?
exit $status
