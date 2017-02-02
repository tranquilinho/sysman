#!/usr/bin/env python
import pwd
import grp

def print_passwd_entries(uid_list):
	for uid in uid_list:
		row=pwd.getpwuid(int(uid))
		print(row.pw_name + "(" + str(row.pw_uid) + "," + str(row.pw_gid) + ")" ),

def print_group_entries(gid_list):
	for gid in gid_list:
		row=grp.getgrgid(int(gid))
		print(row.gr_name + "(" + str(row.gr_gid) + ")" ),

pwdall=pwd.getpwall()

nas_users={}
for line in open("users"):
	name,uid = line.split()
	nas_users[uid] = name

nas_groups={}
for line in open("groups"):
	name,gid = line.split()
	nas_groups[gid] = name

passwd_uids_set = set(str(p.pw_uid) for p in pwdall)
passwd_gids_set = set(str(p.pw_gid) for p in pwdall)
group_gids_set = set(str(g.gr_gid) for g in grp.getgrall())

#print('Passwd UIDs')
#print(' '.join(sorted(passwd_uids_set)))

#print('Passwd GIDs')
#print(' '.join(sorted(passwd_gids_set)))

#print('Group GIDs')
#print(' '.join(sorted(group_gids_set)))

print('Users with GID only in passwd:')
passwd_only_gids = passwd_gids_set - group_gids_set
uid_list = [row.pw_uid for row in pwdall if str(row.pw_gid) in passwd_only_gids]
print_passwd_entries(uid_list)
print "\n"

print('Groups without users:')
group_only_gids = group_gids_set - passwd_gids_set
print_group_entries(group_only_gids)
print "\n"

print('Users whose UID is not in NAS register:')
unregistered_uids = passwd_uids_set - set(nas_users.keys())
print_passwd_entries(unregistered_uids)
print "\n"

print('Groups whose GID is not in NAS register:')
unregistered_gids = group_gids_set - set(nas_groups.keys())
print_group_entries(unregistered_gids)
print "\n"
