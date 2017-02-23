# sysman
System administration scripts collection (automate + document)

The best documentation on how to complete a task is a simple script; a good way of automating a task is a simple script.

# Features (scripts) summary

NAS scripts: set of scripts to simplify NAS management tasks (create shared resource, rename it...), snapshots, replicas, deduplication, VM backup...

Backup scripts: remote copy of files (rsync_backup), local copy of databases (PostgreSQL, SQLite)

Log scripts: simple logging of GPU, network and sensors status

User management scripts: add, clone, change UID

# General "setup"

Firs thing: clone this repo

```
cd ~
git clone https://github.com/tranquilinho/sysman.git
```

It is useful to set some variables before using these scripts:

   - SYSMAN_ETC: location of the configuration directory (for default servers lists, backup configs...)
   - SYSMAN_LOGDIR: location of the loggin directory
   - SSH_USER: account to use when connecting to remote servers

For example...

```
export SYSMAN_ETC=~/sysman/etc
export SYSMAN_LOGDIR=~/sysman/log/
export SSH_USER=root
```

# Short introduction to NAS scripts

Shared resources are called "network_resources". All scripts beginning with "network_resource" handle one
of the stages of their life cycle. The most recurrent are setup and resize. With time, remove, rename and migrate
come handy too.

All these scripts support the "-h" switch, which shows help on syntax and parameters, and even examples of use.

With nas_dsh script, you can run commands on all your NAS cluster nodes. For example, to find all the backup network resources (and their sizes):

```
nas_dsh -c "df -h | grep backup"
```
You can define a default set of NAS cluster nodes in SYSMAN_ETC/nas_servers

# Style guidelines

Scripts should have no extension, while "libraries" should have .sh extension

File names should use "_" to separate words

TODOs are marked with !!!!

Nice example of style guide: https://google.github.io/styleguide/shell.xml

# Archive

Branch 'old' contains some ancient scripts (like iSCSI NAS integration, DRBD management... that may still be useful)

Copyright: Jesus Cuenca (jesus.cuenca@gmail.com) - Biocomputing Unit/CNB-CSIC
