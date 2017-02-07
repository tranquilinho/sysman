#!/bin/bash
SCRIPTS_DIR=/etc/san/rsync_backup

status=0
if [ $# -ge 4 ]; then
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

old_backups=$( ${SCRIPTS_DIR}/backup-info-host.sh | grep OLD | sort -n -k 4 )
if [ ${#old_backups} -gt 1 ]; then
    status=1
    echo ${old_backups}
else
    echo [OK]    
fi

exit ${status}
