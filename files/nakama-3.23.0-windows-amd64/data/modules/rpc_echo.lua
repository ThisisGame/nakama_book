--导入nakama库
local nk = require("nakama")

--注册RPC调用
nk.register_rpc(function(context, payload)
    --返回结果
    return nk.json_encode({ success = true })
end, "lua_echo")