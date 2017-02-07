function togb(size)
{
	if(size ~ /g/){
		gsub("g","",size)
	}else if (size ~ /t/){
                gsub("t","",size)
		size = size * 1024
	}
	return size
}
BEGIN{
	size=0
	used=0
}
{
size = size + togb($6)
used = used + togb($7)
# print $6 " " $7
}
END{
	print size " " used
}
