#!/usr/bin/env python
# Return a list of /dev/sdxx which come from server S

import os
import sys
import glob
import re

def printSyntax():
	print "Syntax: vdisk_from_server.py SERVER_NAME"



if len(sys.argv) == 2 :
	server=sys.argv[1]
	files = glob.iglob("/dev/disk/by-path/*%s*" % server)
	r = re.compile('.*-iqn.san.(.*):(.*)\.(.*)-lun-0')
	for f in files:
		m = r.search(f)
		if m:
			server = m.group(1)
			disk = m.group(2)
			resource = m.group(3)
			print "iqn.san.%s:%s.%s" %(server,disk,resource)
else:
	#print removeDotDot("/dev/disk/by/../../sdkk")
	#print removeDotDot("/dev/disk/by/2/../../../sdkk")
	#print removeDotDot("/dev/disk/../by/3/../sdkk")
	#print removeDotDot("/sdkk")
	printSyntax