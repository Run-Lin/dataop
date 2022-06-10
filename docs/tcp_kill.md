# 如何杀死一个僵死的 TCP 连接
从最近一周生产上出现大量的 CLOSE-WAIT 场景来探讨下，如何杀死一个僵死的 TCP 连接

---

# 什么是 TCP 连接
连接是一种逻辑上的概念，本质上是内核中一个数据结构即 [TCP_SOCK](https://elixir.bootlin.com/linux/latest/source/include/linux/tcp.h#L139), 
是 TCP 协议的一种具体实现. 

一般可以通过 [netstat](https://man7.org/linux/man-pages/man8/netstat.8.html) 和 [ss](https://man7.org/linux/man-pages/man8/ss.8.html) 进行观测 

---

# 什么是僵死的 TCP 连接 ？
从实际上来看就是一个永远不会关闭的连接（内核中的对象永远不释放），理论上只要不关机可以永久存在。

僵死连接通常处于以下两种状态:

1. ESTABLISH: 一般是拔网线造成
2. CLOSE-WIAT： 一般是是应用程序 bug 未关闭连接

---

# 什么是 CLOSE-WAIT
CLOSE-WAIT 直白点说可以理解成 WAIT CLOSE, 在收到 Fin 报文之后，等待应用层程序主动 close，如果不主动 close，这个状态会持续存在没有超时. （稍后会有复现程序展示 CLOSE-WAIT)

### 参考
[RFC793 TCP 状态迁移图](https://tools.ietf.org/html/rfc793#section-3.2)

---

# 僵死的 TCP 连接有什么影响？

僵死的 TCP 连接，简单来说就是会浪费内存（内核对象/应用层连接上下文）。

少量的连接泄漏对系统不会有过大的影响, 但是出现大量的僵死连接就需要注意会对内存有比较大的负荷,
这种连接泄漏往往是应用程序存在 BUG，没有很好的处理连接关闭。

---

# 内核允许的 TCP 最大占用内存

/proc/sys/net/ipv4/tcp_mem

See [ipsysctl.txt](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
``` bash
tcp_mem - vector of 3 INTEGERs: min, pressure, max
	min: below this number of pages TCP is not bothered about its
	memory appetite.

	pressure: when amount of memory allocated by TCP exceeds this number
	of pages, TCP moderates its memory consumption and enters memory
	pressure mode, which is exited when memory consumption falls
	under "min".

	max: number of pages allowed for queueing by all TCP sockets.

	Defaults are calculated at boot time from amount of available
    memory.
```

---

# 如何构造僵死的 TCP 连接

1. 连接处于 establish 状态下，直接拔网线 （有一定概率不会成功，比如正在发送数据，等待 ack会触发重传)
2. 永远不主动关闭连接, 即使对端peer关闭了连接 (CLOSE-WAIT)

```python
import socket;import time; import thread

def do_connect():
    time.sleep(3);s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", 8888));s.close()

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("", 8888)); s.listen(1)
thread.start_new_thread(do_connect, ())

conn, addr = s.accept()
while 1:time.sleep(1)
```

---

class: center,middle
# 如何杀死僵死的 TCP 连接

---

class: center,middle
# SOCK_DESTORY (最推荐的方式)

[4.5及以上版本内核](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=64be0aed59ad519d6f2160868734f7e278290ac1) 使用 SOCK_DESTORY option关闭 socket. 可利用如下 ss 命令:

```bash
ss --tcp state CLOSE-WAIT --kill
```
---

class: center,middle
# ptrace (最简单的方式)

利用 ptrace attach 上进程，close 对应的 fd，可利用如下 oneline 命令:

```bash
gdb -ex="set confirm off" -p pid -ex 'p close(fd)' -ex quit
```

---

class: center,middle
# 直接杀掉进程 (最暴力的方式)

kill -9 pid :)
---

## send RST segment (最麻烦的方式)

通过 raw socket 构造 RST 报文发送让内核来 close socket，可以使用 [sendpkt-rs](https://github.com/detailyang/sendpkt-rs) 从命令行构造 RST 报文

```bash
sendpkt --ip-dip 127.0.0.1 --ip-sip 127.0.0.1 \
--tcp-dport 8888 --tcp-sport 1234  \
--tcp-seq 0x12345 --tcp-flag-rst
```

关键难点在于如何获取 socket 的序列号，写内核模块直接打印 socket 对象的 rcv_nxt 成员即可。

先通过 ss 查看 socket 内核地址：
```bash
Recv-Q Send-Q                            Local Address:Port                                           Peer Address:Port
1      0                                     127.0.0.1:8888                                              127.0.0.1:49416               ino:43000 sk:ffff90bcf4f126c0
```

再通过 systemtap 直接打印 socket 里的序列号
```bash
stap -e \
'probe oneshot {printf("seq:%d\n", @cast(0xffff90bcf4f10f80, "tcp_sock")->rcv_nxt);}'
```
---

# 一些应用层的小技巧

1. 尽量开启 Socket TCP Keepalive Option （Go 默认打开）定时检查对端 peer 的状态，可以避免出现僵死连接
```c
int yes = 1;
setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &yes, sizeof(int));
int idle = 1;
setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &idle, sizeof(int)));
int interval = 1;
setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &interval, sizeof(int));
int maxpkt = 10;
setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &maxpkt, sizeof(int));
```

---
class: center,middle
# Thanks
