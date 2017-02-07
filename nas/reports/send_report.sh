#!/bin/bash

. /etc/san/reports/reports.common

REPORT=`mktemp`
REPORT_SCRIPT=$1
SUBJECT="$2"

if [ $# -ne 2 ]
then
	echo Syntax: $0 report_script email_subject
	exit 1
fi

$REPORT_SCRIPT > $REPORT

mail -s "$SUBJECT `date +%d/%m/%Y` `hostname`" $ADMIN_EMAIL < $REPORT

rm $REPORT
exit 0
