#!/usr/bin/env ruby

require 'pp'

BASE_PATH='/etc/sysman/san/'
BACKUP_TIME_FILE=BASE_PATH + 'rsync_backup/conf/backup_time'
BACKUP_HOSTS_PATH=BASE_PATH + 'rsync_backup/updates/configs/backup-hosts'
def make_sysconfig_path(file_name)
	lambda{|sysconfig| BASE_PATH + "rsync_backup/updates/configs/#{sysconfig}/#{file_name}"}
end
SYSCONFIG_PATH=make_sysconfig_path("")
SYSCONFIG_BACKUP_PATH=make_sysconfig_path("backup")
SYSCONFIG_CRON_PATH=make_sysconfig_path("cron")

def replace_lines(file_path,lines,&pattern_extractor)
  begin
    file_lines = File.read(file_path)
  rescue StandardError
    file_lines=""
  end
  lines.each do |line|
    pattern=pattern_extractor.call(line)
    if file_lines.gsub!(/#{pattern}.*/, line).nil?
      file_lines << line + "\n"
    end
  end
  File.open(file_path, "w") {|file| file.puts file_lines}
end


if ARGV.length != 1
  puts "Syntax: "
  puts "#{$0} backup_description"
  exit 1
end

backup_description = ARGV[0]
description={}
backup_paths= []

File.open(backup_description){ |f|
  f.readlines.each { |line| 
    if line =~ /\[.*\]/
	description["module"] = line[ /\[(.*)\]/,1 ]
    elsif line =~ /.*=.*/
        key = line[ /(\w+)\s*=/,1 ].rstrip
        value = line[ /=(.*)/,1 ]
	value= value.lstrip unless value.nil?
	if key == "backup_paths"
	  backup_paths.push(value)
          value=backup_paths
	end

	description[key]=value
    end
  } 
}


sysconfig_name=description["sysconfig"]
if sysconfig_name.nil? 
  puts "Sysconfig undefined"
  exit 1
else
  variant= (sysconfig_name.include? "linux") ? "linux" : "win"
  unless File.directory?(SYSCONFIG_PATH.call(sysconfig_name))
    Dir.mkdir(SYSCONFIG_PATH.call(sysconfig_name))
  end
  backup_time = File.read(BACKUP_TIME_FILE).lines.grep( /#{sysconfig_name}.*/ )[0]
  if backup_time.nil?
    puts "Backup time undefined - check #{BACKUP_TIME_FILE}"
  else
    (_,hour,minutes) = backup_time.split
    cron_line="#{minutes} #{hour}  * * 1,2,3,4,5 /etc/cron_scripts/rsync_backup_#{variant}"
    File.open(SYSCONFIG_CRON_PATH.call(sysconfig_name), "w") {|file| file.puts cron_line}
  end
end

backup_host_without_domain=description["backup_host"].split('.')[0]
if description["backup_paths"].nil?
  puts "Backup paths not defined"
else
  mod_backup_hosts=description["backup_paths"].map{ |p| 
    if p.include?("@")
      mod=p.split("@")[-1]
    else
      mod=description["module"]
    end
    mod  + " " + backup_host_without_domain 
  }

  replace_lines(BACKUP_HOSTS_PATH,mod_backup_hosts) {|line| "^" + line.split[0] }

  sysconfig_backup=description["backup_paths"].map{ |p|
    if p.include?("@")
      fields=p.split("@")
      mod=fields[-1]
      client_paths=fields[0]
    else
      mod=description["module"]
      client_paths=p
    end
    # print("#{mod}  #{description["snapshot_freq"]}  #{client_paths}")
    mod  + " " + description["snapshot_freq"] + " " + client_paths
  } 
  replace_lines(SYSCONFIG_BACKUP_PATH.call(sysconfig_name),sysconfig_backup) {|line| "^" + line.split[0] }
end

