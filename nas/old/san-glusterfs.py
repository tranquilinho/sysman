#!/usr/bin/env python2.7

import sqlite3
import argparse
import subprocess
import StringIO
import re
import string

DB='/etc/san/san.db'

def scanPeer(args,c):
	server = args.peer
	if server == "all":
		for row in listPeers(c):
			server=row['name']
			print "PEER %s..." %(server)
			scanVolumeGroups(server,c)
			scanLogicalVolumes(server,c)			
	else:
		try:
			c.execute('insert into server(name,physicalhost) values (?,null)', (server,))
		except sqlite3.IntegrityError:
			# Ignore primary key error
			pass
		scanVolumeGroups(server,c)
		scanLogicalVolumes(server,c)

def volumeStartAll(args,c):
	c.execute('select name from volume')
	for volume in c.fetchall():
		cmd=["gluster","volume","start",str(volume['name'])]
		try:
			printLines(run(cmd))
		except subprocess.CalledProcessError as ex:
			print "Command failed"
			print ex		

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

def addBricks(volumeName, brickPathList):
	cmd=["gluster","volume","add-brick ",volumeName] + brickPathList
	printLines(run(cmd))

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
	return run(baseCommand + command)
	
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
		# asume volume groups < 75GB are system volumes and exclude them
		if volumeSizeGB > 75:
			print "Name: %s, volume free %s/%s (GB)" % (globalName, volumeFreeGB,volumeSizeGB)
			try:
				c.execute('insert into volumeGroup (name,globalName,server,size,free) values (?,?,?,?,?)', (volumeName,globalName,server,volumeSizeGB,volumeFreeGB))
			except sqlite3.IntegrityError:
				# Ignore primary key error
				pass

def scanLogicalVolumes(server,c):
	lvGroup={}
	gfsBricks=scanGfsBricks()
	# print gfsBricks
	for line in runSsh(["lvdisplay", "-c"],server):
		fields = line.split(":")
		volumePath=fields[0].strip()
		vpFields=volumePath.split("/")
		# - s converted into -- within the mapper...
		volumeName=vpFields[-1]
		mapperPath="/dev/mapper/"+vpFields[2]+"-"+ string.replace(vpFields[3],"-","--")
		vgName=fields[1].strip()
		
		dfFields=runSsh(["df","-h",mapperPath],server)[-1].split()
		volumeSizeGB = dfFields[0]
		free=dfFields[2]
		mountPoint=dfFields[-1]
		
		unused = ""
		
		# asume logical volumes outside /pool are system volumes and exclude them
		if  "/pool/" in mountPoint:
			if not volumeName in lvGroup:
				lvGroup[volumeName] = []
			try:
				brickPath = server + ":" + mountPoint
				# print brickPath
				brick = gfsBricks[brickPath]
				c.execute("insert into logicalVolume (name,vg,size,mountPath,volIndex,gfsVolume) values (?,?,?,?,?,?)",(volumeName,vgName,volumeSizeGB,mountPoint,brick["index"],brick["volume"]))
			except KeyError:
				unused=" - UNUSED"
			except sqlite3.IntegrityError:
				# Ignore primary key error
				pass
			lvGroup[volumeName].append("LV %s, volume free %s/%s, mount %s %s" % (vgName,free,volumeSizeGB,mountPoint, unused))
	for key in lvGroup.keys():
		print "Name: %s" % (key)
		for lv in lvGroup[key]:
			print lv

def scanGfsBricks():
	bricks={}
	for line in run(["gluster","volume","info"]):
		match = re.match("Volume Name: ([\w-]+)", line)
		if match != None:
			volName = match.group(1)
		else:
			match = re.match("Brick(\d+): (\w+):([\w/-]+)",line)
			if match != None:
				index=int(match.group(1))
				server=match.group(2)
				mountPoint=match.group(3)
				brick={}
				brick["volume"]=volName
				brick ["index"]=index
				bricks[server + ":" + mountPoint] = brick
	return bricks

def setPhysical(args,c):
	server = args.peer
	physicalHost = args.physicalHost
	try:
		c.execute('update server set physicalhost = ? where name = ?', (physicalHost,server))
	except sqlite3.IntegrityError:
		# Ignore primary key error
		pass

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
	c.execute("CREATE TABLE acl (volume varchar(64),client varchar(128),user varchar(64),type varchar(15),optionSet varchar(32), primary key (volume,client,user))")
	c.execute("CREATE TABLE bricks (volume varchar(64), lv varchar(64), vg varchar(64), primary key (volume))")
	c.execute("CREATE TABLE logicalVolume (name varchar(64),vg varchar(64), size integer,mountPath varchar(255), volIndex integer,gfsVolume varchar(64), primary key (name,vg))")
	c.execute("CREATE TABLE option (id integer,name varchar(64),value varchar(64), primary key (id))")
	c.execute("CREATE TABLE optionSet (name varchar(32),option integer, primary key (name,option))")
	c.execute("CREATE TABLE server (name varchar(128),physicalhost varchar(128), primary key(name))")
	c.execute("CREATE TABLE user (name varchar(64),uid integer,enabled integer,primary key (uid))")
	c.execute("CREATE TABLE volume (name varchar(64), size integer,replica integer, primary key (name))")
	c.execute("CREATE TABLE volumeGroup (name varchar(64),globalName varchar(64), server varchar(128),size integer, free integer, primary key (globalName))")

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row

c = conn.cursor()

# createDB(c)
scanGfsBricks()


# create the top-level parser
parser = argparse.ArgumentParser(prog='san')
subparsers = parser.add_subparsers(help='sub-command help')

parser_peer = subparsers.add_parser('peer', help='peer commands')

peerSubParser = parser_peer.add_subparsers(help='scan command')

parser_peerScan = peerSubParser.add_parser('scan',help='scan peer volume groups')
parser_peerScan.add_argument('peer', type=str, help='peer name')
parser_peerScan.set_defaults(func=scanPeer)

parser_peerSetPhysical = peerSubParser.add_parser('setPhysical',help='link peer to physical host')
parser_peerSetPhysical.add_argument('peer', type=str, help='peer')
parser_peerSetPhysical.add_argument('physicalHost', type=str, help='physical Host')
parser_peerSetPhysical.set_defaults(func=setPhysical)

parser_peerList = peerSubParser.add_parser('list',help='list registered peers info')
parser_peerList.set_defaults(func=printPeersList)

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

parser_volumeStartAll = volumeSubParser.add_parser('startAll',help='start all the available volumes')
parser_volumeStartAll .set_defaults(func=volumeStartAll)

args = parser.parse_args()
args.func(args,c)

# Save (commit) the changes - important, do it always before closing - or you will lose your changes
conn.commit()

# We can also close the cursor if we are done with it
c.close()
conn.close
