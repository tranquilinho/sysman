#!/usr/bin/env ruby

BASE_PATH='/etc/san/rsync_backup/'
BACKUP_TIME_FILE=BASE_PATH + 'conf/backup_time'
RSYNC_CONFS=BASE_PATH + 'conf/rsyncd.confs'
SYSCONFIGS_PATH=BASE_PATH + "updates/configs/"
BACKUP_HOSTS_PATH=SYSCONFIGS_PATH + 'backup-hosts'

sysconfigs=[]
modules=[]

Dir.open(RSYNC_CONFS).each do |entry|
  backup_description = RSYNC_CONFS + '/' + entry
  if File.file?(backup_description)
    File.readlines(backup_description).each { |line|
      if line =~ /\[.*\]/
        modules <<  line[ /\[(.*)\]/,1 ]
      elsif line =~ /.*=.*/
        key = line[ /(\w+)\s*=/,1 ].rstrip
        value = line[ /=(.*)/,1 ]
	value= value.lstrip unless value.nil?
	if key == "sysconfig"
	  sysconfigs <<  value
	end
      end
    }
  end
end

puts "<p>  Master definitions in #{RSYNC_CONFS}</p>"
puts "<p>  Checking configs in #{SYSCONFIGS_PATH}...</p>"
puts "<ul>"
Dir.entries(SYSCONFIGS_PATH).each do |e|
  if File.directory?(e) && !(e =='.' || e == '..')
    d = File.join(SYSCONFIGS_PATH,e)
    puts "<li>#{d} undefined</li>" unless File.directory?(d) and sysconfigs.include?(e)
  end
end
puts "</ul>"

puts "<p>  Backup times</p>"
puts "<ul>"
File.read(BACKUP_TIME_FILE).lines.each do |line|
  (sysconf,_,_) = line.split
  puts "<li>#{sysconf} undefined</li>" unless sysconfigs.include?(sysconf)
end
puts "</ul>"
puts ""

puts "<p>  Backup hosts</p>"
puts "<ul>"
File.read(BACKUP_HOSTS_PATH).lines.each do |line|
  (mod,_) = line.split
  if mod.include?("/")
	mod=mod[ /(.*)\/(.*)/, 1 ]
   end
   puts "<li>#{mod} undefined</li>" unless modules.include?(mod)
end

puts "</ul>"
