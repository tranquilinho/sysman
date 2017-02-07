#!/usr/bin/env python

# TODO: report also a list of all the snapshots sorted by size

import os
import glob
import re
from datetime import datetime


backup_config_root="/etc/san/rsync_backup/updates/configs/"
rsync_config="/etc/rsyncd.conf"
snapshot_disabled_modules=[]
modules_without_path=[]
modules_undefined=[]
old_snapshots=[]
latest_snapshots=[]

def find_module_parameter(module,param):
	f=open(rsync_config,"r")
	pattern="\[%s\]" % (module)
	value=None
	module_found=False
	for line in f.readlines():
		if re.search(pattern,line):
			if pattern==param:
				fields=line.split("=")
				value=fields[1].strip()
				return value
			else:
				pattern=param
				module_found=True
	f.close()
	if module_found:
		value=module
	return value
	
def find_last_snapshot_date(module_path):
	date=None
	# import pdb; pdb.set_trace()
	if os.path.isdir(module_path) == False:
	# 	print "Path %s not found..." % (module_path)
		return None

	snapshot_path= module_path + "/snapshot"
	if os.path.isdir(snapshot_path):
		mtime=os.path.getmtime(snapshot_path)
	else:
		daily_regex=module_path + "/daily.?"
		files = glob.iglob(daily_regex)
		files = [[path, os.path.getmtime(path)] for path in files]
		# it seems files is empty...
		if len(files) == 0:
		#	print "No snapshot dirs in %s for %s" %(module_path,module)
			return None
		# print(files)
		files_sorted_by_date=sorted(files,key=lambda file: file[1])
		mtime=files_sorted_by_date[0][1]

	return mtime
		
today= datetime.today()

for file in glob.iglob("%s/*/backup" % (backup_config_root)):
	f=open(file, "r")
	for line in f.readlines():
		if len(line) > 0:
			fields=line.split()
			module=fields[0]
			# module may have subdir
			if "/" in module:
				module=module[0:module.find("/")]
			snapshot_freq=fields[1]
			if snapshot_freq == "0":
				snapshot_disabled_modules.append(module)
			else:
				# print("%s : %s" % (fields[0], fields[1]))
				module_path=find_module_parameter(module,"path")
				if module_path == None:
					modules_undefined.append(module)
				elif module_path == module:
					modules_without_path.append(module)
				else:
					mtime=find_last_snapshot_date(module_path)
					if mtime == None:
						modules_without_path.append(module)
					else:
						date = datetime.fromtimestamp(mtime)
						if (today - date).days > 2:
							old_snapshots.append([module,date.date()])
						else:
							latest_snapshots.append([module,date])
				

	f.close()
print("Modules with snapshots disabled: ")
print(snapshot_disabled_modules)
print
# print("Modules undefined in this host: ")
# print(modules_undefined)
print("Modules without snapshot paths: ")
print(modules_without_path)
print
print("Modules without a recent snapshot")
print(old_snapshots)
print
print("Latest snapshots")
for s in latest_snapshots:
	print "%s - %s" % (s[0], s[1].strftime("%m/%d"))
