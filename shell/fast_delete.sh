#!/usr/bin/env bash

#快速删除指定日期的hdfs文件

hadoop fs  -D fs.defaultFS=hdfs://NS  -fastls  /tmp/hadoop-yarn/staging/history/done_intermediate/dream/ |awk -F " " '{if($6 <= "'2020-08-19'") print $8}' |grep staging >staging_2020-08-19.txt
hadoop fs  -D fs.defaultFS=hdfs://NS  -fastrm   staging_2020-08-19.tx