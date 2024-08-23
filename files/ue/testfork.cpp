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