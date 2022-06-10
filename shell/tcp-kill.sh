#!/usr/bin/env bash
closewait -p


sudo netstat -tanp|grep CLOSE_WAIT|awk '{print $NF}'|sort|uniq -c|sort -nr -k2，获取pid，然后执行 ./closewait -p  xxx