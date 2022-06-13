#!/usr/bin/env bash
#fgc常见解决方案

#1 Dump内存镜像，确认FullGC问题后，执行jmap保留现场，然后重启服务。
map -dump:live,format=b,file=hiveserver.bin <hs_pid>

#2 确定内存使用异常的类/对象

##1 按照对象分组
#使用内存分析工具MAT(Memory Analyzer Tool) 对内存镜像进行分析，分析结果如图2所示首先看到的大对象分布情况。80%以上的空间是Remainder，说明各种小对象占据80%的空间，没有特别大的对象。

##2 按照类分组
#通过MAT的Histogram功能按照Class分组

##3 明确问题根因
#从MAT中可以获取对象的引用关系

##4 代码fix

##5 参考材料 https://help.eclipse.org/2021-03/index.jsp?topic=%2Forg.eclipse.mat.ui.help%2Fgettingstarted%2Fbasictutorial.html
