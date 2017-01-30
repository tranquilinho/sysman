#!/usr/bin/env python
# Return a list of /dev/sdxx which come from server S

import os
import sys
import glob

def readlinkabs(l):
    """
    Return an absolute path for the destination 
    of a symlink
    """
    assert (os.path.islink(l))
    p = os.readlink(l)
    if os.path.isabs(p):
        return p
    return os.path.join(os.path.dirname(l), p)
    
def removeDotDot(path):
	slices=path.split("/")
	return "/".join(removeDotDotAux(slices))

def removeDotDotAux(v):
	if len(v) < 2 or v[0] == "..":
		return v
	else:
		res=removeDotDotAux(v[1:])
	
		if res[0] == "..":
			return res[1:]
		elif len(res) > 1:
			return [v[0]] + removeDotDotAux(res)
		else: 
			return  [v[0]] + res

def printSyntax():
	print "Syntax: devices_from_server.py SERVER_NAME"

if len(sys.argv) == 2 :
	server=sys.argv[1]
	files = glob.iglob("/dev/disk/by-path/*%s*" % server)
	for f in files:
		devicePath=readlinkabs(f)
		print removeDotDot(devicePath)
	
else:
	#print removeDotDot("/dev/disk/by/../../sdkk")
	#print removeDotDot("/dev/disk/by/2/../../../sdkk")
	#print removeDotDot("/dev/disk/../by/3/../sdkk")
	#print removeDotDot("/sdkk")
	printSyntax