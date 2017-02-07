#!/bin/bash

O=`mktemp`
TOTAL=`mktemp`
echo Vdisks report > $O
echo >> $O
/etc/sysman/san/nas_dsh -v -c "vgs" >> $O
echo Size Free > $TOTAL
egrep -v 'VFree|^$|vgs|===' $O  | awk -f /etc/san/reports/sum_vgs_sizes.awk >> $TOTAL

column -t $TOTAL | cat $O -
rm $O $TOTAL
