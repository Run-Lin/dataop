#!/usr/bin/env bash
#!/bin/bash
## SHELL
######################################################################
## author: zhangrunlin
## create time: 2021-03-08 11:11:06
## desc: 快速移除前一天的hive临时目录: /tmp/hive-hadoop/*/
## remind: hive -e执行中需要use {DB_NAME}
#######################################################################
#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <date, eg. 20161118>"
    exit 1
fi

# check input format
if ! [[ $1 =~ ^[0-9]{4}[0-9]{2}[0-3][0-9]$ ]]; then
    echo "$1 format is wrong"
    exit 1
fi

# convert date to yyyy-MM-dd
yyyy=$(cut -c-4 <<< "$1")
MM=$(cut -c5-6 <<< "$1")
dd=$(cut -c7-8 <<< "$1")

date="$yyyy-$MM-$dd"

echo $date
# only hadoop has permission

#ns1
#先遍历用户目录
hadoop fs -ls hdfs://Cluster/tmp/hive-hadoop/ |awk -F " " '{print $8}' | grep "hive-hadoop" > Cluster-hive-hadoop.txt
# head -n 100 Cluster-hive-hadoop.txt
cat Cluster-hive-hadoop.txt | while read LINE
do
  echo $LINE
  if [[ "$LINE" = "hdfs://Cluster/tmp/hive-hadoop/hadoop" ]]; then
    echo "skip clear hadoop user path..."
    continue
  fi
  hadoop fs  -D fs.defaultFS=hdfs://Cluster   -fastls ${LINE}  |awk -F " " '{if($6 < "'$date'") print $8}' | grep hive-hadoop > ${date}.txt
  cat ${date}.txt | wc -l
  hadoop fs  -D fs.defaultFS=hdfs://Cluster  -fastrm  ${date}.txt
done

#ns2
#先遍历用户目录
hadoop fs -ls hdfs://Cluster2/tmp/hive-hadoop/ |awk -F " " '{print $8}' | grep "hive-hadoop" > Cluster2-hive-hadoop.txt
# head -n 100 Cluster2-hive-hadoop.txt
cat Cluster2-hive-hadoop.txt | while read LINE
do
  echo $LINE
  if [[ "$LINE" = "hdfs://Cluster2/tmp/hive-hadoop/hadoop" ]]; then
    echo "skip clear hadoop user path..."
    continue
  fi
  hadoop fs  -D fs.defaultFS=hdfs://Cluster2   -fastls ${LINE}  |awk -F " " '{if($6 < "'$date'") print $8}' | grep hive-hadoop > ${date}.txt
  cat ${date}.txt | wc -l
  hadoop fs  -D fs.defaultFS=hdfs://Cluster2  -fastrm  ${date}.txt
done


# hive-staging
#ns1
#先遍历用户目录
hadoop fs  -D fs.defaultFS=hdfs://Cluster   -fastls hdfs://Cluster/tmp/hive-staging/  |awk -F " " '{if($6 < "'$date'") print $8}' |grep hive-staging > ${date}.txt
cat ${date}.txt |wc -l
hadoop fs  -D fs.defaultFS=hdfs://Cluster  -fastrm  ${date}.txt

#ns2
#先遍历用户目录
hadoop fs  -D fs.defaultFS=hdfs://Cluster2   -fastls hdfs://Cluster2/tmp/hive-staging/  |awk -F " " '{if($6 < "'$date'") print $8}' |grep hive-staging > ${date}.txt
cat ${date}.txt |wc -l
hadoop fs  -D fs.defaultFS=hdfs://Cluster2  -fastrm  ${date}.txt


exit 0