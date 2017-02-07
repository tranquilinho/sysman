#!/bin/bash

CRIT=200
WARN=200
status=0
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


DEV=$1
# We need to set at least two samples to get the current value (instead of average since boot) 
STATS=($`iostat -kd -p $DEV -d 1 2 | grep "$DEV " | tail -1`)
READ=${STATS[2]}
WRITE=${STATS[3]}
SUM=`echo $READ + $WRITE | bc`
echo "KB/s Read=$READ Write=$WRITE Sum=$SUM"
temp=100
                if [ $temp -gt $CRIT ]
                then
                        status=2
                elif [ $temp -gt $WARN ]
                then
                        status=1
                fi

exit $status
