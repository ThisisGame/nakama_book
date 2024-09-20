--导入nakama库
local nk = require("nakama")

--- 请求Url并将结果返回给客户端
---@param context table 请求的上下文
---@param payload string 请求的数据，是json，可以用nk.json_decode(payload)解析
---@return string 返回json格式的数据
function rpc_match_list(context, payload)
    nk.logger_info("rpc_match_list is called")

    --打印payload
    nk.logger_info(("payload: %q"):format(payload))

    --从payload解析
    local payload_table = nk.json_decode(payload)
    
    --测试查找过滤条件
    local limit = payload_table.limit
    local isAuthoritative = payload_table.isAuthoritative
    local label = payload_table.label
    local min_size = payload_table.min_size
    local max_size = payload_table.max_size
    local filter = payload_table.filter
    local matches = nk.match_list(limit, isAuthoritative, label, min_size, max_size,filter)
    
    --返回结果
    if (not matches) or (#matches == 0) then
        nk.logger_error("Failed to match_list")
        return nk.json_encode({ success = false })
    else
        nk.logger_info("Success to match_list")
        return nk.json_encode({ success = true , matches = matches })
    end
end


nk.register_rpc(rpc_match_list, "rpc_match_list")