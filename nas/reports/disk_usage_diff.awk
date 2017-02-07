BEGIN{
	KBYTE_TO_MB=1024

}
{
	usage[$6,$7]=$3
	if ($6 in indexes)
		i=indexes[$6]
	else
		i=0
	dates[$6,i]=$7
	indexes[$6]=i+1
#	print $6 " " $7 " " i
}
END{
	for(resource in indexes){
		last=indexes[resource]-1
		last_date=dates[resource,last]
		last_usage=usage[resource,last_date]
		last_but_one_date=dates[resource,last-1]
		last_but_one_usage=usage[resource,last_but_one_date]
		usage_diff=last_usage - last_but_one_usage
#		print last " " last_date " " last_usage ", " last_but_one_date, " "  last_but_one_usage
		print resource " "  (last_usage / KBYTE_TO_MB) " " (usage_diff / KBYTE_TO_MB) 
	}
}
