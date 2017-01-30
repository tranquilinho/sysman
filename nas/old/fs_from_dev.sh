#!/usr/bin/env python
# Return a list of filesystems for the vg from stdin

import subprocess
import StringIO
import sys

def run(command):
	output = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE).stdout
	# buf = StringIO.StringIO(output)
	return output.readlines()	

def fsFromVg(vg,mountedFs):
	for line in mountedFs:
		if line.find(vg)>0:
			fields=line.split(" ")
			return fields[2].rstrip()

mountedFs=run("mount")

for vg in sys.stdin:
	vgMapperSyntax=vg.rstrip().replace("-","--")
	print fsFromVg(vgMapperSyntax,mountedFs)

