rsync_backup script documentation


INTRODUCTION

This software perform backups from heterogeneous clients to a central server,
according to the following objectives

	- security, applied to the different levels (encrypted transfers, 
	secure authentication, access control...)
	
	- integrity: ensure the data is valid
	
	- versatility: in a heterogeneous ecosystem, the software must adapt
	to all the changing parameters
	
	- efficiency: aim for the best resource usage
	
FEATURES

	- data transfer is encrypted and compressed (thanks to rsync and ssh)
	- automated, periodic and configurable backup schedule
	- everything is registered on logs
	- the logs are analysed to create periodic reports
	- incremental backups (snapshots)
	- authentication and authorization, users have just the indispensable permissions only
	on their data
	- automatic software updates
	- multiplatform (windows / linux / mac os x)

INSTALLATION INSTRUCTIONS

	1) Configure the backup in /etc/rsyncd.conf, even if the client is not available yet:
	
	[user-computer]
        	path = /home/user/hostname
        	write only = true
        	read only = false
        	list = false
        	hosts allow = hostname_list_comma_separated
        	use chroot = true
        	exclude from = /etc/rsync_exclude_p2p

	Usually it is a good idea to use the rsync_exclude_p2p file to exclude the backup
	of peer to peer files.
	
	Configuring this entry early allows the report system to notify that the client
	has no backup, which serves as a reminder of the remaining steps
	
	2) Download the script from the backup server using rsync. For example,
	
	rsync -av server::updates/rsync_backup_linux .
	
	3) Create the sysconfig file in the client
	
	4) Create the SSH keys:
	ssh-keygen -t dsa
	
	   Include the key in the server's /root/.ssh/authorized_keys file:
	from="HOST",command="/usr/local/bin/validate-ssh-command" ssh-dss KEY
	
	
	5) Run the script in the client. It will download the backup config (according to
	sysconfig) and program cron. If everything is OK will start the backup

CONFIGURATION

== Client configuration:

	sysconfig tells the client config directory on the server. Syntax is
	client_name-os

	For each client, "backup" and "cron". Modify them in configs/client_sysconfig
	folder and they will be automatically updated on next sync.

	cron is in standard user-crontab syntax:
	# minute hour day_of_month month day_of_week command
	
	backup syntax:
	module_name snapshot_frequency files_and_directories_to_backup (separed by blankspaces)

	snapshot_frequency=0 -> don't make snapshots ; =2 -> make a snapshot every 2 days	

	File/dir exclussion is handled in the server configuration
	
	File "server_key" is downloaded automatically too. It is used to upgrade
	ssh known_hosts config
	
== Server configuration:

	* Backup subsystem

	/etc/rsyncd.conf contains the configuration of each backup module (one per user per host)
	
	/root/.ssh/authorized_keys
	
	/etc/rsync_exclude_p2p
	
	/home/software/updates/configs (client configurations)
	
	* Snapshots
	
	/etc/cron_scripts/snapshot.cfg
	
	* Restore
	
	/etc/samba/smb.conf
	/etc/exports

	* Updates

	Update servers must define an "updates" rsync resource in rsyncd.conf. All files in that resource must have read permission for everybody, so they can be downloaded freely as part of rsync_backup update system.

	"configs" directory in that resource must point to the collection of client-configs (backup/client) that will be download on update

	Other files that are required by backup clients are: server_key, update_servers


	

DETAILED DESCRIPTION

This software is build upon the following subsystems:

	- backup agent
	- backup server
	- restore subsystem
	- snapshot (incremental backups)
	- reports
	- software updates agent
	- security (metasystem)

Currently the backup and updates agents are integrated in a single script.

== Backup script

This main script checks for updates against the updates server (typically, 
the backup server itself) using rsync. Then according to the configuration it performs
the backup of the client data with the help of rsync too.

The backup schedule is handled by cron daemon based on the schedule config

The configuration is splitted between the server and the clients, although 
client configuration is centralized in a single directory of the backup
server (for easier management)

If you need further details, pay a look to the script code.

== Security

Authentication is handled in the server, with the help of SSH:

	- the ssh key ensures only clients with the key connect to the server
	- the "from" field of authorized_keys restricts the key use to specific hosts
	- the combination of the two ensures that the client is not tampered (the hacker would
	have to steal the IP address and the private ssh key)
	- mobile clients need to perform backups from different IPs. In this case, the host
	restriction is replaced by rsync secrets.
	
Clients are limited to write-only on their backup directory (thanks to write-only and chroot
options of rsyncd), which means the worst thing a hacker could do is delete all the
contents of the users backup. This sceneario is protected by automated snapshots outside the backup
subsystem (hence not modifiable by rsync)
	
The script /usr/local/bin/validate-ssh-command verifies that the client
is not trying to do anything nasty, so even an aproved host can only run rsync against
the server.
	
== Snapshots

Snapshots provide incremental backups since they keep copies of the data at specific times.

This feature is distributed between client and server. On the client, the --backup option of rsync
copies the previous version of each modified file in the "snapshot" dir. Then the server rotates those
snapshot dirs according to the schedule.

The implementation allows for transparent snapshots: it does not matter where the files & directories
are actually located (as with hard links technique, in which it does matter)

Cron facility runs on a daily, weekly and monthly basis the periodic_snapshot script, which configures
the snapshot script according to the period

Snapshot script rotates snapshot dirs, and deletes old snapshots.

Since continuous iterations of the script without backups can lead to data lost, the script checks that
it's safe to rotate directories (using the backup database)

The script registers all the actions in its log along with a status message. You can run a weekly
script that filters that log for statistics.

The config is stored in 3 files (snapshot_daily.cfg, snapshot_monthly.cfg and snapshot_weekly.cfg)
Each file lists the directories that will be snapshotted. Some users may have many of them, in
different schedules (for example, only weekly)

The only issue is that, since both backups and snapshots reside in the user directory, they may be
accidentally removed with rsync (although it's not easy)


== Restore

The home directory is exported read-only with Samba/NFS. In this way, users can access all their
files clasified by period, while the backups remain safe (since they cannot delete anything)

== Reports

cron runs once per week the backup_log_summary and disk_usage_summary scripts.

backup_log_summary.awk filters the logs and saves the important info into the backup_log.db SQLite3
database.

backup_log_summary queries the database and formats the report, then sends it by email. For statistical
processing it recurs the outlier_transfers.pl script.

== Relevant parameters

	* Backup script
	
	UPDATE_CHECK_PERIOD
	SERVER
	SERVER_SHORT
	REMOTE_USER
	UPDATE_MODULE
	LOG_FILE
	
	* Snapshot script
	DAILY_COPIES=5
	WEEKLY_COPIES=2
	MONTHLY_COPIES=1

== Logs

Backup server (rsyncd) logs to /var/log/rsyncd.log

Backup agent logs to /var/log/rsync_backup.log

Validation script logs to /var/log/validate-ssh-command.log

Snapshots log: /var/log/snapshot.log

== Programs

	* Backup
rsync_backup_linux
/usr/local/bin/validate-ssh-command

	* Snapshots
snapshot
periodic_snapshot
backup_log_summary
remove_duplicates - to be replaced by findup

	* Reports 
disk_usage_summary
show_last_backups
backup_log.awk
outlier_transfers.pl

