## 使用Lua开发Nakama服务器逻辑

官方文档：`https://heroiclabs.com/docs/nakama/server-framework/lua-runtime/`

运行Nakama后，在文件夹里自动创建了下面的空目录结构。

```text
./data
./data/module
```

Nakama支持使用Go、Js、Lua来编写服务器逻辑，我比较喜欢Lua，就选择Lua来开发后续的一些例子。

编写的Lua脚本放在`module`目录就会被加载运行。

官方文档列出了Nakama中可用的所有Lua函数及其各自的参数，以及每个函数的相应代码示例，请参考：

`https://heroiclabs.com/docs/nakama/server-framework/lua-runtime/function-reference/`