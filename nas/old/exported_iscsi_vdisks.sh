#!/bin/bash
awk '/Target/{a=gensub(".* iqn(.*):(d|disk)([0-9]+)(.*)","iqn\\1:\\2\\3\\4","g"); print a}' < /etc/iet/ietd.conf | grep -v "^#"
