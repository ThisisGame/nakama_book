## 在腾讯云Linux上运行DS

### 1. 上传

在电脑上压缩LinuxServer文件夹为LinuxServer.7z，用FileZilla上传到云服务器上。

### 2. 解压

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds$ 7z x LinuxServer.7z

7-Zip [64] 16.02 : Copyright (c) 1999-2016 Igor Pavlov : 2016-05-21
p7zip Version 16.02 (locale=en_US.utf8,Utf16=on,HugeFiles=on,64 bits,2 CPUs Intel(R) Xeon(R) Gold 6148 CPU @ 2.40GHz (506E3),ASM,AES-NI)

Scanning the drive for archives:
1 file, 367554613 bytes (351 MiB)

Extracting archive: LinuxServer.7z
--
Path = LinuxServer.7z
Type = 7z
Physical Size = 367554613
Headers Size = 25107
Method = LZMA2:26
Solid = +
Blocks = 1

Everything is Ok

Folders: 326
Files: 1877
Size:       2727984079
Compressed: 367554613
ubuntu@VM-8-8-ubuntu:~/testperf/ds$
```

### 3. 给权限

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ ls
Engine   Manifest_DebugFiles_Linux.txt   Manifest_UFSFiles_Linux.txt  ThirdPersonDemoServer.sh
log.txt  Manifest_NonUFSFiles_Linux.txt  ThirdPersonDemo
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ chmod 777 -R ./*
```

### 4. 运行

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ sh ThirdPersonDemoServer.sh
- Existing per-process limit (soft=65535, hard=65535) is enough for us (need only 65535)
Increasing per-process limit of core file size to infinity.
Looking for binary: ../../../ThirdPersonDemo/Config/BinaryConfig.ini
LogConsoleResponse: Display: Failed to find resolution value strings in scalability ini. Falling back to default.
LogConsoleResponse: Display: Failed to find resolution value strings in scalability ini. Falling back to default.
LogInit: GuardedMain: CmdLine:  ThirdPersonDemo
LogInit: GuardedMain: check waitforstandaloneattachdebuger.
LogInit: PreInitPreStartupScreen,CmdLine:  ThirdPersonDemo
LogCore: FTraceAuxiliary::Initialize,Parameter:
LogPlatformFile: Using cached read wrapper
LogTaskGraph: Started task graph with 5 named threads and 7 total threads with 1 sets of task threads.
LogStats: Stats thread started at 0.897009
LogICUInternationalization: ICU TimeZone Detection - Raw Offset: +8:00, Platform Override: ''
LogInit: Display: Loading text-based GConfig....
LogPluginManager: Mounting plugin MeshPainting
LogPluginManager: Mounting plugin OodleNetwork
LogPluginManager: Mounting plugin OodleData
......
......

[2024.08.29-16.07.31:372][  0]LogNet: Created socket for bind address: 0.0.0.0 on port 7777
[2024.08.29-16.07.31:373][  0]PacketHandlerLog: Loaded PacketHandler component: Engine.EngineHandlerComponentFactory (StatelessConnectHandlerComponent)
[2024.08.29-16.07.31:373][  0]LogNet: GameNetDriver IpNetDriver_2147482566 IpNetDriver listening on port 7777
[2024.08.29-16.07.31:373][  0]LogWorld: Bringing World /Game/ThirdPersonCPP/Maps/ThirdPersonExampleMap.ThirdPersonExampleMap up for play (max tick rate 30) at 2024.08.30-00.07.31
[2024.08.29-16.07.31:374][  0]LogWorld: Bringing up level for play took: 0.000769
[2024.08.29-16.07.31:374][  0]LogLoad: Took 0.064041 seconds to LoadMap(/Game/ThirdPersonCPP/Maps/ThirdPersonExampleMap)
[2024.08.29-16.07.31:374][  0]LogInit: Display: Engine is initialized. Leaving FEngineLoop::Init()
[2024.08.29-16.07.31:374][  0]LogLoad: (Engine Initialization) Total time: 0.57 seconds
```

或者可以让它在后台执行，并将log输出到log文件：

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ sh ThirdPersonDemoServer.sh ->log.txt &
```

放到后台后，可以根据进程名查找到进程ID(PID)

```sh
ubuntu@VM-8-8-ubuntu:~/testperf/ds/LinuxServer$ ps aux | grep ThirdPersonDemoServer
ubuntu     529  0.0  0.0   4636   860 pts/16   S    00:11   0:00 sh ThirdPersonDemoServer.sh -
ubuntu     536  3.9  9.6 1453328 197044 pts/16 Rl   00:11   0:05 /home/ubuntu/testperf/ds/LinuxServer/ThirdPersonDemo/Binaries/Linux/ThirdPersonDemoServer ThirdPersonDemo -
ubuntu    1821  0.0  0.0  13776  1020 pts/16   S+   00:13   0:00 grep --color=auto ThirdPersonDemoServer
```

第二列就是PID。