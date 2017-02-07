# Deprecated - see backup_log.awk
BEGIN{

	debug = 0
	# Make the summary over the last 7 seven days
	week_beginning= systime() - (7*24*3600)


	# Create a vector with the list of available modules (from rsyncd.conf)
	command = "grep ^\\\\[ /etc/rsyncd.conf"
	print "kk" |& command
	close(command,"to")
	
	while ((command |& getline line) > 0 ){
		module=substr(line,2,length(line) - 2)
		module_names[module] =  module
		module_acceses[module] = 0
		sent[module] = 0
		received[module] = 0
		total[module] = 0
	}
	close(command)
}

{
	split($1,date,"/")
	date_string = date[1] " " date[2] " " date[3] " 00 00 00"

	date_systime = mktime(date_string) + 0

	# print date_systime
	if(date_systime > week_beginning){
		if($4 == "rsync" && $5 == "to"){
			# New event
			# In the log modules may include a path, like module/windows
			split($6,module_full,"/")
			module= module_full[1]
			host = $8
			transaction_id = $3
			modules[transaction_id]=module
			last_backup_date[module]=$1
		}else if ($4 == "sent"){
			# event finished without problems
			transaction_id = $3
			module=modules[transaction_id]
			sent[module] = sent[module] + $5
			received[module] = received[module] + $8
			total[module] = total[module] + ($12 / (1024 * 1024))
			module_acceses[module] = module_acceses[module] + 1
			if (debug == 1){
				print module " " received[module] " " transaction_id
			}
		}
			
	}

}

END{
#	printf "%-20s %-8s %-14s %-14s %-14s\n", "Module", "Accesses", "Sent(B)", "Received(B)", "Total(MB)"
	for (m in module_names){
		if (last_backup_date[m] == ""){
			e= getline < ("/etc/cron_scripts/last_backup/" m)	
			if (e != -1)
				last_backup_date[m]=$1
		}else{
			print last_backup_date[m] > ("/etc/cron_scripts/last_backup/" m)
		}
		printf "%-20s %-4s  %-4s %-12s %-12s %-14s\n", m, module_acceses[m], sent[m], received[m], total[m], last_backup_date[m]
	}
}
