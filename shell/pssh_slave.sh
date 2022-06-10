#!/usr/bin/env bash
 pssh -h /tmp/nm -p 100 -O StrictHostKeyChecking=no -A -i  "netstat -tan|grep CLOSE_W|wc" >/tmp/wait.log