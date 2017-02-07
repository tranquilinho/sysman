#!/bin/bash

. /etc/san/reports/reports.common

REPORT=`mktemp --suffix=.html`
REPORT_SCRIPT=$1
SUBJECT="$2"

if [ $# -ne 2 ]
then
	echo Syntax: $0 report_script email_subject
	exit 1
fi

$REPORT_SCRIPT > $REPORT

mutt -s "$SUBJECT `date +%d/%m/%Y` `hostname`" -a $REPORT -- $ADMIN_EMAIL <<EOF
.
EOF

rm $REPORT
exit 0
