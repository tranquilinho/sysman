# Store info from the rsync log file into a MySQL DB
# NOTES:
#  - every backup accesses each module twice per day (one for the backup and one for uploading the local log). The
#  primary key constraint ensures only the first access is actually stored in the DB
BEGIN{

	debug = 0
	# Make the summary over the last 7 seven days
	week_beginning= systime() - (7*24*3600)


	print "USE backup"
	# Create a vector with the list of available modules (from rsyncd.conf)
	# and store it on the DB
	# sentence=sprintf("DELETE FROM active_modules;")
	# print sentence
	command = "grep -h ^\\\\[ /etc/san/rsync_backup/conf/rsyncd.confs/*"
	print "kk" |& command
	close(command,"to")
	
	while ((command |& getline line) > 0 ){
		# if it has no hyphen, then the computer is the module itself.
		# Otherwise, is the second word
		module=substr(line,2,length(line) - 2)
		if(index(module,"-") == 0){
			computer=module
			user="NULL"
		}else{
			split(module,m,"-")
			computer=m[2]
			user=m[1]
		}
		module_names[module] =  module
		module_acceses[module] = 0
		sent[module] = 0
		sentence=sprintf("INSERT INTO active_modules VALUES ('%s','%s','%s');",module,computer,user)
		print sentence 
	}
	close(command)
}

{
	split($1,date,"/")
	# dates in SQLite use - instead of /
	backup_date=$1
	gsub(/\//, "-", backup_date)
	date_string = date[1] " " date[2] " " date[3] " 00 00 00"

	date_systime = mktime(date_string) + 0

	# print date_systime
	# Now that the DBMS checks duplicates, it's not really necessary to check dates
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
			started [module] = $2
		}else if ($4 == "sent"){
			# event finished without problems
			transaction_id = $3
			module=modules[transaction_id]
			sent[module] = sent[module] + $5
			received = $8
			total = $12 
			module_acceses[module] = module_acceses[module] + 1
			finished = $2
			sentence=sprintf ("insert into backup values ('%s', '%s', %s, %s,subtime('%s','%s'));", module, backup_date, received, total,finished, started[module]) 
			print sentence
			if (debug == 1){
				print module " " received[module] " " transaction_id
			}
		}
			
	}

}
