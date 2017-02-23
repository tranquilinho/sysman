# Extract module-path association from rsynd.conf


/^\[.*\]/  {module = substr($0,index($0,"[")+1,index($0,"]")-2);
	   module_names[module] =  module	}
/^[ \t]+path.*/ { path[module]= substr($0,index($0,"/"),length($0));}

END{ 
	for (m in module_names){
		print m "	" path[m];
	}
}

