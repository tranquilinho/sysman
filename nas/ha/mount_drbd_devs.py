#!/usr/bin/env python
# Pending: test latest changes
import re
import os
import stat
import time
#import optparse
import sys
import string

mount_pending=[]
RETRIES=5
WAIT=5

def is_user_writeable(filepath):
  st = os.stat(filepath)
  return bool(st.st_mode & stat.S_IWUSR)

def drbd_devs_in(file):
    mounted=[]
    pattern="drbd"
    for line in open(file):
 	# match= re.search("^" + pattern + "(\d+)",line)
        # if match != None:
	if pattern in line:
		dev=string.split(line," ")[0]
		# mounted.append(pattern + match.group(1))
		mounted.append(dev)
    return mounted

def drbd_mounted():
	return drbd_devs_in("/etc/mtab")

def drbd_requested():
	return drbd_devs_in("/etc/fstab")

def drbd_mount(dev):
    # dev = "/dev/drbd%s" % dev_number
    print "Mounting %s" % dev
    if os.path.exists(dev):
	if is_user_writeable(dev):
		print "Mounting..."
		os.system("mount %s" % dev)
	else:
		print "Read only. Maybe still secondary?"
    else:
	print "%s not found..." % dev

# parser = optparse.OptionParser()
# parser = argparse.ArgumentParser(description='Mount drbd devices')
# parser.add_option('action', type='string', choices=['start','stop'], help='Who is calling us - start, stop...')
# parser.add_option('action',action="store", type="string", dest="action")
#args = parser.parse_args()
# (options, args) = parser.parse_args()
if len(sys.argv) != 2 or sys.argv[1] != 'start' :
   print "Syntax: mount [start|stop]"
   exit(0)

for i in range(0,RETRIES):
   os.system("pvscan")
   os.system("vgchange -a y")
   mounted= drbd_mounted()
   requested= drbd_requested()

   if sorted(mounted) == sorted(requested):
      exit(0)

   for dev in requested:
       if dev not in mounted:
      	   drbd_mount(dev)

   time.sleep(WAIT)


exit(1)
