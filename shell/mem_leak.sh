#!/usr/bin/env bash

#内存泄露对于java程序来讲是个常见的问题，通用的方法如下：

#查看是否有空内存块

##dump内存
cat /proc/<pid>/smaps >smaps.txt

#or
pmat -X <pid>

#通过gdb dump出内存来查看；【具体命令见下方】

gdb attach <pid>
dump memory outfile.txt startAddreess endAddress
#其中startAddreess endAddress在上面的smaps中都有 返现很多内存是空的，


#如何解决？
#引入jemalloc  博客文档 https://www.jianshu.com/p/f1988cc08dfd   version stable-4 4.5.0

#操作步骤
#1 下载 jemalloc.tar.gz

#2 将上述压缩包解压到/usr/local目录下

#3 source环境变量 source /usr/local/jemalloc/bin/jemalloc.sh

#4 启动应用程序

#验证
cat /proc/${pid}/maps | grep jemalloc

#若能看到jemalloc被加载了，则说明配置成功