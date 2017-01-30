#!/bin/bash
awk '/^Target/{a=gensub(".* .*:d([0-9]+)","\\1","g"); print a}' < /etc/iet/ietd.conf | awk '$0 ~ /^[0-9]+/{print $0}' | sort -n
