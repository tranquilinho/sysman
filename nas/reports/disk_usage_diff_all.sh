#!/bin/bash

/etc/sysman/san/nas_dsh -v -c /etc/sysman/san/reports/update_disk_usage_history.sh > /dev/null

echo '<html><head></head><body>'
echo '<h1>Disk usage variation bigger than 300MB</h1>'
echo '<table width="95%">'
echo '<tr><td>Resource</td><td>Last(MB)</td><td>Diff(MB)</td></tr>'

/etc/san/dsh /etc/san/nas_ip /etc/san/reports/disk_usage_diff.sh | awk ' \
BEGIN{ threshold=300;avgthr=0;i=0}
{ diff=$3; if(diff < 0) diff=diff * -1; if(diff >= threshold) print "<tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td></tr>"; avgthr = avgthr + diff; i++ }
END { print "<tr><td colspan="3">Average delta: " avgthr / i "</td></tr>" }'

echo '</table></body></html>'
