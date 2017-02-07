#!/bin/bash

CRIT=100
WARN=96
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

NASCOUNT=`df -h | grep nas| wc -l `
LIST=`mktemp`
df -Ph | grep nas | sort -rnk 5 | head | awk -v W=$WARN -v C=$CRIT '{P=$5+0; if (P > W){if (P>=C) E=2;if (E!=2) E=1; printf "%s %s %s, <br>",$1,$5,$6}}END{exit E}' > $LIST
status=$?
cat $LIST
if [ $NASCOUNT -eq 0 ]
then
	echo No volumes
elif [ `wc -l $LIST | awk '{print $1}'` -eq 0 ]
then
	echo [OK]
fi
rm $LIST
exit $status
