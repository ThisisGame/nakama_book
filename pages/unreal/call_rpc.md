## 执行Nakama RPC

在UE中想要执行Nakama RPC函数，有2种方式：
1. 通过HTTP请求，无需登录。
2. Nakama Plugin提供的接口，需要先登录。

两种方式都有自己的应用场景，在DS上与Nakama进行交互时，通过HTTP请求。在客户端与Nakama交互时，通过Plugin接口。

### 1. HTTP请求RPC

在luaruntime介绍三方服务器与Nakama交互时，就介绍了如何同通过HTTP执行Nakama RPC函数，当时是通过控制台或者Postman，现在换成在UE代码来发送Post请求即可。



### 2. Plugin接口请求RPC

Nakama Plugin提供了两种接口来请求RPC，一种是传递Session，另一个是传递HttpKey。

这两个接口都是RealTime Client提供的。

传递Session的接口用来调用玩家相关的RPC，例如更新账号数据。

传递HttpKey的接口用来调用服务器框架相关的，例如获取服务器状态。



