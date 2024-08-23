## DS Fork机制

    参考知乎文章：https://zhuanlan.zhihu.com/p/628867664

为了实现起来简单，省去不必须的架构节点，我们就直接用DS来与Nakama服务器进行交互，当有新的匹配对局时，Fork出新的DS进程。

### 1. Linux Fork

复制一段AI的描述。

在Linux操作系统中，fork()是一个系统调用，用于复制一个现有的进程来创建一个新的进程。

这个新进程被称为子进程（child process），而执行fork()调用的进程被称为父进程（parent process）。

fork()调用在父进程中返回新创建的子进程的PID（进程标识符），而在子进程中返回0。

特点：
- 复制：子进程是父进程的一个副本，它拥有父进程数据空间、堆和栈的副本。
- 共享：子进程和父进程共享相同的文件描述符和环境变量，但是它们拥有独立的进程ID。
- 执行：子进程从fork()调用之后的代码继续执行，而父进程则从fork()调用返回后继续执行。

使用场景：
- 并发执行：创建多个进程来并行处理任务。
- 子任务执行：父进程可以分配任务给子进程执行。
- 进程间通信：父子进程可以通过进程ID进行通信。

用一个例子来感受`fork`：

```c++
/// file:files\ue\testfork.cpp

#include <iostream>
#include <cstring>
#include <sys/types.h>
#include <unistd.h>

int main() {
    std::cout << "parent start, pid = " << getpid() << std::endl;

    // 分配内存并初始化数据
    char* data = new char[10];
    strcpy(data, "example");
    // 输出data以及data地址
    std::cout << "original: " << data << ", address: " << (void*)data << std::endl;

    // 创建子进程
    std::cout << "forking..." << std::endl;
    pid_t pid = fork();

    if(pid<0)//fork失败
    {
        std::cout << "fork failed" << std::endl;
        return 1;
    }

    if (pid > 0) // 父进程
    {
        // 暂停1s，让子进程先启动执行。
        sleep(1);

        // 输出data以及data地址
        std::cout << "parent data: " << data << ", address: " << (void*)data << std::endl;

        // 修改相同的数据，触发COW
        data[0] = 'Y';
        
        // 输出data以及data地址
        std::cout << "parent modify data: " << data << ", address: " << (void*)data << std::endl;
    }
    else if (pid == 0) // 子进程
    {
        // 输出data以及data地址
        std::cout << "child data: " << data << ", address: " << (void*)data << std::endl;

        // 修改数据，触发COW
        data[0] = 'X';

        // 输出data以及data地址
        std::cout << "child modify data: " << data << ", address: " << (void*)data << std::endl;
    } 

    std::cout << "exiting current pid = " << getpid() << std::endl;

    return 0;
}
```

扔到WSL里去编译运行。

```log
captainchen@DESKTOP-GS0D9IU:/mnt/g/book/nakama_book/files/ue$ g++ testfork.cpp
captainchen@DESKTOP-GS0D9IU:/mnt/g/book/nakama_book/files/ue$ ./a.out
parent start, pid = 5221
original: example, address: 0x563edc7f8280
forking...
child data: example, address: 0x563edc7f8280
child modify data: Xxample, address: 0x563edc7f8280
exiting current pid = 5222
parent data: example, address: 0x563edc7f8280
parent modify data: Yxample, address: 0x563edc7f8280
exiting current pid = 5221
captainchen@DESKTOP-GS0D9IU:/mnt/g/book/nakama_book/files/ue$
```

可以看到，fork出来的子进程拥有自己的pid，子进程中的data和父进程中的data地址相同，这是因为fork完全复制了父进程的状态和数据。

现代Linux系统实现了COW技术，当子进程没有对data执行写操作是，访问的data其实就是父进程的同一块物理内存。

当子进程对data进行写操作时，才会复制一块物理内存，但是仍然保持原来的地址。