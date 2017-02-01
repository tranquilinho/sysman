#!/bin/sh

# Date calculations using POSIX shell
# Tapani Tarvainen July 1998, February 2001 (POSIXified)
# This code is in the public domain.

example()
{
	TODAY=`date +%m/%d/%Y`
	echo $TODAY
	echo $(julian2date $(( $(date2julian $TODAY ) + 365 )))
	# Convert a date from YYYY-MM-DD to MM/DD/YY
	dswap 2010-03-02 3 2 1 2 1 3 "-" "/" 2
	dsub 01/01/10 12/25/09

	date2julianorig 10 03 2009
	# echo $(date2julian 3/10/9)
	# julian2date $(( $(date2julianorig $(date +"%d %m %Y") ) + 15 )) 
}

# Julian Day Number from calendar date
date2julianorig()   #  day month year
{
  day=$1;  month=$2;  year=$3
  # Bug: when using (( for arithmetic, leading zeroes are interpreted
  # as a base change. Use bc or expr for arithmetic instead
  tmpmonth=`echo "12 * $year + $month - 3" | bc`
  # tmpmonth=$((12 * $year + $month - 3))
  # tmpyear=$((tmpmonth / 12))
  tmpyear=`expr $tmpmonth / 12`
  # echo $(( (734 * tmpmonth + 15) / 24 -  2 * tmpyear + \
  #   tmpyear/4 - tmpyear/100 + tmpyear/400 + day + 1721119 ))
  echo "(734 * $tmpmonth + 15) / 24 -  2 * $tmpyear + \
    $tmpyear/4 - $tmpyear/100 + $tmpyear/400 + $day + 1721119 " | bc

}

# Wrapper to allow "standard" date (MM/DD/YY)
date2julian()
{
        # Don't pad with zeroes
        # date2julianorig `date -d $1 +"%-d %-m %-Y"`
        date2julianorig  $(dswap $1 2 1 3 1 2 3 / " ")
}


# Calendar date from Julian Day Number
julian2dateorig()   # julianday
{
  tmpday=$(($1 - 1721119))            
  centuries=$(( (4 * tmpday - 1) / 146097))  
  tmpday=$((tmpday + centuries - centuries/4))      
  year=$(( (4 * tmpday - 1) / 1461))          
  tmpday=$((tmpday - (1461 * year) / 4))            
  month=$(( (10 * tmpday - 5) / 306))        
  day=$((tmpday - (306 * month + 5) / 10))  
  month=$((month + 2))                              
  year=$((year + month/12))                        
  month=$((month % 12 + 1))
  echo $day $month $year

}

julian2date()
{
	TMPDATE=$(julian2dateorig $1)
	# default MM/DD/YY
	echo `echo $TMPDATE | awk '{printf "%.2d/%.2d/%.2d",$2,$1, substr($3,3,4)}'`
	# YYYY-MM-DD
	# echo `echo $TMPDATE | awk '{printf "%.2d-%.2d-%d",$3,$2,$1}'`
}

# Day of week, Monday=1...Sunday=7
dow()   # day month year
{
  echo $(( $(date2julianorig $1 $2 $3) % 7 + 1))

} 

# Swap date fields to convert dates
dswap()
# date day_pos month_pos year_pos nday_pos nmonth_pos nyear_pos orig_separator new_separator year_digits
{
	d=$1
	os=$8
	ns=$9
	day=`echo $d | cut -d "$os" -f $2`
	month=`echo $d | cut -d "$os" -f $3`
	year=`echo $d | cut -d "$os" -f $4`
	if [ "2" == "${10}" ]
	then
		year=`echo $year | cut -c 3-4`
	fi
	newdate[$5]=$day
	newdate[$6]=$month
	newdate[$7]=$year
	echo ${newdate[1]}$ns${newdate[2]}$ns${newdate[3]}
}

# Substract 2 dates, in MM/dd/YY format
dsub()
# date1 date2
{
	d1=$(date2julian $1)
	d2=$(date2julian $2)
	s=`expr $d1 - $d2`
	echo $s
}

# example
# dsub $1 $2
