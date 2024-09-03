--导入nakama库
local nk = require("nakama")

--- 请求Url并将结果返回给客户端
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据
function rpc_get_url(context, payload)
    nk.logger_info("rpc_get_url is called")

    --打印context类型(table)
    nk.logger_info(type(context))

    --打印payload类型(string)
    nk.logger_info(type(payload))

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --从payload解析url
    local payload_table = nk.json_decode(payload)
    local url = payload_table.url
    local method = payload_table.method
    nk.logger_info(("url: %q method: %q"):format(url, method))

    --访问url
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    local content = nk.json_encode({}) -- encode table as JSON string
    local timeout = 5000 -- 5 seconds timeout
    local success, code, headers, body = pcall(nk.http_request, url, method, headers, content, timeout)

    --返回结果
    if (not success) then
        nk.logger_error(string.format("Failed %q", code))
        return nk.json_encode({ success = false , code = code })
    elseif (code >= 400) then
        nk.logger_error(string.format("Failed %q %q", code, body))
        return nk.json_encode({ success = false , code = code, body = body })
    else
        nk.logger_info(string.format("Success %q %q", code, body))
        return nk.json_encode({ success = true , code = code, body = body })
    end
end


nk.register_rpc(rpc_get_url, "rpc_get_url")