--导入nakama库
local nk = require("nakama")

--- 将请求的数据返回给客户端
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据
function rpc_echo(context, payload)
    nk.logger_info("rpc_echo is called")

    --打印context类型(table)
    nk.logger_info(type(context))

    --打印payload类型(string)
    nk.logger_info(type(payload))

    --遍历payload
    for k, v in pairs(nk.json_decode(payload)) do
        nk.logger_info(("key: %q value: %q"):format(k, v))
    end

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --返回结果&请求的数据
    return nk.json_encode({ success = true , payload = payload })
end


nk.register_rpc(rpc_echo, "rpc_echo")