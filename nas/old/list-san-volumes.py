#!/usr/bin/env python
# SAN volumes are based upon the following hierarchy
# SAN LV -> SAN VG -> SAN PV ---- iscsi ---- storage node (SN) ---- SN LV -> SN VG -> SN PV
# For general purpose, it does not matter where the SN PVs of a SAN LV are: they can be located in same or different disks/servers
# For replica and backup uses, it does matter: the SN LVs of the original and the replica/backup must be in different servers
# Hence, SAN PV info is enough - no need to bother with SN elements...
# ... except for new SAN LV allocation, where you need to know the space available on all the SN VG of the SAN
# But that's a different script

import subprocess

def run(command):
        output = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE).stdout
        return output.readlines()   

def printLines(lines):
	for line in lines:
		print line,
		
def localLvList():
	lvList={}
	# print gfsBricks
	for line in run("lvdisplay -c"):
		print line
		lv={}
		fields = line.split(":")
		lv["volumePath"]=fields[0].strip()
		vpFields=lv["volumePath"].split("/")
		# - s converted into -- within the mapper...
		lv["name"]=vpFields[-1]
		# lv["mapperPath"]="/dev/mapper/"+vpFields[2]+"-"+ string.replace(vpFields[3],"-","--")
		lv["vgName"]=fields[1].strip()

		#cmd=["df","-h",lv["mapperPath"]]
		#printList(cmd)
		#dfFields=runSsh(cmd,server)[-1].split()
		#dfFields=[0,0,"/"]
		#volumeSizeGB = dfFields[0]
		#free=dfFields[2]
		#mountPoint=dfFields[-1]
		
		#unused = ""
		
		if not lv["name"] in lvGroup:
			lvGroup[lv["name"]] = []
		lvList[lv["name"]].append(lv)
	return lvGroup
	
print localLvList()
