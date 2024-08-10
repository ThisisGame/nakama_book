--导入nakama库
local nk = require("nakama")

--输出log
nk.logger_info("Hello World!")

--调用一个不存在的函数
-- call_null_func()

--以pcall(protected call)保护模式调用一个不存在的函数
local result,errorMessage = pcall(call_null_func)
if result then
    --如果返回true，表示pcall运行的函数没有错误
    nk.logger_info("pcall call function no error")
else
    --如果返回false，表示pcall运行的函数有错误，这里可以做一些异常处理。
    nk.logger_error("pcall call function error,errorMessage: " .. errorMessage)
end