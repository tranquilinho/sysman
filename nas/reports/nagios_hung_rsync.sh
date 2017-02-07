#!/bin/bash

status=0
CRIT=18
WARN=9
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

NPROCS=`ps -ef | grep rsync | wc -l`
echo Rsync related processes: $NPROCS
                if [ $NPROCS -gt $CRIT ]
                then
                        status=2
                elif [ $NPROCS -gt $WARN ]
                then
                        status=1
                fi

exit $status
