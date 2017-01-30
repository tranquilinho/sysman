#!/usr/bin/env python2.7

import sqlite3
import argparse
import subprocess
import StringIO
import re
import string

DB='/etc/san/san.db'

def scanSanNode(args,c):
	server = args.sanNode
	if server == "all":
		for row in listSanNodes(c):
			try:
				server=row['name']
				print "PEER %s..." %(server)
				scanVolumeGroups(server,c)
				lvGroup = scanLogicalVolumes(server,c)	

				ietfExportsCmd=["grep",'"Target\|Lun"',"/etc/iet/ietd.conf" ,"|","grep","-v","'#'"] #,"|","sed" "s/.*\\([0-9][0-9][0-9]\\).*/\\1/g"] #,"|", "sort","-n","|","tail", "-1"]
				ietfExports=runSsh(ietfExportsCmd,server)
				ids=[]
				exportedLvs=[]
				exportedLvPaths={}
				for export in ietfExports:
					m=re.search(r"Target .*(\d\d\d).([a-zA-Z0-9_-]+)",export)
					if m != None:
						ids = ids + [int(m.group(1))]
						exportedLvs = exportedLvs + [m.group(2)]
					else:
						print export
						m=re.search(r"Path=([a-zA-Z0-9_/-]+),",export) #\b*Lun\b*\d+\b*
						if m != None:
							exportedLvPaths[m.group(1)]=exportedLvs[-1]
				print exportedLvPaths
				greatestDiskId=max(ids)
				diskId=greatestDiskId+1
				for key in lvGroup.keys():
					# print "Name: %s" % (key)
					for lv in lvGroup[key]:
						if lv["volumePath"] not in exportedLvPaths:
							# print "%s,%s,%s" % (lv["name"],lv["mapperPath"],lv["vgName"])
							printIetExport(server,diskId,lv["name"],lv["volumePath"])
							diskId = diskId + 1
			except subprocess.CalledProcessError as ex:
				print "Command failed"
				print ex
	else:
		scanVolumeGroups(server,c)
		scanLogicalVolumes(server,c)

def listSanNodes(c):
	c.execute("select name from server where type = 'san'")
	return c.fetchall()
	
# iscsi target config
def printIetExport(sanNode,diskId,volumeName,volumePath):
	print "Target iqn.san.%s:disk%03d.%s" % (sanNode,diskId,volumeName)
	print "        Lun 0 Path=%s,Type=fileio" % (volumePath)
	
	
def volumeCreate(args,c):
	name= args.name
	replica = args.replica
	brickListString = args.brick_list
	brickList=brickListString.split(",")
	brickPathList=[]
	# print "Name: %s. Replica count: %d" % (name,replica)
	index = 0
	for brick in brickList:
		try:
			fields=brick.split(":")
			vg=fields[0]
			size=int(fields[1])
			# print "VG: %s, size: %d" % (vg,size)
			brickPath = initLv(c,name,vg,index,size)
			brickPathList += [brickPath]
			index = index + 1
		except sqlite3.IntegrityError:
			# the volume was already created - don't run creation commands again
			print "Volume %s already created" %(name)
			c.rollback()
		except subprocess.CalledProcessError as ex:
			print "Command failed"
			print ex
	createGfsVolume(c,name,replica,brickPathList)
		
def volumeExpand(args,c):
	name= args.name
	brickListString = args.brick_list
	brickList=brickListString.split(",")
	brickPathList=[]
	# print "Name: %s. Replica count: %d" % (name,replica)
	try:
		c.execute("select max(volIndex) as i from logicalVolume where gfsVolume = ?",(name,))
		result = c.fetchone()
		index = int(result["i"] ) + 1	
		for brick in brickList:
			fields=brick.split(":")
			vg=fields[0]
			size=int(fields[1])
			# print "VG: %s, size: %d" % (vg,size)
			brickPath = initLv(c,name,vg,index,size)
			brickPathList += [brickPath]
			index = index + 1
		addBricks(name,brickPathList)
		print "To rebalance the volume:"
		print "gluster volume rebalance %s start" % (name)
	except sqlite3.IntegrityError as ex:
		# the volume was already created - don't run creation commands again
		print "Volume %s already created" %(name)		
		print ex
		c.rollback()
	except subprocess.CalledProcessError as ex:
		print "Command failed"
		print ex
	except TypeError:
		# Volume index not found...
		print "The volume does not exist"
		
def createGfsVolume(c,name,replica, brickPathList):
	if replica > 1:
		replicaCmd=["replica",str(replica)]
	else:
		replicaCmd = []
	cmd=["gluster","volume","create",name] + replicaCmd + ["transport","tcp"] + brickPathList
	c.execute("insert into volume(name,size,replica) values (?,?,?)",(name,0,replica))
	print "Create GFS Volume: "
	printList(cmd)
	printLines(run(cmd))
	print
	print "To start the volume, run:"
	print "gluster volume start %s" %(name)
	print "To export the volume for backup:"
	print "gluster volume set %s nfs.rpc-auth-allow 192.168.130.20" % (name)
	print "To mount the volume in the backup server:"
	print "mount -t nfs 192.168.130.200:/%s /mnt/nfs/temp" %(name)

def initLv(c,name,vg,index,size):
	mountPath="/pool/"+name + str(index)
	c.execute("select name,server from volumeGroup where globalName = ?",(vg,))
	result = c.fetchone()
	server =  result["server"] 
	brickPath= server + ":" + mountPath
	vgName=result["name"]
	lvcmd = ["lvcreate","-L", "%dG" %size, "-n",name,vgName]
	vgPath = "/dev/" +vgName + "/" + name
	mkfsCmd = ["mkfs","-t","ext4","-m","1",vgPath]
	mkdirCmd = ["mkdir","-p",mountPath]
	fstabCmd1 = ["ci","-l",'-m"san edit"','-t-fstab',"/etc/fstab"]
	fstabCmd2 = ["echo",'"%s\t%s\t ext4 defaults 0 0"' % (vgPath,mountPath) ,">>","/etc/fstab"]
	mountCmd = ["mount",mountPath]
	# print "%s %s %s" %(name,vg,brickPath)
	print "Execution plan: initLv"
	printList(lvcmd)
	printList(mkfsCmd)
	printList(mkdirCmd)
	printList(fstabCmd1)
	printList(fstabCmd2)
	printList(mountCmd)
	print "Plan end"
	c.execute("insert into logicalVolume (name,vg,size,mountPath,volIndex,gfsVolume) values (?,?,?,?,?,?)",(name,vg,size,mountPath,index,name))
	c.execute("insert into bricks (volume,lv,vg) values(?,?,?)",(brickPath,name,vg))	
	try:
		printLines(runSsh(lvcmd,server))
		printLines(runSsh(mkfsCmd,server))
	except subprocess.CalledProcessError as ex:
		print "Error creating logical volume %s" %(name)	
	try:
		printLines(runSsh(mkdirCmd,server))
		printLines(runSsh(fstabCmd1,server))
		printLines(runSsh(fstabCmd2,server))
		printLines(runSsh(mountCmd,server))
	except subprocess.CalledProcessError as ex:
		print "Error preparing mountpoint %s" %(mountPath)	
		print ex
	return brickPath

def runSsh(command,server):
	baseCommand=["ssh",server]
	cmd=baseCommand + command
	return run(cmd)
	
def run(command):
	output = subprocess.check_output(command)
	buf = StringIO.StringIO(output)
	return buf.readlines()	

def printLines(lines):
	for line in lines:
		print line,

def sizeInGB(field,extentSizeKB):
	return int(field) * extentSizeKB / 1048576

def scanVolumeGroups(server,c):
	for line in runSsh(["vgdisplay", "-c"],server):
		fields = line.split(":")
		volumeName=fields[0].strip()
		extentSizeKB= int(fields[12])
		volumeSizeGB = sizeInGB(fields[13],extentSizeKB)
		volumeFreeGB = sizeInGB(fields[15],extentSizeKB)
		globalName = server+"_"+volumeName
		print "Name: %s, volume free %s/%s (GB)" % (globalName, volumeFreeGB,volumeSizeGB)

def scanLogicalVolumes(server,c):
	lvGroup={}
	# print gfsBricks
	for line in runSsh(["lvdisplay", "-c"],server):
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
		lvGroup[lv["name"]].append(lv)
	return lvGroup


def printPeersList(args,c):
		print "Server\tPhysical Host"
		for row in listPeers(c):
			print "%s\t%s" % (row['name'],row['physicalhost'])

def printList(list):
	print " ".join(map(str, list))

def listPeers(c):
	c.execute('select name,physicalhost from server')
	return c.fetchall()
	
def vg(args):
	print args.command
	
def createDB(c):
	# c.execute("CREATE TABLE acl (volume varchar(64),client varchar(128),user varchar(64),type varchar(15),optionSet varchar(32), primary key (volume,client,user))")
	# c.execute("CREATE TABLE bricks (volume varchar(64), lv varchar(64), vg varchar(64), primary key (volume))")
	#c.execute("CREATE TABLE logicalVolume (name varchar(64),vg varchar(64), size integer,mountPath varchar(255), volIndex integer,gfsVolume varchar(64), primary key (name,vg))")
	#c.execute("CREATE TABLE option (id integer,name varchar(64),value varchar(64), primary key (id))")
	#c.execute("CREATE TABLE optionSet (name varchar(32),option integer, primary key (name,option))")
	c.execute("CREATE TABLE server (name varchar(128),physicalhost varchar(128), type varchar(30), primary key(name))")
	#c.execute("CREATE TABLE user (name varchar(64),uid integer,enabled integer,primary key (uid))")
	#c.execute("CREATE TABLE volume (name varchar(64), size integer,replica integer, primary key (name))")
	#c.execute("CREATE TABLE volumeGroup (name varchar(64),globalName varchar(64), server varchar(128),size integer, free integer, primary key (globalName))")

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row

c = conn.cursor()

# createDB(c)



# create the top-level parser
parser = argparse.ArgumentParser(prog='san')
subparsers = parser.add_subparsers(help='sub-command help')

parser_san = subparsers.add_parser('san', help='san commands')

sanSubParser = parser_san.add_subparsers(help='scan command')

parser_sanScan = sanSubParser.add_parser('scan',help='scan servers')
parser_sanScan.add_argument('sanNode', type=str, help='node name')
parser_sanScan.set_defaults(func=scanSanNode)

parser_volume = subparsers.add_parser('volume', help='volume commands')
volumeSubParser = parser_volume.add_subparsers(help='')

parser_volumeCreate = volumeSubParser.add_parser('create',help='create new volume')
parser_volumeCreate.add_argument('--name', type=str, required=True, help='volume name')
parser_volumeCreate.add_argument('--replica', type=int, default=1, help='replica count')
parser_volumeCreate.add_argument('brick_list', type=str, help='comma-separated brick list (using vg global names): vg1:size1,vg2:size2...')
parser_volumeCreate.set_defaults(func=volumeCreate)

parser_volumeExpand = volumeSubParser.add_parser('expand',help='add bricks to a volume')
parser_volumeExpand .add_argument('--name', type=str, required=True, help='volume name')
parser_volumeExpand .add_argument('brick_list', type=str, help='comma-separated brick list (using vg global names): vg1:size1,vg2:size2...')
parser_volumeExpand .set_defaults(func=volumeExpand)

args = parser.parse_args()
args.func(args,c)

# Save (commit) the changes - important, do it always before closing - or you will lose your changes
conn.commit()

# We can also close the cursor if we are done with it
c.close()
conn.close
