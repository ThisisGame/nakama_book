## 使用perf对DS进行性能分析

先安装好perf，然后让DS在后台运行。

先根据进程名查找到进程ID(PID)

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ ps aux | grep ThirdPersonDemoServer
ubuntu     529  0.0  0.0   4636   860 pts/16   S    00:11   0:00 sh ThirdPersonDemoServer.sh -
ubuntu     536  3.9  9.6 1453328 197044 pts/16 Rl   00:11   0:05 /home/ubuntu/testperf/ds/LinuxServer/ThirdPersonDemo/Binaries/Linux/ThirdPersonDemoServer ThirdPersonDemo -
ubuntu    1821  0.0  0.0  13776  1020 pts/16   S+   00:13   0:00 grep --color=auto ThirdPersonDemoServer
```

第二列就是PID，这里第二行是DS服务器进程，PID 536。

录制一段时间，`-p` 后面跟着进程ID。

```sh
# 回到FlameGraph所在的目录，执行perf录制，这样方便调用FlameGraph脚本
sudo perf record -e cpu-clock --call-graph dwarf -p 536
```

按`ctrl+c`结束后，会生成 `perf.data`文件。

