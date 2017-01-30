#!/usr/bin/env python
# Return a list of /dev/sdxx which come from server S

import subprocess
import StringIO
import sys

def run(command):
	output = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE).stdout
	# buf = StringIO.StringIO(output)
	return output.readlines()	

def pvFromDevice(dev):
	if len(dev) > 6:
		for line in run("pvdisplay %s" % (dev)):
			if "VG Name" in line:
				fields=line.split(" ")
				return fields[-1].rstrip()

def printSyntax():
	print "Syntax: devices_from_server.py SERVER_NAME"

for device in sys.stdin:
	print pvFromDevice(device)

