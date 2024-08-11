--导入nakama库
local nk = require("nakama")

--在GetAccount执行之前执行的函数
local function before_get_account(context, payload)
    --执行自定义逻辑
    nk.logger_info("before_get_account")

    --一定要把payload返回，让GetAccount继续执行
    return payload
end

--在GetAccount执行之后执行的函数
local function after_get_account(context, payload)
    --执行自定义逻辑
    nk.logger_info("after_get_account")

    --一定要把payload返回，让GetAccount继续执行
    return payload
end

--注册GetAccount的钩子函数
nk.register_req_before(before_get_account, "GetAccount")
nk.register_req_after(after_get_account, "GetAccount")