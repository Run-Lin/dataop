# 大数据架构部团队开发流程

大数据团队不仅仅负责维护和管理公司内的离线，实时，hbase等集群的维护和管理，同时也会对开源大数据框架进行定制的开发和优化。而对于平台的开发工作，需要遵循一定的流程和规范，以方便对开发patch，问题追溯和版本升级进行更加有效的管理。开发团队的同学请在开发之前仔细阅读本说明文档，严格按照开发流程进行日常开发工作。

* 详细了解开发流程之前，请先移步团队的内部gitlab group链接，大数据架构部的开发项目都托管在公司内部的gitlab上

具体开发流程如下：

## 1，找到项目
通常一项开发任务是针对某个项目（比如hadoop/spark等，本文档使用hadoop作为示例进行说明）的某个版本（比如hadoop-2.7.2）进行一项改进，或者bugfix，或者性能优化。不管是哪种类别，首先需要找到该项目的链接，在右边project列表中找到相应的项目（如hadoop），点击进入该项目

## 2，创建issue
点击进入项目后，会看到该项目的一些说明和历史修改记录，如果该项目的代码根目录下提供了README.md文件，也能看到该项目作者在REAEME中提供的一些该项目的基本信息。点击页面右边导航栏中的issues链接，进入该项目的问题列表。
在问题列表中，每一项issue record就是一个独立的开发任务，每个issue record中会详细记录该开发任务的描述，比如该修改的目的，为了解决什么问题，修改了哪个参数的默认值，优化了某项性能等等。

点击右上角的`NEW ISSUE`按钮创建一个新的issue，会进入issue创建页面。

在该创建issue页面中，填入以下内容：

 * Title：
  * [引擎名-编号] issue标题
  * 编号严格按照顺序递增（序列编号需与issueId一致）
  * 对于类似Hadoop、Flink等开源社区引擎，引擎名需要增加前缀`R`，例如`RHADOOP`
 * Description
  * 这里编辑内容使用markdown语法
  * 主要用以描述要解决的问题，例如异常信息，问题解读等
 * Assignee
  * 问题由谁来解决，可以指派给自己或他人，或先留空等人认领
 * Milestone
  * 这里的milestone可以理解为这个问题会被merge到那些版本中去，通常肯定会进入master主干，如果是bugfix，有时候也会merge到以前已经release的版本中去，如hadoop-2.7.2-100
 * Labels
  * label用于对问题进行分类，通常有两个维度
  * 模块：HDFS、YARN、DataNode等
  * 改动：BugFix、Improvement、NewFeature、Doc等

## 3，进行开发编码
创建好issue后，这个开发任务就会被assign给某个人，也可能是创建者自己，然后谁接到这个开发任务就可以进行开发编码工作。

在进行开发编码之前，先需要从gitlab上clone该项目的代码到本地（如果已经进行过clone，这一步可以省略）：

```
git clone XXX
```

然后可以运行如下命令查看当前branch相关信息：

```
$ git status
On branch master
Your branch is up-to-date with 'origin/master'.
nothing to commit, working directory clean
```

以上显示目前是在hadoop项目的master分支上。


因为是要为某个issue进行开发，同时也因为有其他的同学也在进行其他issue的开发，为了不互相影响，所以请为每个issue单独创建一个分支进行开发，分支的名字可以就按照issue编号来，如下：

```
$ git checkout -b RHADOOP-1
Switched to a new branch 'RHADOOP-1'
$ git status
On branch RHADOOP-1
nothing to commit, working directory clean
```

这样就在本地创建了一个名叫`RHADOOP-1`的分支，分支名跟issue需要最好一一对应，方便问题追溯和管理。

此时就可以在该分支上进行编码和修改，修改完成后，将代码提交到该分支中去。比如本示例里，在该分支的代码中新增了一个README.md文件，用来对该project进行简单说明（通常还包括一些代码的修改，这里仅以文档修改作为示例），然后进行提交。


经过上述提交，一个名叫`RHADOOP-1`的branch就已经提交到gitlab上，在该project的gitlab管理界面上，能看到有一个新的分支

至此，开发工作告一段落。


## 4，合并commits
通常在开发中会涉及多次commit提交，但最终应该合并成一个来提交。可以采用`git rebase -i <from commmitid>`来合并，并按照交互式对话框的说明修改message。

## 5，提交merge request
代码提交到gitlab后，事情远远还不算完，因为现在你提交的代码有如下特征：

* 首先，该代码还在`RHADOOP-1`这个branch中，并没有被合并到master分支
* 另外，你提交的修改也只有你自己知道，没有经过其他同事的代码review和确认

因此，提交了branch后，需要提交merge request让同事们进行代码review。

点击gitlab该项目左边导航栏的`Files`，在右边的页面中选择右上角的`CREATE MERGE REQUEST`

进入到编辑页面，对`merge request`进行编辑

这里需要注意几个地方：

* Title内容请跟创建issue时对应的issue title保持一致
* 在Description中详细描述该修改中都进行了哪些修改，基于什么考虑，解决了什么问题，尤其重要的是，需要提供非常完整详细的测试相关信息，相关格式请参考如下：

```
【类型】：功能缺陷/性能优化/文档完善/新功能
【严重程度】：1-Blocker/2-Critical/3-Major/4-Minor/5-Trivial
【功能模块】：HDFS/YARN/Spark/HBase/...
【问题描述】：详细描述问题
【设计描述】：详细描述代码修改逻辑和解决问题思路
【影响分析】：是否会影响其他模块或者运维手段等
【测试思路】：详细描述测试思路和TestCase逻辑，并提供集群真实环境测试的步骤和验证结果
【兼容性】：无


issue link: https://xxxxx

```
* 注意Description最后需要提供对应的issue链接，方便review的同学追溯问题。
* 选择将该review任务assign给谁，尽量不要assign给自己
* 最重要的，选择正确的`Source branch`和`Target branch`，由于本merge request中提供的是`RHADOOP-1`这个branch和`master`branch的对比，所以就是按如图中进行选择。
* 点击`SUBMIT MERGE REQUEST`按钮后，该MR就提交了。相关的assign同学就会收到邮件通知他对代码进行review。

如果改动较大建议独立写测试报告

## 5，review代码

开发同学不仅会自己提交代码给别人review，同时也会收到其他同学的review request，当review别人的代码时，通过连接进入到相关`merge request`界面

通过红框中的tab页，可以看到代码提交这进行过几次提交，代码都做了哪些修改，并且可以在代码修改上提出自己的一些参考建议

如果对修改没有问题，每个reviewer需要在comments下写下+1，或者是`LGTM(Looks Good To Me)`, 表示自己reviewer过后没有问题，同意merge。或者可以直接点击`ACCEPT MERGE REQUEST`，表示reviewer自己觉得该patch没有问题，并为这个修改承担跟开发者一样的责任。

## 6，代码合并

当开发，测试，Review等都通过后，project owner就可以选择对该提交进行merge，也就是merge到相应的分支中去。相关merge操作可以跟github上的操作一致。merge完成后需要删除原branch。


至此，该issue的开发就已经全部结束，但事情仍然没有完，需要找到原来的issue链接，将该issue进行关闭。到这里，本次开发结束，等待后续上线。
