function togb(size)
{
	if(size ~ /[gG]/){
		gsub(/[gG]/,"",size)
	}else if (size ~ /[tT]/){
                gsub(/[tT]/,"",size)
		size = size * 1024
	}
	# ensure it returns a number
	return size + 0
}
BEGIN{
	min_size= togb(MINSIZE) 
}
{
vgfree = togb($7) 
if (vgfree > min_size)
	print $1
}
