require 'date'

class RsyncConfig
	Rsync_config="/etc/rsyncd.conf"
	
	def moduleParameters(mod)
		insideModule = 0
		param= Hash.new()
		IO.foreach(Rsync_config) do |line|
			if insideModule == 1
				break if line !~ /=/
				m= /=/.match(line)
				param[m.pre_match.strip]=m.post_match.strip
			end			
			insideModule = 1 if line =~ /\[#{mod}\]/
		end
		param
	end	
end

class BackupConfig
	Backup_config_root="/etc/san/rsync_backup/updates/configs/"
	
		def modulesConfig()
			result=[]
			Dir.chdir(Backup_config_root)
			backupFiles=Dir.glob("**/backup") .reject {|path| path.start_with?("old/")}
			backupFiles.each{ |file|
				IO.foreach(file) do |line|
					backupParams=line.split
					destination=backupParams[0]
					# module may have subdir
					indexSlash=destination =~ /\//
					if indexSlash
						mod=destination[0..indexSlash-1]
					else
						mod=destination
					end
					snapshot_freq=backupParams[1]
					result << [mod,destination,snapshot_freq]
				end
			}
			result
		end
		
end

def  findLastSnapshotDate(modulePath)
	result=nil
	
	return nil if File.exists?(modulePath) == false
	
	begin
		result=File.mtime(modulePath + "/snapshot")
	rescue
		Dir.chdir(modulePath)
		dailyDates=[]
		dailyDates = Dir.glob("daily.?").collect { |dir|  [ dir, File.mtime(dir)]}
		newest=dailyDates.sort_by{|e| e[1]}.last
		if newest != nil
			result=newest[1]
		end
#		do |dir|
#			dailyDates << [ dir, File.mtime(dir)
#		end
	end
	result
end

def pp(object)
	object.pp
end

class Array
	def pp
		result="<p>"
		for e in self
			result = result + e.to_s + " "
		end
		print result + "</p>\n"
	end
end

class String
	def pp
		print "<p>" + self + "</p>\n"
	end
end



def htmlHeader(title)
		"<html><head><title>"+title + "</title></head><body><h1>"+title+"</h1>"    
end

def htmlFooter()
		"</body></html>\n"    
end

def printAsHtmlRow(row)
	print "<tr>"
	for e in row
		print "<td>" + e.to_s + "</td>"
	end
	print "</tr>\n"
end


def printAsHtmlTable(matrix,header)
	print '<table border="1" cellpadding="5">' + "\n"
	printAsHtmlRow(header)
	for row in matrix
		printAsHtmlRow(row)	
	end
	print"</table>\n"
end

r=RsyncConfig.new()

b=BackupConfig.new()
mc=b.modulesConfig()
modsWithSnapshotsDisabled=mc.select {|backupParams|  backupParams[2] == "0"}

print htmlHeader("Snapshots report - " + Date.today.to_s)

pp "Modules with snapshots disabled:"
pp modsWithSnapshotsDisabled.map {|e| e[0]}.sort

modulesWithoutPath=[]
modulesWithoutSnapshot=[]
modsWithSnapshot=mc.collect{|backupParams|  backupParams[0] if backupParams[2] == "1" } - [nil]

# XML.Builder gem simplifies HTML generation

now=Time.now
threshold= 7*24*3600
tableOldSnapshots=[]
modsWithSnapshot.uniq.each do |mod|
	modulePath=r.moduleParameters(mod)["path"]
	if modulePath == nil
		modulesWithoutPath << mod
	else
		date=findLastSnapshotDate(modulePath)
		if date == nil
			modulesWithoutSnapshot << mod
		elsif (now - date) >= threshold
			tableOldSnapshots << [date.strftime("%Y-%m-%d %R"), modulePath]
		end
	end
end

pp "Modules without a snapshot in a week (or more):"
printAsHtmlTable(tableOldSnapshots,["Date","Module Path"])

#pp "Modules not defined in rsyncd.conf:"
#pp modulesWithoutPath.sort

pp "Modules without snapshot:"
pp modulesWithoutSnapshot.sort

print htmlFooter
