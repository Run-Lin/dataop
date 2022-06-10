#!/usr/bin/env bash
sudo lsof > /tmp/lsof
grep '/blockmgr' /tmp/lsof|awk '{print $NF}' |awk -F '/' '{print $9}'|sort |uniq -c |sort -k1|head  3