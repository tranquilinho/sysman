#!/bin/bash

/etc/san/dsh /etc/san/san_servers_ip "/etc/san/exported_iscsi_vdisks.sh" | grep iqn
